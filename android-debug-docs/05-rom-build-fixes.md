# ROM Build & APK Fixes

Fixes for common AOSP / vendor ROM build issues: APK alignment, preprocessed APK signing, `dex2oat` compiler filter tuning, hidden-API verifier exemptions, GCam wrappers, and Display Engine mode entries.

---

## Table of Contents

1. [Overview](#1-overview)
2. [APK Zipalign Verification](#2-apk-zipalign-verification)
3. [Preprocessed / Presigned APK Signing](#3-preprocessed--presigned-apk-signing)
4. [Per-App dex2oat Compiler Filter](#4-per-app-dex2oat-compiler-filter)
5. [Hidden-API / Verifier Exemption List](#5-hidden-api--verifier-exemption-list)
6. [dex2oat Flags in Device Tree](#6-dex2oat-flags-in-device-tree)
7. [GCam / Camera Fix Script](#7-gcam--camera-fix-script)
8. [Display Engine Mode Entries](#8-display-engine-mode-entries)
9. [Verification Checklist](#9-verification-checklist)
10. [Notes](#10-notes)

---

## 1. Overview

Three categories of build issues are addressed here:

| Category | Typical symptom | Fix section |
|---|---|---|
| APK packaging | `zipalign` verification fails during build | [§2](#2-apk-zipalign-verification), [§3](#3-preprocessed--presigned-apk-signing) |
| ART / dex2oat | Slow first-launch, verification failures, `PackageManager` rejecting APK | [§4](#4-per-app-dex2oat-compiler-filter), [§6](#6-dex2oat-flags-in-device-tree) |
| Hidden-API / verifier | App crashes with `NoSuchMethodError` after update | [§5](#5-hidden-api--verifier-exemption-list) |

Plus two device-specific tweaks in [§7](#7-gcam--camera-fix-script) and [§8](#8-display-engine-mode-entries).

---

## 2. APK Zipalign Verification

`zipalign` ensures 4-byte alignment of uncompressed entries inside an APK so the runtime can `mmap` them directly. Modern AOSP builds (Android 13+) also verify page-alignment (`-P 16`) for native libraries.

### Verify an existing APK

```bash
# Standard 4-byte alignment check
zipalign -c -v 4 existing.apk

# Page-aligned check (Android 13+, native libs / resources.arsc)
zipalign -c -P 16 -v 4 existing.apk
```

### Exit codes

| Exit code | Meaning |
|---|---|
| `0` | APK is correctly aligned |
| `1` | Alignment check failed — the APK needs re-aligning |

### Fix: re-align an APK

```bash
zipalign -P 16 -v 4 input.apk output_aligned.apk

# Then re-sign it
apksigner sign --key key.pk8 --cert cert.x509.pem output_aligned.apk
```

### Where this matters in the build

- `system/extras/ext4_utils/` — image creation verifies alignment
- `build/make/tools/zipalign/` — build-time alignment tool
- Some custom ROMs add `zipalign` post-processing to `prebuilt_etc` APK entries; if an APK is `presigned: true`, `zipalign` may need to be skipped or re-applied manually.

### Common failure

```
ERROR: zipalign failed on ... (exit 1)
```

Usually means the source APK was signed and aligned by a **different** `zipalign` version, or its native libs were built with a mismatched `-P` value. Re-align with the same `zipalign` that the build itself uses.

---

## 3. Preprocessed / Presigned APK Signing

Some vendor ROM builds ship APKs that are **already signed and preprocessed**. The AOSP prebuilt-APK check (`has_preprocessed_issues`) normally blocks these to prevent accidental re-signing.

### Why the build "passes" when it shouldn't

If the prebuilt APK declares:

```
presigned: true,
preprocessed: true,
```

then `has_preprocessed_issues` returns `True`. The build logic then hits:

```python
if not has_preprocessed_issues:
    sys.exit("APK is preprocessed but not flagged")
```

Because the condition is **false** (issues *were* found), `sys.exit` is skipped, and the **stamp file gets touched** — the build then passes, silently shipping a preprocessed APK that may not have been re-signed.

### Correct `Android.bp` declaration

```bp
android_app_import {
    name: "MyPrebuiltApp",
    apk: "MyPrebuiltApp.apk",
    presigned: true,
    preprocessed: true,
    skip_preprocessed_apk_checks: true,   // acknowledge and bypass checks
    certificate: "platform",
}
```

### Correct `Android.mk` declaration

```make
include $(CLEAR_VARS)
LOCAL_MODULE        := MyPrebuiltApp
LOCAL_SRC_FILES     := MyPrebuiltApp.apk
LOCAL_MODULE_CLASS  := APPS
LOCAL_MODULE_TAGS   := optional
LOCAL_CERTIFICATE   := PRESIGNED
LOCAL_PREBUILT_JNI_LIBS :=
LOCAL_DEX_PREOPT    := false
LOCAL_PRIVILEGED_MODULE := true
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
include $(BUILD_PREBUILT)
```

> ⚠️ `skip_preprocessed_apk_checks: true` **silences** the check without actually solving an alignment or signing problem. Use it only when you've independently verified the APK is correctly signed and aligned.

### Verifying a presigned APK

```bash
# Check signature and alignment
apksigner verify --verbose --print-certs MyPrebuiltApp.apk
zipalign -c -P 16 -v 4 MyPrebuiltApp.apk
```

If either fails, **do not** silence the check — fix the APK first (re-sign / re-align), then update the declaration.

---

## 4. Per-App dex2oat Compiler Filter

`dex2oat` compiles DEX → native code at install time. The `speed` filter skips most runtime verification and generates fully-optimized native code, which is faster at the cost of install size.

### Why per-app matters

Some apps (Instagram, banking apps, large games) either:
- Time out during `dex2oat` with the default `speed-profile` filter, or
- Trigger repeated re-verification because of hidden-API changes.

Forcing them to `speed` avoids both.

### Global override (build.prop / BoardConfig)

```make
PRODUCT_PROPERTY_OVERRIDES += \
    pm.dexopt.install=speed \
    dalvik.vm.dex2oat-filter=speed
```

### Per-app override (recommended)

Use `pm.dexopt.<package>=speed` in `PRODUCT_PROPERTY_OVERRIDES` — note that `pm.dexopt.<package>` keys are handled by the framework's `PackageDexOptimizer` only if the ROM supports per-app filters. The portable way is to add the app to a **dexpreopt config**:

```make
# device/<vendor>/<device>/dexpreopt.config
PRODUCT_DEXPREOPT_PREBUILTS += \
    MyPrebuiltApp

# Force speed compilation for it
DEXPREOPT_APP_FILTER_MAP := \
    MyPrebuiltApp:speed
```

If your ROM doesn't support `DEXPREOPT_APP_FILTER_MAP`, fall back to the global `dalvik.vm.dex2oat-filter=speed` override, accepting the install-time cost across the board.

### Verify the effect

```bash
# Confirm the prop was baked in
adb shell getprop dalvik.vm.dex2oat-filter
adb shell getprop pm.dexopt.install

# Confirm an app was compiled with the speed filter
adb shell pm dump com.example.app | grep -A2 "dexopt"
```

---

## 5. Hidden-API / Verifier Exemption List

Since Android 9, apps cannot access non-SDK (hidden) framework APIs. On AOSP-derived ROMs, you can whitelist specific packages.

### Where the file lives

The exemption list is compiled into the boot classpath at build time from one of:

- `frameworks/base/core/res/res/xml/hiddenapi-package-whitelist.xml`
- `frameworks/base/data/etc/hiddenapi-package-whitelist.xml`
- or a device-specific override under `device/<vendor>/<device>/hiddenapi-package-whitelist.xml`

### Format

```xml
<?xml version="1.0" encoding="utf-8"?>
<hidden-api-package-whitelist version="1">
    <hidden-api-package-whitelist-entry>
        <package-name>com.instagram.android</package-name>
    </hidden-api-package-whitelist-entry>
    <hidden-api-package-whitelist-entry>
        <package-name>com.example.app</package-name>
    </hidden-api-package-whitelist-entry>
</hidden-api-package-whitelist>
```

The entries whitelist **whole packages** — every hidden API the app uses becomes accessible. Use sparingly.

### Applying it in the build

Add to your device tree's `BoardConfig.mk`:

```make
# Point to the whitelist file
PRODUCT_PACKAGES += \
    hiddenapi-package-whitelist

# Or, if overriding the framework default:
HIDDENAPI_PACKAGE_WHITELIST := device/<vendor>/<device>/hiddenapi-package-whitelist.xml
```

The `hiddenapi-lists` build target regenerates the compiled policy files:

```bash
m hiddenapi-lists
```

### Verify on device

```bash
adb shell dumpsys package com.example.app | grep -i "hiddenapi"
adb logcat | grep -i "hiddenapi"
```

If the app still crashes with `NoSuchMethodError`, the whitelist wasn't picked up — check that:

1. The XML is present in the source tree.
2. `HIDDENAPI_PACKAGE_WHITELIST` points at the right path.
3. `hiddenapi-lists` was rebuilt after editing.

---

## 6. dex2oat Flags in Device Tree

Global `dex2oat` tuning for the whole ROM. Place in your device tree's `device.mk`.

```make
# device/<vendor>/<device>/device.mk

PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.dex2oat-Xms=64m \
    dalvik.vm.dex2oat-Xmx=512m \
    dalvik.vm.dex2oat-filter=speed \
    dalvik.vm.image-dex2oat-filter=speed
```

### What each flag does

| Flag | Default | Effect of `speed` / larger value |
|---|---|---|
| `dalvik.vm.dex2oat-Xms` | `16m` | Initial heap for dex2oat — raise for large apps |
| `dalvik.vm.dex2oat-Xmx` | `512m` (device dependent) | Max heap — raise if dex2oat hits `OutOfMemoryError` |
| `dalvik.vm.dex2oat-filter` | `speed-profile` | `speed` skips profile-guided optimization for full AOT |
| `dalvik.vm.image-dex2oat-filter` | `speed` | Filters applied to the boot image; leave at `speed` |

### Variants for specific devices

**Low-RAM devices** — reduce install cost at the expense of first-launch performance:

```make
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.dex2oat-filter=quicken \
    dalvik.vm.image-dex2oat-filter=verify
```

**High-performance devices** — maximize first-launch speed:

```make
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.dex2oat-filter=speed \
    dalvik.vm.image-dex2oat-filter=speed \
    dalvik.vm.dex2oat-Xmx=1g
```

### Verify on device

```bash
adb shell getprop | grep dex2oat
# → [dalvik.vm.dex2oat-filter]: [speed]
# → [dalvik.vm.dex2oat-Xmx]: [512m]
# → ...
```

---

## 7. GCam / Camera Fix Script

Some custom ROMs ship a wrapper script that patches GCam-related camera HAL mismatches after install. Typical invocation:

```bash
chmod +x fix_gcam.sh
./fix_gcam.sh
```

### What the script usually does

- Renames or symlinks `camera.*.so` vendor libs
- Patches `media_profiles.xml` frame-rate entries
- Sets `persist.vendor.camera.*` props
- Remounts `/vendor` if needed (requires `adb root`)

### Running it via ADB

```bash
adb push fix_gcam.sh /data/local/tmp/
adb shell chmod +x /data/local/tmp/fix_gcam.sh
adb shell sh /data/local/tmp/fix_gcam.sh

# Reboot to apply
adb reboot
```

### Verify after reboot

```bash
adb logcat -b all | grep -iE "camera|gcam" | head -40
adb shell dumpsys media.camera | head -60
```

If GCam still crashes, the script likely patched the wrong HAL variant for your device — check the `camera.*.so` list in `/vendor/lib64/hw/` and confirm the script's expected filenames match.

---

## 8. Display Engine Mode Entries

Some MTK / Qualcomm display HALs look up display mode entries by name from a per-device config. Missing entries cause a boot loop or a black screen after the boot animation.

### Symptom

```
FATAL EXCEPTION: main
  java.lang.IllegalArgumentException:
    display_engine_mode_entries: entry not found
```

Or the display HAL silently falls back to a low-power mode and never refreshes.

### Where to add entries

Device-specific display config — usually one of:

- `device/<vendor>/<device>/configs/display_engine.xml`
- `/vendor/etc/display_engine/modes.xml`
- A `PRODUCT_COPY_FILES` target that places the file into `/vendor/etc/`

### Example entry

```xml
<display_engine_mode_entries>
    <mode name="default">
        <entry key="peak_brightness" value="800"/>
        <entry key="gamma" value="2.2"/>
    </mode>
    <mode name="hdr">
        <entry key="peak_brightness" value="1200"/>
        <entry key="gamma" value="2.4"/>
    </mode>
</display_engine_mode_entries>
```

### Copy into the vendor image

```make
# device.mk
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/display_engine.xml:$(TARGET_COPY_OUT_VENDOR)/etc/display_engine.xml
```

### Verify on device

```bash
adb shell ls -la /vendor/etc/display_engine.xml
adb shell cat /vendor/etc/display_engine.xml
adb logcat | grep -i "display_engine\|DisplayEngine"
```

---

## 9. Verification Checklist

Before declaring the fix complete, run through:

```bash
# ── 1. APK alignment & signature ───────────────────────────
zipalign -c -P 16 -v 4 <your_apk>.apk
apksigner verify --verbose <your_apk>.apk

# ── 2. dex2oat props ───────────────────────────────────────
adb shell getprop | grep -E "dalvik.vm.(dex2oat|image-dex2oat)"
adb shell getprop pm.dexopt.install

# ── 3. Per-app dexopt result ───────────────────────────────
adb shell pm dump <package> | grep -A2 dexopt

# ── 4. Hidden-API whitelist ────────────────────────────────
adb shell dumpsys package <package> | grep -i hiddenapi
adb logcat | grep -i hiddenapi

# ── 5. Display engine ──────────────────────────────────────
adb shell ls -la /vendor/etc/display_engine.xml
adb logcat | grep -i display_engine

# ── 6. Camera (if GCam script applied) ─────────────────────
adb logcat -b all | grep -iE "camera|gcam" | head -20
```

Each section of the checklist should produce **expected output with no errors**. If any step fails, revisit the matching fix section before moving on.

---

## 10. Notes

- **`skip_preprocessed_apk_checks` is not a fix.** Use it only after independently verifying that the APK is correctly signed and aligned.
- **`dex2oat-filter=speed` increases APK install size** (native code is generated up front). On storage-constrained devices, prefer `speed-profile` and rely on profile-guided optimization.
- **Hidden-API whitelisting is a blunt instrument.** It opens the entire hidden framework surface to the listed package. Prefer per-method whitelists (via `hiddenapi-flags.csv`) when possible.
- **Per-app dex2oat filters (`pm.dexopt.<package>`) require ROM support.** If your ROM's `PackageDexOptimizer` doesn't honour them, fall back to `DEXPREOPT_APP_FILTER_MAP` (build-time) or the global filter.
- **`display_engine` XML schema is vendor-specific.** The `<entry>` keys and valid values differ between MTK, Qualcomm, and Exynos. Pull the schema from a stock vendor image of the same platform.
- **Always rebuild `boot.img` / `vendor_boot.img` after changing `device.mk` props.** Changing `PRODUCT_PROPERTY_OVERRIDES` alone does not update the ramdisk or vendor boot image.
- For logcat commands used in the verification checklist, see `01-adb-logcat-debugging.md`.
