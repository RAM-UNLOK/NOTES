# Android Audio HAL & Vendor Library Debugging

Debugging dlopen failures, missing dependencies, and audio HAL initialization issues on MediaTek / AOSP devices.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Crash Log Capture](#2-crash-log-capture)
3. [Audio HAL Configuration Inspection](#3-audio-hal-configuration-inspection)
4. [Investigating createIEffectMTK dlopen Failures](#4-investigating-createieffectmtk-dlopen-failures)
5. [Tracing the Audio HAL at Runtime](#5-tracing-the-audio-hal-at-runtime)
6. [Discovering MTK-specific Vendor Libraries](#6-discovering-mtk-specific-vendor-libraries)
7. [readelf Cheatsheet](#7-readelf-cheatsheet)
8. [strace Cheatsheet](#8-strace-cheatsheet)
9. [Quick Diagnostic Workflow](#9-quick-diagnostic-workflow)
10. [Notes](#10-notes)

---

## 1. Overview

The MTK audio effect HAL (`android.hardware.audio.effect.aidl-impl-mediatek.so`) often silently fails to initialize an effect because a `dlopen()` call inside `createIEffectMTK()` cannot resolve its target library or a transitive dependency.

Common symptoms:
- Audio effect chain is missing in `dumpsys media.audio_flinger`
- Logcat shows generic `EffectHalHidl: Effect init failed` or `AidlEffect: create failed`
- No obvious `dlopen.*failed` message because the failing call is on a worker thread that swallows the error

The workflow below walks through capturing the failure and identifying the exact missing library.

---

## 2. Crash Log Capture

Run these on the device after the failure occurs.

```bash
# Kernel ring buffer
adb shell dmesg > dmesg.log

# Tombstones (native crash dumps)
adb pull /data/tombstones/ .

# Persistent RAM console (survives reboot)
adb shell cat /sys/fs/pstore/console-ramoops-0 > ramoops.log

# Last kernel message (older kernels only)
adb shell cat /proc/last_kmsg > last_kmsg.log

# Full logcat from all buffers
adb logcat -b all > full_logcat.log
```

> 👉 For logcat filtering tips, see `01-adb-logcat-debugging.md`.

---

## 3. Audio HAL Configuration Inspection

Inspect the on-device audio configuration before digging deeper.

```bash
# Effect config file
adb shell ls -la /vendor/etc/audio_effects.xml
adb shell cat /vendor/etc/audio_effects.xml

# Audio config directory
adb shell ls -la /vendor/etc/audio/

# HAL binaries in /vendor/bin/hw
adb shell ls -la /vendor/bin/hw/ | grep -i audio

# HAL impl libs
adb shell ls -la /vendor/lib64/hw/ | grep -iE "audio|effect"
```

### What to look for in `audio_effects.xml`

- `<effect-library name="...">` entries — each should correspond to a `.so` in `/vendor/lib64/soundfx/`.
- `<effect name="..." library="..." uuid="...">` entries — each `library` must match a `<effect-library>` name.
- Missing library entries cause silent effect initialization failures.

Example snippet:

```xml
<effect-libraries>
    <lib name="dolby_dap" path="libswdapaidl.so"/>
    <lib name="dolby_vol" path="libdlbvolaidl.so"/>
</effect-libraries>

<effects>
    <effect name="dolby_dap" library="dolby_dap" uuid="..."/>
</effects>
```

If `audio_effects.xml` references a library that doesn't exist in `/vendor/lib64/soundfx/`, that's your culprit.

---

## 4. Investigating createIEffectMTK dlopen Failures

The `createIEffectMTK` function in the MTK audio effect HAL typically tries to `dlopen()` a Dolby or MTK audio library that may not be present in the current ROM.

### Step 1 — Inspect the HAL's own dynamic dependencies

```bash
adb shell readelf -d /vendor/lib64/hw/android.hardware.audio.effect.aidl-impl-mediatek.so | grep NEEDED
```

### Step 2 — Inspect Dolby soundfx library dependencies

```bash
adb shell readelf -d /vendor/lib64/soundfx/libswdapaidl.so        | grep NEEDED
adb shell readelf -d /vendor/lib64/soundfx/libdlbvolaidl.so        | grep NEEDED
adb shell readelf -d /vendor/lib64/soundfx/libswspatializeraidl.so | grep NEEDED
adb shell readelf -d /vendor/lib64/soundfx/libswgamedapaidl.so     | grep NEEDED
```

Any `NEEDED` entry without a matching `.so` in `/vendor/lib64/` (or `/vendor/lib64/soundfx/`) is a broken dependency.

### Step 3 — Enable verbose linker logging to catch silent dlopen failures

The Android linker supports `debug.ld.all` to dump failures for every `dlopen()`. Use `dlerror` to print only failed loads.

```bash
adb root
adb shell setprop debug.ld.all dlerror
adb shell stop && adb shell start

# Immediately grab logcat — the failing library name will be printed
adb logcat | grep -E "dlerror|dlopen.*failed|cannot locate" | head -20
```

### Step 4 — Reset the property when done

```bash
adb shell setprop debug.ld.all ""
```

> ⚠️ Leaving `debug.ld.all` set to a non-empty value can spam logcat and slow down library loading during normal use.

---

## 5. Tracing the Audio HAL at Runtime

### Option A — `strace` openat + dlopen on the audio service

```bash
adb root
adb shell "strace -e trace=openat,dlopen \
    /vendor/bin/hw/android.hardware.audio.service-aidl.mediatek \
    2>&1 | head -100"
```

Look for `openat(...) = -1 ENOENT` lines near `dlopen` calls. The path in the failed `openat` is the library the HAL tried to load.

### Option B — Enable linker debug + capture (no `strace` required)

```bash
adb root
adb shell setprop debug.ld.all dlerror
adb logcat -c && adb shell stop ; adb shell start
adb logcat | grep -E "dlerror|dlopen.*failed|cannot locate" | head -20
```

### Option C — Check runtime-loaded maps

```bash
# PID of the audio HAL service
adb shell pidof android.hardware.audio.service-aidl.mediatek

# Confirm which .so files are actually loaded
PID=$(adb shell pidof android.hardware.audio.service-aidl.mediatek)
adb shell cat /proc/$PID/maps | grep -iE "effect|dolby|audio" | awk '{print $6}' | sort -u
```

If a library is listed in `audio_effects.xml` but is absent from `/proc/<pid>/maps`, it never loaded — consistent with a silent `dlopen()` failure.

---

## 6. Discovering MTK-specific Vendor Libraries

### Libraries in `/vendor/lib64/`

```bash
adb shell ls /vendor/lib64/ | grep -iE "effect|mtkaudio|libmtk"
```

### Libraries in `/vendor/lib64/hw/` (HAL implementations)

```bash
adb shell ls /vendor/lib64/hw/ | grep -iE "effect|audio"
```

### Libraries in `/vendor/lib64/soundfx/` (effect plugins)

```bash
adb shell ls /vendor/lib64/soundfx/
```

### Full list of MTK audio-related libs

```bash
adb shell "ls /vendor/lib64/ /vendor/lib64/hw/ /vendor/lib64/soundfx/ \
    2>/dev/null | grep -iE 'audio|effect|mtk|dolby'"
```

### Common MTK / Dolby library names to look for

| Library | Purpose |
|---|---|
| `libswdapaidl.so` | Dolby DAP (Dynamic Audio Processing) |
| `libdlbvolaidl.so` | Dolby Volume |
| `libswspatializeraidl.so` | Dolby Spatializer |
| `libswgamedapaidl.so` | Dolby Game DAP |
| `libmtkaudio_utils.so` | MTK audio utility helpers |
| `libaudioeffect_sw.so` | Generic software effects |
| `android.hardware.audio.effect.aidl-impl-mediatek.so` | MTK effect HAL |

If `audio_effects.xml` declares one of these but the file is missing, either:
1. Add the missing library to the vendor partition (pull from another build), or
2. Remove the offending entry from `audio_effects.xml` to unblock the rest of the chain.

---

## 7. readelf Cheatsheet

`readelf` is available on most Android builds under `/system/bin/readelf` (or `/vendor/bin/readelf` on some vendor builds).

### List dynamic dependencies (NEEDED)
```bash
readelf -d <file.so> | grep NEEDED
```

### Full dynamic section
```bash
readelf -d <file.so>
```

### Check soname
```bash
readelf -d <file.so> | grep SONAME
```

### Check rpath / runpath
```bash
readelf -d <file.so> | grep -E "RPATH|RUNPATH"
```

### List exported symbols
```bash
readelf --dyn-syms <file.so> | grep -i "mtk\|effect"
```

### Check ELF class and ABI (32 vs 64 bit)
```bash
readelf -h <file.so> | grep -E "Class|Machine"
```

### Check for missing dependencies across a whole directory
```bash
for so in /vendor/lib64/soundfx/*.so; do
    echo "== $so"
    readelf -d "$so" | grep NEEDED
done
```

---

## 8. strace Cheatsheet

`strace` on Android requires either a userdebug/eng build with `strace` present, or a static `strace` binary pushed to `/data/local/tmp`.

### Install static strace (if missing)
```bash
# From your host
adb push strace /data/local/tmp/
adb shell chmod 755 /data/local/tmp/strace
```

### Trace a specific syscall family
```bash
# Only file-open related
strace -e trace=openat,open,stat,access <program>

# Only dlopen-equivalent (dlopen uses openat + mmap + close)
strace -e trace=openat,mmap,mprotect <program>

# Follow forks (useful for HALs that spawn threads/processes)
strace -f -e trace=openat,dlopen <program>
```

### Save trace to file
```bash
strace -o /data/local/tmp/audio_hal.strace \
    -f -e trace=openat,dlopen \
    /vendor/bin/hw/android.hardware.audio.service-aidl.mediatek

adb pull /data/local/tmp/audio_hal.strace .
```

### Filter output on host
```bash
grep -E "ENOENT|dlopen" audio_hal.strace | head -50
```

---

## 9. Quick Diagnostic Workflow

Copy-paste this block to go from "audio effect not working" to "here is the missing library" in a few minutes.

```bash
# ── 1. Capture boot-time state ─────────────────────────────
adb root
adb shell dmesg > dmesg.log
adb pull /data/tombstones/ .
adb shell cat /sys/fs/pstore/console-ramoops-0 > ramoops.log
adb logcat -b all > full_logcat.log

# ── 2. Confirm HAL dependencies resolve ────────────────────
adb shell readelf -d /vendor/lib64/hw/android.hardware.audio.effect.aidl-impl-mediatek.so \
    | grep NEEDED

# ── 3. Turn on linker debug and restart the audio service ─
adb shell setprop debug.ld.all dlerror
adb logcat -c && adb shell stop ; adb shell start

# ── 4. Grab the exact missing symbol / library ─────────────
adb logcat | grep -E "dlerror|dlopen.*failed|cannot locate" | head -20 > dlopen_errors.log

# ── 5. Cross-check against available vendor libs ───────────
adb shell ls /vendor/lib64/           | grep -iE "effect|mtkaudio|libmtk" > available_libs.txt
adb shell ls /vendor/lib64/soundfx/   | grep -iE "dolby|swda|dlb"        >> available_libs.txt

# ── 6. Inspect what actually loaded ────────────────────────
PID=$(adb shell pidof android.hardware.audio.service-aidl.mediatek)
adb shell cat /proc/$PID/maps | grep -iE "effect|dolby|audio" \
    | awk '{print $6}' | sort -u > loaded_libs.txt

# ── 7. Reset linker debug property ─────────────────────────
adb shell setprop debug.ld.all ""

echo "[*] Results:"
echo "    dlopen_errors.log     → exact missing library"
echo "    available_libs.txt    → what's on disk"
echo "    loaded_libs.txt       → what the HAL loaded"
```

### Decision tree

```
dlopen_errors.log shows a missing library?
├─ YES
│  ├─ Library exists in /vendor/lib64/ → check RUNPATH / ld.config (search path)
│  ├─ Library missing from disk        → add it OR remove from audio_effects.xml
│  └─ Library exists but wrong ABI     → 32-bit lib referenced by 64-bit HAL (or vice versa)
└─ NO
   └─ Failure is not a dlopen issue → fall back to strace (Section 5, Option A)
```

---

## 10. Notes

- `readelf` and `strace` binaries may not exist on user builds — pull from a matching userdebug image.
- `debug.ld.all` values: `dlerror` (failures only), `dlerror,dlopen` (verbose), `all` (very verbose). Always reset to empty afterwards.
- `/sys/fs/pstore/console-ramoops-0` persists across reboots but has limited size — capture it immediately after a crash.
- For the effect XML schema details, see `frameworks/av/media/libeffects/config/` in AOSP.
- For related SELinux denials on audio HAL (e.g. missing `vendor_file` access on `/vendor/lib64/soundfx/*.so`), see `02-selinux-avc-debugging.md`.
