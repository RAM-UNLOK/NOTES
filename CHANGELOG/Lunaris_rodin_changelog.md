=====================================================
    🌕 LUNARIS-AOSP v3.9 | Unofficial Release 🌕
=====================================================
  Device:       POCO X7 Pro (rodin)
  Build Date:   2026-04-19
  Maintainer:   @rakmoparte
=====================================================

🚀 RELEASE STATUS
This is our second Stable Build, bringing a massive 
under-the-hood rework. We have rebased to Android 16 
QPR2, updated proprietary blobs to OS3.0.10.0, and 
introduced over 50+ device tree improvements targeted 
at stock-like performance, audio, and battery life.

# Changelog - Build 3

### 🚀 System & UI
- Fixed dynamic refresh rate (VRR) to allow power-saving 30Hz downclocking at idle.
- Disabled limited alpha to fix notification background glitches when blur is enabled.
- Improved UDFPS LHBM handling to properly toggle FOD status and NIT during authentication.
- Cleaned up kernel cmdline and removed unnecessary vendor extraction patches.
- Added init configuration for USB OTG support and audio calibration.

### ⚡ Performance, Power & Security
- Added MiCharge 90W fast charging and Battery Anti-Aging support.
- Optimized PowerHAL, schedutil, and GPU DVFS for balanced thermal performance.
- Added proprietary GPU Game Driver support for the mt6899 platform.
- Tuned storage I/O queues and expanded block device read-ahead for better efficiency.
- Overhauled SELinux policies to resolve hardware denials for charging and graphics.


=====================================================
  Device:       POCO X7 Pro (rodin)
  Build Date:   2026-04-11
  Maintainer:   @rakmoparte
=====================================================

# Changelog - Build 2

### 🚀 System & UI
- Rebased to Android 16 QPR2 with 50+ device tree improvements.
- Updated proprietary blobs to OS3.0.10.0.WOJMIXM.
- Added MinRefreshRateCtrl (Fixes 30Hz flicker/60Hz minimum).
- Fixed lockscreen UDFPS overlap and "Charging Rapidly" accuracy.
- Added Battery Cycle Count in Settings.
- Fixed MTK system animation lags.

### ⚡ Performance, Power & Security
- Fully migrated to stock MTK thermal profiles and power hints.
- Re-tuned LMK for better multitasking and camera load times.
- Capped game refresh rates to 60fps for better thermals.
- Upgraded Fingerprint to IMPL_VER V2 for faster unlocks.
- Fixed Fingerprint calibration and JIIOV sensor data paths.
- Massive SEPolicy overhaul to fix hardware denials (Audio, Camera, RIL).

### 📸 Camera & Audio
- Replaced GCam with Aperture as the default camera.
- Enabled 60FPS video (HFPS) and EIS stabilization.
- Switched to Sony Dolby 1.5 with stock DAX spatializer tunings.
- Fixed WhatsApp/VoIP audio silence and A/V de-sync.
- Cleaned media stack using stock Codec2 blobs.
- Added Speaker Calibration support via Xiaomi CIT.

### 📶 Network & Connectivity
- Integrated stock MediaTek IMS (Reliable VoLTE/ViLTE).
- Improved Wi-Fi stability via MTK wlan OUI updates.
- Added full NXP PN54x/PN5xx NFC support binaries.

-----------------------------------------------------
⚠️ IMPORTANT NOTES (READ BEFORE USE)
-----------------------------------------------------
1. XIAOMI CIT: Found in "About Phone" above the 
   "Build Number" block.
   - ONLY use CIT for Fingerprint and Speaker 
     Calibration.
   - DO NOT use other tests; it will cause system 
     crashes and sensor issues.

2. REFRESH RATE: Minimum refresh rate is strictly 
   locked to 60Hz via MinRefreshRateCtrl to prevent 
   AOD/display flickering issues.

3. APERTURE CAMERA: To successfully achieve 60FPS 
   video recording support on the main lens, we had 
   to drop support for the ultra-wide camera. The 
   ultra-wide lens will not be available.

-----------------------------------------------------
🔗 OFFICIAL LINKS
-----------------------------------------------------
📁 Device Tree: https://github.com/Digimend-X-Rodin/android_device_xiaomi_rodin/tree/Lunaris-AOSP
💬 Support:     @rakmoparte

❤ Thank you for building Lunaris-AOSP!
=====================================================