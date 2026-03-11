=====================================================
    🌕 LUNARIS-AOSP v3.8 | STABLE RELEASE 🌕
=====================================================
  Device:       POCO X7 Pro (rodin)
  Build Date:   2026-03-11
  Maintainer:   @rakmoparte
=====================================================

🚀 RELEASE STATUS
This is the First Stable Build following our initial 
release. It includes 28 targeted commits to the device 
tree focused on hardware stability, performance 
tuning, and display optimization.

📸 CAMERA & VISUALS
- Integrated GCam LMC 8.3 by Xenius9 (RC60).
- Fixed dark/low-light issues during video calls.
- Resolved FOD (Fingerprint) light staying ON after 
  enrollment (JIIOV sensor).
- Updated media profiles and video codecs for rodin.

⚡ PERFORMANCE & POWER
- Fixed Fast Charging support for up to 65W PD chargers.
- Improved Memory Management (LMKD optimizations).
- Tuned Thermal & Power profiles for better efficiency.
- Fixed Game Refresh/Frame Rate drops (Forced 120Hz).
- Optimized I/O scheduler for faster app opening.

📺 SYSTEM & UI
- Forced 120Hz Refresh Rate for consistent smoothness.
- Added Xiaomi CIT (Calibration Tool) in Settings.
- Integrated Moto Dolby Atmos & Pixel Player.
- Updated Build Fingerprints for CTS/Play Integrity.
- General UI smoothness and transition improvements.

-----------------------------------------------------
⚠️ IMPORTANT NOTES (READ BEFORE USE)
-----------------------------------------------------
1. XIAOMI CIT: Found in "About Phone" above the 
   "Build Number" block.
   - ONLY use CIT for Fingerprint and Speaker 
     Calibration.
   - DO NOT use other tests; it will cause system 
     crashes and sensor issues.

2. REFRESH RATE: If you experience display flickering, 
   manually set the rate to 120Hz in Display Settings.

3. GCAM INSTALLATION: To use custom configs and libs, 
   you MUST install the 'gcam_signed.apk' over the 
   pre-installed version.
   - Importing/applying configs directly on the 
     stock build version WILL cause a crash.

-----------------------------------------------------
🔗 OFFICIAL LINKS
-----------------------------------------------------
📁 Device Tree: https://github.com/Digimend-X-Rodin/android_device_xiaomi_rodin/tree/Lunaris-AOSP
📸 GCam XMLs:   https://t.me/XydrionXUpdates
💬 Support:     @rakmoparte

❤ Thank you for building Lunaris-AOSP!
=====================================================