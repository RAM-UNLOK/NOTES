# GCam APK Patch Guide
### apktool (smali patch) → zip (uncompressed JNI) → zipalign → sign

---

## Why two tools?

| Task | Tool | Reason |
|------|------|--------|
| Patch smali | `apktool` | DEX bytecode must be decoded to smali and recompiled back. Plain zip can't read or modify DEX. |
| Uncompressed .so libs | `zip` | After apktool rebuilds the APK, re-add .so files using `zip -0` (store mode). |
| Align | `zipalign` | Must run after all file changes, before signing. |
| Sign | `apksigner` | Must be last step. |

---

## Prerequisites

```bash
sudo apt install apktool zipalign apksigner unzip zip openjdk-17-jdk python3

apktool --version
zipalign --version
apksigner version
```

---

## Step 1 — Decode with apktool

```bash
apktool d gcam.apk -o gcam_decoded/
```

This decodes DEX → smali and extracts all resources:
```
gcam_decoded/
├── smali/
├── smali_classes2/
│   └── MC/
│       └── LibPatcher.smali   ← patch this
├── lib/
│   └── arm64-v8a/*.so
├── res/
├── AndroidManifest.xml
└── apktool.yml
```

---

## Step 2 — Patch LibPatcher.smali

Save this as `patch_libpatcher.py`:

```python
#!/usr/bin/env python3
import re, shutil
from pathlib import Path

src = Path("gcam_decoded/smali_classes2/MC/LibPatcher.smali")

shutil.copy2(src, src.with_suffix(".smali.bak"))
print(f"Backup: {src.with_suffix('.smali.bak')}")

lines = src.read_text(encoding="utf-8").splitlines(keepends=True)
patched = []
i = 0
fixed = 0

while i < len(lines):
    line = lines[i]
    if "Landroid/widget/Toast;->makeText(" in line:
        m = re.search(r'\{([^}]+)\}', line)
        regs = [r.strip() for r in m.group(1).split(',')]
        msg_reg = regs[1]
        indent = re.match(r'^(\s*)', line).group(1)

        # Skip ahead to show() call
        j = i + 1
        while j < len(lines) and "Landroid/widget/Toast;->show()V" not in lines[j]:
            j += 1

        # Replace entire Toast block with getToast() (main thread safe)
        patched.append(
            f"{indent}invoke-static {{{msg_reg}}}, LMC/main;->getToast(Ljava/lang/String;)V\n"
        )
        fixed += 1
        print(f"  Fixed line {i+1} → getToast({msg_reg})")
        i = j + 1
        continue

    patched.append(line)
    i += 1

src.write_text("".join(patched), encoding="utf-8")
print(f"\nDone. Fixed {fixed} Toast block(s).")
```

Run it:
```bash
python3 patch_libpatcher.py
```

Verify no direct Toast calls remain:
```bash
grep "Toast;->makeText\|Toast;->show" gcam_decoded/smali_classes2/MC/LibPatcher.smali
# Must return nothing
```

---

## Step 3 — Rebuild with apktool

```bash
apktool b gcam_decoded/ -o gcam_rebuilt.apk
```

apktool recompiles all smali back to DEX and repacks the APK.
The .so files will still be compressed at this point — fixed in next step.

---

## Step 4 — Repack .so libs uncompressed

```bash
# Extract the rebuilt APK
mkdir gcam_tmp/
unzip -q gcam_rebuilt.apk -d gcam_tmp/

# Remove the compressed .so entries
zip -d gcam_rebuilt.apk "lib/arm64-v8a/*.so" 2>/dev/null || true

# Re-add .so files with store (no compression)
cd gcam_tmp/
find . -name "*.so" | sed 's|^\./||' | xargs zip -0 ../gcam_rebuilt.apk
cd ..

rm -rf gcam_tmp/
```

Verify .so files are stored uncompressed:
```bash
unzip -v gcam_rebuilt.apk | grep "\.so"
# Method column must show "Stored" and 0% compression
```

---

## Step 5 — Zipalign

Always zipalign BEFORE signing. `-P 16` page-aligns .so files for
direct mmap on Android 15+ (16KB page size):

```bash
zipalign -P 16 -f -v 4 gcam_rebuilt.apk gcam_aligned.apk
```

Verify:
```bash
zipalign -P 16 -c -v 4 gcam_aligned.apk
# Should print: Verification successful
```

---

## Step 6 — Sign

### Option A — Your own keystore
```bash
apksigner sign \
    --ks my.keystore \
    --ks-key-alias mykey \
    --ks-pass pass:yourpassword \
    --key-pass pass:yourkeypassword \
    --out gcam_signed.apk \
    gcam_aligned.apk
```

### Option B — Generate a debug keystore (testing)
```bash
keytool -genkeypair \
    -keystore debug.keystore \
    -alias androiddebugkey \
    -keyalg RSA -keysize 2048 \
    -validity 10000 \
    -storepass android \
    -keypass android \
    -dname "CN=Android Debug,O=Android,C=US"

apksigner sign \
    --ks debug.keystore \
    --ks-key-alias androiddebugkey \
    --ks-pass pass:android \
    --key-pass pass:android \
    --out gcam_signed.apk \
    gcam_aligned.apk
```

### Option C — ROM platform key (product app in ROM)
```bash
apksigner sign \
    --ks /path/to/aosp/build/target/product/security/platform.jks \
    --ks-key-alias platform \
    --ks-pass pass:android \
    --key-pass pass:android \
    --out gcam_signed.apk \
    gcam_aligned.apk
```

Verify signature:
```bash
apksigner verify --verbose gcam_signed.apk
# v2 scheme (APK Signature Block v2): true
# v3 scheme (APK Signature Block v3): true
```

---

## Android.bp (ROM builds)

```bp
soong_namespace {
}
android_app_import {
    name: "gcam",
    owner: "Google",
    apk: "proprietary/product/app/gcam/gcam.apk",
    overrides: ["Aperture", "Camera2"],
    presigned: true,
    dex_preopt: {
        enabled: false,
    },
    product_specific: true,
}
prebuilt_etc_xml {
    name: "com.meitu.meiyancamera.permissions",
    owner: "google",
    src: "permissions/com.meitu.meiyancamera.permissions.xml",
    filename_from_src: true,
    sub_dir: "permissions",
    product_specific: true,
}
```

Place `gcam_signed.apk` at:
```
proprietary/product/app/gcam/gcam.apk
```

---

## Full Pipeline — Quick Reference

```bash
# 1. Decode DEX → smali
apktool d gcam.apk -o gcam_decoded/

# 2. Patch smali (fix Toast crash)
python3 patch_libpatcher.py

# 3. Rebuild smali → DEX
apktool b gcam_decoded/ -o gcam_rebuilt.apk

# 4. Repack .so uncompressed
mkdir gcam_tmp && unzip -q gcam_rebuilt.apk -d gcam_tmp/
zip -d gcam_rebuilt.apk "lib/arm64-v8a/*.so" 2>/dev/null || true
cd gcam_tmp && find . -name "*.so" | sed 's|^\./||' | xargs zip -0 ../gcam_rebuilt.apk && cd ..
rm -rf gcam_tmp/

# 5. Zipalign
zipalign -P 16 -f -v 4 gcam_rebuilt.apk gcam_aligned.apk

# 6. Sign
apksigner sign --ks my.keystore --ks-key-alias mykey \
    --ks-pass pass:password --key-pass pass:password \
    --out gcam_signed.apk gcam_aligned.apk

# 7. Verify
apksigner verify --verbose gcam_signed.apk
zipalign -P 16 -c -v 4 gcam_signed.apk
unzip -v gcam_signed.apk | grep "\.so"
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `brut.androlib.AndrolibException` | apktool decode failed | Use latest apktool, try `--only-main-classes` |
| `Toast on thread without Looper` | Smali patch not applied | Re-run patch script before `apktool b` |
| `.so files still compressed` | Forgot Step 4 | Re-run zip -0 step |
| `Verification FAILED` on zipalign | Signed before aligning | Zipalign first, sign second — always |
| `INSTALL_PARSE_FAILED_NO_CERTIFICATES` | APK unsigned | Run apksigner |
| `unrecognized property` in Android.bp | Invalid Soong property | Use the Android.bp from this guide exactly |
