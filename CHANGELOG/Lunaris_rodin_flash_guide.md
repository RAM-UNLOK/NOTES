=====================================================
    🌕 LUNARIS-AOSP v3.8 | STABLE RELEASE 🌕
=====================================================
  Device:       POCO X7 Pro (rodin)
  Build Date:   2026-03-11
  Maintainer:   @rakmoparte
  Android:      16 QPR2 (16.0.0_r4)
=====================================================

🚀 RELEASE STATUS: FIRST STABLE
This is our first stable milestone after the initial 
preview. It includes 28 targeted commits for hardware 
stability, performance, and display optimization.

-----------------------------------------------------
⚠️ IMPORTANT NOTES (READ BEFORE USE)
-----------------------------------------------------
1. XIAOMI CIT: Found in "About Phone" above the 
   "Build Number" block.
   - ONLY use CIT for Fingerprint and Speaker 
     Calibration. 
   - DO NOT use other tests; it will cause system 
     crashes and broken sensors.

2. REFRESH RATE: If you experience display flickering, 
   manually set the rate to 120Hz in Display Settings.

3. GCAM: For custom libs and configs, please install 
   the gcam_signed.apk manually after flashing.

=====================================================
      🚀 INSTALLATION & CALIBRATION GUIDE 🚀
=====================================================

❗ PRE-REQUISITES:
- CLEAN FLASH: Mandatory if coming from MIUI/HyperOS 
  or any other AOSP ROM.
- DIRTY FLASH: Only supported if you are already on 
  a previous Lunaris-AOSP build.
- Remove lockscreen PIN/Password and DELETE all 
  enrolled fingerprints BEFORE flashing.

STEP 1: FLASH PARTITIONS (FASTBOOT)
(SKIP this step if you are already on an existing 
AOSP-based ROM)
> fastboot flash vendor_boot vendor_boot.img
> fastboot flash boot boot.img

STEP 2: FORMAT & SIDELOAD
- Reboot to Recovery (Vol Up + Power).
- FORMAT DATA: Select Factory Reset -> Format Data.
  (SKIP this only if Dirty Flashing from previous Lunaris)
- Apply Update -> Apply from ADB.
- Run: > adb sideload lunaris-aosp-v3.8.zip
- Recovery will ask: "Reboot to recovery?" -> Select YES.
- Select: Reboot System Now.

🛠️ CIT CALIBRATION (FOD & SPEAKER)
If sensors feel uncalibrated, follow this EXACTLY:
1. Settings > About Phone > Xiaomi CIT.
2. 3-dot menu (Top Right) > Additional Tools.
3. Select Option 5 (FOD) or Option 8 (Speaker).
4. ❗ IMPORTANT: Once finished, REBOOT IMMEDIATELY. 
   Do not close the app or go back.

⚡ ROOT ACCESS (KSU NEXT)
Reboot to Fastboot and run:
> fastboot flash init_boot kernelsu_next_patched_init_boot.img

-----------------------------------------------------
🔗 OFFICIAL LINKS
-----------------------------------------------------
📁 Device Tree: https://github.com/Digimend-X-Rodin/android_device_xiaomi_rodin/tree/Lunaris-AOSP
📸 GCam XMLs:   https://t.me/XydrionXUpdates
💬 Support:     @rakmoparte

❤ Thank you for supporting Lunaris-AOSP!
=====================================================