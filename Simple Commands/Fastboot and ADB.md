<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# add additional logs extractions method and create me anew markdown

Here's your complete new markdown file with expanded log extraction methods:

***

<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# 📱 ADB \& Fastboot Command Reference

A comprehensive guide for ADB/Fastboot usage, logging, device recovery, partition management, slot operations, and more.

***

## 🔌 Device Connection \& Status

> **Purpose:** Check device connectivity and basic information in both ADB and fastboot modes.

**List all connected devices in ADB mode:**

```bash
adb devices
```

Shows all devices/emulators visible to ADB along with their authorization state.[^1][^2]

**Check device connection in fastboot/bootloader mode:**

```bash
fastboot devices
```

Lists devices detected in fastboot mode to confirm USB connection and driver setup.[^3][^4]

**Get detailed device and bootloader information:**

```bash
fastboot getvar all
```

Prints comprehensive bootloader info including partition sizes, slot info, device model, and software versions.[^4][^3]

**Check current active slot (A/B devices):**

```bash
fastboot getvar current-slot
```

Shows which slot (a or b) is currently active on A/B system devices.[^5][^3]

## 🔑 Device Authorization Fix

> **Purpose:** Bypass ADB "unauthorized" issues by manually adding your PC's ADB key to the device (usually via recovery mode).

**On Linux/macOS: Push your ADB public key to the device**

```bash
adb push ~/.android/adbkey.pub /data/misc/adb/adb_keys
```

**On Windows: Push your ADB public key to the device**
*(Replace USERNAME with your Windows username)*

```bash
adb push C:\Users\USERNAME\.android\adbkey.pub /data/misc/adb/adb_keys
```


## 🔄 Reboot Operations

> **Purpose:** Restart device into different modes for maintenance, flashing, or recovery operations.

**Reboot device normally to Android system:**

```bash
adb reboot
```

Standard restart back into Android OS.[^1][^3]

**Reboot into bootloader/fastboot mode:**

```bash
adb reboot bootloader
```

Enters fastboot mode for flashing and bootloader operations.[^3][^1]

**Reboot into recovery mode:**

```bash
adb reboot recovery
```

Boots into recovery environment (stock or custom like TWRP).[^1][^3]

**Reboot from fastboot back to system:**

```bash
fastboot reboot
```

Restarts device from fastboot mode back to Android.[^4][^3]

## 📝 Basic Logging

> **Purpose:** Collect standard Android, kernel, and crash logs for troubleshooting.

**Get the main Android logcat log (all standard logs):**

```bash
adb logcat -d > logcat.log
```

Dumps the entire log buffer to a file and exits.[^6][^7]

**Save continuous logcat output to a file:**

```bash
adb logcat -f /sdcard/logcat.txt
```

Writes log messages continuously to a file on the device.[^7][^6]

**View specific log buffer (events, radio, system, crash):**

```bash
adb logcat -b events
adb logcat -b radio
adb logcat -b system
adb logcat -b crash
```

Displays logs from alternative buffers like radio modem, system events, or crash logs.[^6][^7]

**View multiple buffers simultaneously:**

```bash
adb logcat -b main -b system -b crash
```

Combines output from multiple log buffers in one stream.[^6]

**Filter logcat by priority level (V/D/I/W/E/F):**

```bash
adb logcat *:E
adb logcat *:W
```

Shows only Error (E) or Warning (W) level messages and higher, reducing noise.[^7][^6]

**Filter logcat by tag:**

```bash
adb logcat ActivityManager:I *:S
```

Displays only ActivityManager logs at Info level and silences all others.[^6]

**Clear the log buffer:**

```bash
adb logcat -c
```

Flushes all current log entries from the buffer.[^7][^6]

**Check log buffer size:**

```bash
adb logcat -g
```

Prints the current size of the specified log buffer.[^7][^6]

**Fetch kernel ring buffer (system core logs, hardware info):**

```bash
adb shell dmesg > dmesg.log
```

Captures low-level kernel messages including driver, hardware, and boot information.

**Download persistent storage crash logs (ramoops/pstore):**

```bash
adb pull /sys/fs/pstore
```

Retrieves kernel panic and crash logs preserved across reboots.

**Retrieve the last kernel message (after a crash or panic):**

```bash
adb pull /proc/last_kmsg
```

Gets the kernel log from immediately before the last system crash (legacy method).

## 🐛 System Diagnostics \& Bug Reports

> **Purpose:** Generate comprehensive system diagnostic reports containing all logs, system state, and configuration data.

**Generate a complete bug report (Android 7.0+):**

```bash
adb bugreport bugreport.zip
```

Creates a full diagnostic archive including logcat, dmesg, dumpsys output, tombstones, ANR traces, and system configuration.[^8][^9]

**Generate bug report to current directory (older format):**

```bash
adb bugreport > bugreport.txt
```

Outputs all diagnostic data as a text file (pre-Android 7.0 format).[^8]

**Dump all system services information:**

```bash
adb shell dumpsys > dumpsys_all.txt
```

Generates diagnostic output for every system service running on the device.[^10]

**Dump specific system service (battery example):**

```bash
adb shell dumpsys battery
```

Shows detailed battery statistics, health, voltage, temperature, and charging state.[^10]

**Dump memory information:**

```bash
adb shell dumpsys meminfo
```

Displays memory usage breakdown by process and system.[^10]

**Dump package information for specific app:**

```bash
adb shell dumpsys package com.example.app
```

Shows detailed information about an installed package including permissions, activities, and services.[^10]

**Dump activity manager state:**

```bash
adb shell dumpsys activity
```

Displays current activity stack, recent tasks, and process information.[^10]

**Dump input device information:**

```bash
adb shell dumpsys input
```

Shows state of input devices like touchscreens, keyboards, and input event processing.[^10]

**Dump network diagnostics:**

```bash
adb shell dumpsys wifi
adb shell dumpsys connectivity
```

Provides WiFi connection details, network interfaces, and connectivity status.[^10]

**List all available system services:**

```bash
adb shell dumpsys -l
```

Shows all services that can be queried with dumpsys.[^10]

## 💀 Crash Logs \& Tombstones

> **Purpose:** Extract native crash dumps and application not responding (ANR) traces for debugging crashes.

**List available tombstone files:**

```bash
adb shell ls /data/tombstones/
```

Shows all tombstone crash dumps stored on the device (requires root or bugreport).[^11][^12]

**Pull a specific tombstone file (requires root):**

```bash
adb pull /data/tombstones/tombstone_01 ./
```

Downloads a native crash dump containing stack traces, memory maps, and register states.[^12][^11]

**Extract tombstones from bug report (non-rooted devices):**

```bash
adb bugreport bugreport.zip
```

Tombstones are included in the zip under `FS/data/tombstones/` directory.[^9][^8]

**Get stack trace from a running process (requires debuggerd):**

```bash
adb shell debuggerd -b <PID>
```

Generates a backtrace for all threads in a running process without killing it.[^11]

**Pull ANR traces (Application Not Responding):**

```bash
adb pull /data/anr/traces.txt ./
```

Retrieves stack traces generated when apps become unresponsive (requires root or bugreport).[^13][^12]

**Monitor for new tombstones in real-time:**

```bash
adb shell "while true; do ls -la /data/tombstones/; sleep 2; done"
```

Continuously checks for new crash dumps being created.

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

**Pull recovery logs from TWRP or custom recovery:**

```bash
adb pull /tmp/recovery.log ./
```

Gets the recovery operation log when booted into custom recovery mode.

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


## 📦 App \& Package Management

> **Purpose:** Install, uninstall, and manage applications on Android devices.

**Install an APK to the device:**

```bash
adb install app.apk
```

Installs an Android application package to the connected device.[^2][^1]

**Install APK to a specific location (internal/external storage):**

```bash
adb install -s app.apk
```

Forces installation to external storage if supported.[^1]

**Reinstall an app keeping its data:**

```bash
adb install -r app.apk
```

Updates an existing app without removing user data.[^1]

**Uninstall an app by package name:**

```bash
adb uninstall com.example.app
```

Removes an installed application using its package identifier.[^2][^1]

**Uninstall app but keep its data:**

```bash
adb uninstall -k com.example.app
```

Removes the app but preserves data and cache directories.[^1]

**List all installed packages:**

```bash
adb shell pm list packages
```

Displays all installed app package names on the device.[^2]

**List only system packages:**

```bash
adb shell pm list packages -s
```

Shows system apps only.[^1]

**List only third-party packages:**

```bash
adb shell pm list packages -3
```

Shows user-installed apps only.[^1]

**List enabled packages:**

```bash
adb shell pm list packages -e
```

Shows only enabled applications.[^1]

**List disabled packages:**

```bash
adb shell pm list packages -d
```

Shows only disabled applications.[^1]

## 📁 File Transfer Operations

> **Purpose:** Transfer files between computer and Android device.

**Push a file from computer to device:**

```bash
adb push localfile.txt /sdcard/
```

Copies a file from your PC to the device storage.[^2][^1]

**Pull a file from device to computer:**

```bash
adb pull /sdcard/remotefile.txt .
```

Downloads a file from the device to your current directory.[^2][^1]

**Pull an entire directory:**

```bash
adb pull /sdcard/DCIM/ ./backup/
```

Copies a complete folder from device to PC.[^1]

**Push multiple files using wildcards:**

```bash
adb push *.jpg /sdcard/Pictures/
```

Transfers all matching files in one operation.

## 🖥️ Shell \& Command Execution

> **Purpose:** Execute commands directly on the Android device.

**Open an interactive shell on the device:**

```bash
adb shell
```

Launches a terminal session on the device for running commands.[^2][^1]

**Execute a single command without staying in shell:**

```bash
adb shell ls -la /sdcard/
```

Runs one command and returns to your PC terminal.[^1]

**Run a command with root privileges (requires root):**

```bash
adb shell su -c "command"
```

Executes commands as superuser on rooted devices.[^1]

**Get device properties:**

```bash
adb shell getprop
```

Displays all system properties and build information.

**Get specific property value:**

```bash
adb shell getprop ro.build.version.release
```

Shows Android version number.

**Set a system property (requires root):**

```bash
adb shell setprop debug.myapp.level verbose
```

Modifies system properties for debugging purposes.

## 🎯 Slot-Aware Fastboot Commands (A/B Devices)

> **Purpose:** Manage A/B (seamless update) system slots for flashing and booting operations.

**Flash to all slots simultaneously:**

```bash
fastboot --slot all flash boot boot.img
```

Flashes the image to both slot_a and slot_b in one command, useful for maintaining identical slots on A/B devices.[^14][^4]

**Flash to a specific slot (a or b):**

```bash
fastboot --slot a flash boot boot.img
fastboot --slot b flash system system.img
```

Explicitly targets slot_a or slot_b for slotted partitions.[^14][^4]

**Flash to the inactive (other) slot:**

```bash
fastboot --slot other flash boot boot.img
```

Targets whichever slot is currently not active, useful when preparing the backup slot.[^15][^14]

**Set active slot for next boot:**

```bash
fastboot --set-active=a
fastboot --set-active=b
```

Marks the specified slot as active so the device boots from it on next restart.[^5][^3]

## 🚀 Bootloader \& Flashing Operations

> **Purpose:** Flash partitions, unlock/lock bootloader, and sideload updates.

**Unlock bootloader (device-dependent, may wipe data):**

```bash
fastboot flashing unlock
```

Unlocks bootloader to allow custom ROM and image flashing. This typically wipes all data for security.[^3]

**Lock bootloader (may wipe data):**

```bash
fastboot flashing lock
```

Locks bootloader back to secure state, often required for warranty or security compliance.[^3]

**Flash common partitions:**

```bash
fastboot flash boot boot.img
fastboot flash recovery recovery.img
fastboot flash system system.img
```

Replaces partition contents with new images from stock or custom ROMs.[^4][^3]

**Flash the vendor boot partition (slot a):**

```bash
fastboot flash vendor_boot_a vendor_boot.img
```

**Flash the vendor boot partition (slot b):**

```bash
fastboot flash vendor_boot_b vendor_boot.img
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

**Boot an image temporarily without flashing:**

```bash
fastboot boot recovery.img
```

Loads and boots an image once into RAM without writing to storage—perfect for testing custom recoveries like TWRP.[^4][^3]

**Flash all partitions from extracted factory image:**

```bash
fastboot flashall
```

Automatically flashes all partitions from the current directory (requires specific file naming convention).[^3]

**Sideload a ROM or update ZIP via recovery:**

```bash
adb sideload rom.zip
```

Installs update packages through recovery mode when device is in sideload mode.

## 🗑️ Wipe \& Format Operations

> **Purpose:** Clear or reformat partitions for factory resets or troubleshooting.

**Erase a specific partition:**

```bash
fastboot erase userdata
fastboot erase cache
```

Clears partition contents without reformatting the filesystem.[^4][^3]

**Format a partition (recreates filesystem):**

```bash
fastboot format cache
fastboot format userdata
```

Completely reformats the partition, often used when a partition is corrupted.[^3][^4]

**Full factory wipe (userdata + cache):**

```bash
fastboot -w
```

Performs a complete factory reset by wiping userdata and cache partitions in one command.[^3]

## 🧩 Partition Info \& Advanced Tools

> **Purpose:** Inspect partitions, install essential Android tools, and fetch advanced partition details (usually requires root).

**Show your device's partition table (requires root):**

```bash
adb shell su -c "cat /proc/partitions"
```

**List all block devices with names:**

```bash
adb shell ls -la /dev/block/by-name/
```

Shows symbolic links to all named partitions on the device.

**Install ADB and fastboot tools using Termux (Android terminal app):**

```bash
pkg install android-tools
```

**Dump logical partition configuration (dynamic partitions, requires root):**

```bash
adb shell su -c lpdump
```

Shows detailed super partition layout for devices with dynamic partitions.

**Show the size in bytes of the 'super' partition:**

```bash
adb shell blockdev --getsize64 /dev/block/by-name/super
```

**Show the size in bytes of the 'dtbo_a' partition:**

```bash
adb shell blockdev --getsize64 /dev/block/by-name/dtbo_a
```

**Backup a partition to a file:**

```bash
adb shell su -c "dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img"
adb pull /sdcard/boot_backup.img ./
```

Creates a raw image backup of a partition (requires root).

**Restore a partition from a backup:**

```bash
adb push boot_backup.img /sdcard/
adb shell su -c "dd if=/sdcard/boot_backup.img of=/dev/block/by-name/boot"
```

Writes a backup image back to the partition (requires root, very dangerous if used incorrectly).

***

## ⚠️ Important Notes

- **For Windows-specific commands:** Always replace `USERNAME` with your actual Windows username in file paths.
- **Root requirements:** Commands with `su -c` require root access on your device.
- **Bootloader unlocking:** Unlocking the bootloader typically wipes all data and may void warranty on some devices.
- **Slot operations:** `--slot all` and slot-specific commands only work on A/B (seamless update) devices, not on older A-only devices.
- **Safety warning:** Be extremely cautious with flashing and partition commands—incorrect usage can brick your device and make it unbootable!
- **Backup first:** Always backup important data before performing any flashing, wiping, or bootloader operations.
- **Bug reports:** Bug reports contain sensitive information including account details, location data, and app usage. Handle them carefully.
- **Tombstones:** Accessing `/data/tombstones/` and `/data/anr/` directories requires root access or can be retrieved via `adb bugreport`.
- **Log buffers:** Different Android versions may have different available log buffers. Use `adb logcat -b all` to see all available buffers.

***

This comprehensive reference now includes extensive log extraction methods including bugreport generation, dumpsys diagnostics, tombstone retrieval, ANR traces, and advanced logcat options for thorough debugging and troubleshooting.
<span style="display:none">[^16][^17][^18]</span>

<div align="center">⁂</div>

[^1]: https://www.automatetheplanet.com/adb-cheat-sheet/

[^2]: https://www.youtube.com/watch?v=XwKXYhs1tyc

[^3]: https://meghtechnologies.com/blog/fastboot-mode-commands-with-examples/

[^4]: https://linuxcommandlibrary.com/man/fastboot

[^5]: https://xdaforums.com/t/can-i-change-the-boot-slot-from-fastboot-with-a-command.3977207/

[^6]: https://stuff.mit.edu/afs/sipb/project/android/docs/tools/help/logcat.html

[^7]: https://adbshell.com/commands/adb-logcat

[^8]: https://stackoverflow.com/questions/28643397/android-tombstones-are-not-always-generated-how-to-enforce-its-generation

[^9]: https://developer.arm.com/documentation/108035/latest/MTE-bug-reports/Tombstones

[^10]: https://developer.android.com/tools/dumpsys

[^11]: https://source.android.com/docs/core/tests/debug

[^12]: https://smartbear.com/blog/how-to-make-sense-of-android-crash-logs/

[^13]: https://iverify.io/blog/android-bug-reports-an-underrated-but-complex-goldmine-for-mobile-security-investigations

[^14]: https://manpages.debian.org/testing/fastboot/fastboot.1.en.html

[^15]: https://gist.github.com/MrHallows/a60cced443107c30d78568fe7c081a93

[^16]: Simple-Commands.md

[^17]: https://forensics.socialtic.org/en/explainers/03-explainer-log-forensics-android/index.html

[^18]: https://ccdcoe.org/uploads/2021/03/Android-Dumpsys-Analysis-to-Indicate-Driver-Distraction.pdf

