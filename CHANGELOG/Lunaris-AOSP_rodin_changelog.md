# 🌙 Lunaris-AOSP v3.8 — Full Changelog

> Android 16 QPR2 | GApps | Community Build (Unofficial) | 03-05-2026
>
> 👨‍💻 [rakmoparte](https://github.com/RAM-UNLOK) · 🌿 [Device Tree](https://github.com/Digimend-X-Rodin)

---

## 🧩 Core & Blobs

- Upstream Blobs to OS3.0.9.0.WOJMIXM (Global Latest Firmware)
- Patched fatal issue related to Blobs and permissions needed for QPR2 to boot
- Upstream Kernel to 6.6.69 from OS3.0.9.0.WOJMIXM
- Upstream tons of Build Props from OS3.0.9.0.WOJMIXM

---

## ⚙️ System & Performance

- Fixed Sepolicy and updated i2c labels
- Heavily updated Powerhint & Thermal for our device specifications
- Updated dex2oat optimizations to match stock
- Updated Generic names on Bluetooth Hotspot and Wi-Fi to our device names
- Updated tons of Overlay Configs from stock OS3.0.9.0.WOJMIXM
- Updated Device Cutout and padding from stock properly
- Corrected Power Profile for accurate Battery Usage Stats

---

## 📱 Display & Device

- Dropped X-Reality Engine — resulted in non-responsive bright white screen
- Optimised Brightness to be slightly dimmer than stock indoors

---

## 🎵 Audio

- Added Moto 1.4 Dolby Atmos by [swiitch-OFF-Lab](https://github.com/swiitch-OFF-Lab)

---

## 📦 Included Apps

- 📞 **AOSP Dialer** — with built-in call recording support
- 🎶 **Pixel Music Player** by [theovilardo](https://github.com/theovilardo/PixelPlayer)

---

## 🐛 Known Bugs

### Source Side
- Dynamic Refresh Rate Option Not Visible
- X-Reality Display Engine issues

### Device Side _(ROM is fully stable)_
- 90W Charging won't work — may be fixed in next major build
- Spatial Audio won't work — Dolby Atmos works fine
  _(may be fixed in next hyperos firmware release build)_

> 💪 Don't let the bugs scare you! These are minor issues and won't affect your daily experience — ROM is rock solid! ✅

- If Incoming call ringtone volume drops 50% Suddenly — Go Back To Stock and calibrate your speakers

---

## 🙏 Credits

| Contributor | Role |
|---|---|
| [@rakmoparte](https://t.me/rakmoparte) — [GitHub](https://github.com/RAM-UNLOK) | Developer |
| [@rthedream](https://t.me/rthedream) | Base Device Tree |
| [@loki_pushes](https://t.me/loki_pushes) — Project Aerodactyl | Device Tree cherry-picks |
| [@EndoXx0](https://t.me/EndoXx0) | Testing & Bug Reports |
| [@JOEDMOBE13](https://t.me/JOEDMOBE13) | Testing & Bug Reports |
| [swiitch-OFF-Lab](https://github.com/swiitch-OFF-Lab) | Moto 1.4 Dolby Atmos |
| [theovilardo](https://github.com/theovilardo/PixelPlayer) | Pixel Music Player |
| Xenius9 | GCam LMC 8.3 Mod R41 |

---

> 🌙 This is my first major release. Thank you for the support and enjoy Lunaris-AOSP! ❤️
