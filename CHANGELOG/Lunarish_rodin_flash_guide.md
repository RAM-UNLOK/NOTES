# 🌙 Lunaris-AOSP v3.8 — Flash Guide

> **Android 16 QPR2 | 16.0.0_r4** — Community Build (Unofficial)

---

## ⚠️ Before You Begin — Read This First

> [!CAUTION]
> **Clean flash is required.** Dirty flashing over any previous ROM is NOT supported and may cause bootloops or data corruption.

> [!WARNING]
> **Remove your lockscreen PIN/password and ALL enrolled fingerprints BEFORE flashing.**
>
> Go to **Settings → Security** and:
> - Remove your PIN / Password / Pattern
> - Delete ALL enrolled fingerprints
>
> ⚠️ Skipping this step WILL cause your fingerprint sensor to become uncalibrated and stop working after flashing.
>
> 🔧 Already bricked your fingerprint? Here's how to fix it:
> 👉 [POCO X7 Pro — Exact Fingerprint Calibration Fix (AOSP)](https://telegra.ph/POCO-X7-Pro---The-EXACT-fingerprint-calibration-for-jiiov-12-27)

---

## 📥 Downloads

> [!IMPORTANT]
> **Download ALL files from the release page before starting.**
> Missing even one file will cause the flash to fail.

| File | Description |
|---|---|
| `lunaris-aosp-v3.8.zip` | Main ROM zip |
| `vendor_boot.img` | Vendor Boot Image |
| `boot.img` | Boot Image |
| `init_boot.img` | Init Boot Image |

---

## 🔌 Requirements

- ✅ ADB & Fastboot installed on your PC — [Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- ✅ USB Debugging enabled
- ✅ Bootloader unlocked
- ✅ All files downloaded
- ✅ Lockscreen & fingerprint removed

---

## 🚀 Flash Steps

### Step 1 — Flash Partitions via Fastboot

Boot your device into **Fastboot mode**, connect to PC, then run:

```bash
fastboot flash vendor_boot vendor_boot.img
```
```bash
fastboot flash boot boot.img
```
```bash
fastboot flash init_boot init_boot.img
```

> 💡 Wait for each command to complete with `OKAY` before running the next one.

---

### Step 2 — Reboot to Recovery

After flashing, reboot your device. As soon as the screen goes off:

```bash
fastboot reboot recovery
```

> 💡 **Alternatively:** Hold **Volume Up** while the phone reboots to enter recovery manually.

> 🔺 Use **Volume Up / Volume Down** to navigate and **Power Button** to select.

---

### Step 3 — Format Data ( SKIP IF YOU ARE UPDATING SAME ROM BY ME )

Once in recovery, navigate to:

```
Factory Reset → Format Data / Factory Reset → Format Data
```

> [!CAUTION]
> This will **erase all data** on your device. This step is mandatory for a clean flash.

---

### Step 4 — Sideload the ROM

From recovery, go to:

```
Apply Update → Apply from ADB
```

Then on your PC, run:

```bash
adb sideload lunaris-aosp-v3.8.zip
```

> 💡 Sideload may appear to stop at 47% or 97% — this is **normal**. Wait for recovery to respond.

---

### Step 5 — Reboot to Recovery (Again)

Once sideload finishes, recovery will ask:

```
"Reboot to recovery?" → Select YES
```

> This step ensures caches are properly cleared before first boot.

---

### Step 6 — Reboot to System

From recovery, select:

```
Reboot System Now
```

First boot may take **3–5 minutes**. This is normal. Do not panic. 🧘

---

## ✅ Done!

```
🌙 Welcome to Lunaris-AOSP v3.8
```

Enjoy the ROM! For GCam setup, grab the XML & libs here:
👉 [GCam XML & Custom Library](https://t.me/hugo_gcam/256)

---

> 🌙 *Lunaris-AOSP — First major release. Thank you for the support! ❤️*
