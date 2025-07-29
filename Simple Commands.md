<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# yes do extra formatting, descriptions for every section and command

Absolutely! Below is a clearly formatted, easy-to-navigate Markdown reference. Each command is in its own code block, with section and command descriptions. This is perfect for copying, reference, and quick use.

---
# 📱 ADB \& Fastboot Command Reference

A handy guide for ADB/Fastboot usage, logging, device recovery, partition management, and more.

## 🔑 Device Authorization Fix

> **Purpose:** Bypass ADB “unauthorized” issues by manually adding your PC’s ADB key to the device (usually via recovery mode).

**On Linux/macOS: Push your ADB public key to the device**

```bash
adb push ~/.android/adbkey.pub /data/misc/adb/adb_keys
```

**On Windows: Push your ADB public key to the device**
*(Replace USERNAME with your Windows username)*

```bash
adb push C:\Users\USERNAME\.android\adbkey.pub /data/misc/adb/adb_keys
```


## 📝 Basic Logging

> **Purpose:** Collect standard Android, kernel, and crash logs for troubleshooting.

**Get the main Android logcat log (all standard logs):**

```bash
adb logcat -d > logcat.log
```

**Fetch kernel ring buffer (system core logs, hardware info):**

```bash
adb shell dmesg > dmesg.log
```

**Download persistent storage crash logs (ramoops/pstore):**

```bash
adb pull /sys/fs/pstore
```

**Retrieve the last kernel message (after a crash or panic):**

```bash
adb pull /proc/last_kmsg
```


## 🆘 Recovery Mode Logs (If Device Will Not Boot)

> **Purpose:** Extract deep logs and modem/core dumps if Android can't boot—typically used with custom recoveries (e.g., TWRP).

**Dump the expdb partition (modem/debug info) to a temp image:**

```bash
adb shell dd if=/dev/block/by-name/expdb of=/tmp/expdb.img
```

**Extract readable text/strings from the raw expdb image:**

```bash
adb shell strings /tmp/expdb.img > expdb.txt
```


## ⏩ Extended Boot \& Crash Logs

> **Purpose:** Access detailed boot, crash, and kernel logs stored in device metadata.

**Restart ADB daemon with root privileges (may require root):**

```bash
adb root
```

**Pull the complete boot log from the device's metadata partition:**

```bash
adb pull /metadata/boot_log_full.txt
```

**Retrieve the crash boot log:**

```bash
adb pull /metadata/boot_log_crash.txt
```

**Get the kernel boot log from metadata:**

```bash
adb pull /metadata/boot_log_kernel.txt
```


## 🚀 Bootloader and Flashing Operations

> **Purpose:** Reboot into bootloader/fastboot mode, and flash or sideload partitions and images.

**Reboot your device into bootloader/fastboot mode:**

```bash
adb reboot bootloader
```

**Flash the vendor boot partition (slot a):**

```bash
fastboot flash vendor_boot_a vendor_boot.img
```

**Flash the vendor boot partition (slot v):**

```bash
fastboot flash vendor_boot_v vendor_boot.img
```

**Flash the init boot partition (slot a):**

```bash
fastboot flash init_boot_a init_boot.img
```

**Flash the init boot partition (slot b):**

```bash
fastboot flash init_boot_b init_boot.img
```

**Flash the main boot partition (slot a):**

```bash
fastboot flash boot_a boot.img
```

**Flash the main boot partition (slot b):**

```bash
fastboot flash boot_b boot.img
```

**Sideload a ROM or update ZIP via recovery:**

```bash
adb sideload rom.zip
```


## 🧩 Partition Info \& Advanced Tools

> **Purpose:** Inspect partitions, install essential Android tools, and fetch advanced partition details (usually requires root).

**Show your device's partition table (requires root):**

```bash
su -c cat /proc/partitions
```

**Install ADB and fastboot tools using Termux (Android terminal app):**

```bash
pkg install android-tools
```

**Dump logical partition configuration (dynamic partitions, requires root):**

```bash
su -c lpdump
```

**Show the size in bytes of the 'super' partition:**

```bash
blockdev --getsize64 /dev/block/by-name/super
```

**Show the size in bytes of the 'dtbo_a' partition:**

```bash
blockdev --getsize64 /dev/block/by-name/dtbo_a
```

**Tip:**

- For Windows-specific commands, always replace `USERNAME` with your current Windows username.
- For any root-required commands (`su -c ...`), your device must have root access.
- Be very cautious with flashing and partition commands—they can brick devices if used incorrectly!

Let me know if you want color highlights, more categories, or added tips!

