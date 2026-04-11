=====================================================
    🌕 LUNARIS-AOSP v3.9 | STABLE RELEASE 🌕
=====================================================
  Device:       POCO X7 Pro (rodin)
  Build Date:   2026-04-11
  Maintainer:   @rakmoparte
=====================================================

🚀 RELEASE STATUS
This is our second Stable Build, bringing a massive 
under-the-hood rework. We have rebased to Android 16 
QPR2, updated proprietary blobs to OS3.0.10.0, and 
introduced over 50+ device tree improvements targeted 
at stock-like performance, audio, and battery life.

📺 SYSTEM & UI
- Updated proprietary blobs to OS3.0.10.0.WOJMIXM.
- Rebased build environment to Android 16 QPR2.
- Added MinRefreshRateCtrl to force 60Hz minimum 
  and fix 30Hz low-brightness screen flickering.
- Fixed lockscreen UI overlap with the UDFPS sensor.
- Fixed "Charging Rapidly" accuracy on lockscreen.
- Added Battery Cycle Count in Settings.
- Enabled system animation lag fixes for MTK.

⚡ PERFORMANCE, POWER & SECURITY
- Fully migrated to stock MTK thermal profiles and 
  power hints for optimal battery and heat control.
- Aggressively re-tuned Low Memory Killer (LMK) for 
  better multitasking and faster camera load times.
- Capped default game refresh rates to 60fps to 
  reduce thermal throttling during long sessions.
- Switched to IMPL_VER V2 for the fingerprint sensor 
  to improve reliability and unlock speed.
- Fixed Fingerprint Calibration read/write permissions 
  and added missing JIIOV sensor data paths.
- Overhauled SEPolicy to resolve extensive hardware 
  denials (Audio, Camera, RIL, Power, eSE) and clean 
  up redundant rules.

📸 CAMERA & AUDIO
- Switched to Aperture as the default camera app 
  (Pre-installed GCam has been removed).
- Enabled MediaTek HFPS (60FPS video) and EIS 
  (Video Stabilization) support for the main lens.
- Switched to Sony Dolby 1.5 (by swiitch-OFF-Lab) 
  and merged our stock Dolby DAX spatializer tunings.
- Fixed WhatsApp and VoIP call audio silence/crashes.
- Fixed audio/video de-sync issues by disabling 
  buggy hardware audio offloading.
- Cleaned up the media stack by using stock Codec2 
  blobs and dropping redundant hardware codecs.
- Added Speaker Calibration wavs and enabled it 
  via the Xiaomi CIT application.

📶 NETWORK & CONNECTIVITY
- Fully integrated stock MediaTek IMS components 
  for highly reliable VoLTE and ViLTE support.
- Imported MTK wlan OUI changes to improve 
  overall Wi-Fi connection stability.
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