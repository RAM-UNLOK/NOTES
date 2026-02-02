<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Add more related command to this and make it compatible for newer android versions like 16

Here's your enhanced partition size guide with additional commands and Android 16 compatibility:

***

<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# 📏 Complete Android Partition Management Guide

> **Compatibility:** Android 10 - Android 16 (including dynamic partitions, A/B slots, and latest boot image formats)

***

## 🔐 Prerequisites \& Permissions

**Enable root access:**

```bash
adb root
adb shell
```

**Or on device with Magisk/KernelSU:**

```bash
adb shell
su
```

**Check available partitions:**

```bash
ls -l /dev/block/by-name/
```


***

## 📦 Basic Partition Sizes

### BOARD_BOOTIMAGE_PARTITION_SIZE

Get the size of the `boot` partition in bytes:

```bash
blockdev --getsize64 /dev/block/by-name/boot
```


### BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE

Get the size of the `vendor_boot` partition in bytes:

```bash
blockdev --getsize64 /dev/block/by-name/vendor_boot
```


### BOARD_DTBOIMG_PARTITION_SIZE

Get the size of the `dtbo` partition in bytes:

```bash
blockdev --getsize64 /dev/block/by-name/dtbo
```


### BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE

Get the size of the `init_boot` partition in bytes (Android 13+):

```bash
blockdev --getsize64 /dev/block/by-name/init_boot
```


### BOARD_SUPER_PARTITION_SIZE

Get the size of the `super` partition in bytes:

```bash
blockdev --getsize64 /dev/block/by-name/super
```


***

## 🔄 A/B Slot Partitions

**Check both slots for A/B devices:**

```bash
# Slot A
blockdev --getsize64 /dev/block/by-name/boot_a
blockdev --getsize64 /dev/block/by-name/vendor_boot_a
blockdev --getsize64 /dev/block/by-name/dtbo_a

# Slot B
blockdev --getsize64 /dev/block/by-name/boot_b
blockdev --getsize64 /dev/block/by-name/vendor_boot_b
blockdev --getsize64 /dev/block/by-name/dtbo_b
```

**Get current active slot:**

```bash
# Method 1: Via bootctl
bootctl get-current-slot

# Method 2: Via system property
getprop ro.boot.slot_suffix
```

**List all slot suffixes:**

```bash
getprop ro.boot.slot_suffix
# Output: _a or _b
```


***

## 🗂️ Dynamic Partitions (Super Partition)

### BOARD_MEDIATEK_DYNAMIC_PARTITIONS_SIZE

Usually matches the `super` partition:

```bash
blockdev --getsize64 /dev/block/by-name/super
```


### Complete Dynamic Partition Information

**List all partitions (basic):**

```bash
cat /proc/partitions
```

**Detailed partition table with sizes:**

```bash
# Human-readable format
lsblk

# Show all block devices with sizes
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Include partition numbers
lsblk -a
```

**Dynamic partition metadata dump (Android 10+):**

```bash
# Dump metadata for slot 0
lpdump /dev/block/by-name/super

# Dump metadata for slot 1 (A/B devices)
lpdump --slot 1 /dev/block/by-name/super

# Detailed output with group info
lpdump -v /dev/block/by-name/super
```

**Alternative lpdump path:**

```bash
lpdump /dev/block/bootdevice/by-name/super
```

**Get super partition block devices:**

```bash
# List all super partition components
ls -l /dev/block/mapper/

# Show device mapper table
dmsetup table

# Show detailed device mapper info
dmsetup info
```

**Dump logical partition configuration:**

```bash
# Root required
su -c lpdump

# Alternative for newer Android versions
lpdump --json /dev/block/by-name/super > super_metadata.json
```


***

## 📊 Advanced Partition Information

### Get Partition Details with sgdisk

**List all GPT partitions:**

```bash
sgdisk --print /dev/block/sda
# Or for specific block device
sgdisk --print /dev/block/mmcblk0
```

**Get partition UUID:**

```bash
sgdisk --info=1 /dev/block/sda
# Replace 1 with partition number
```

**Get all partition GUIDs:**

```bash
sgdisk --print /dev/block/sda | grep -i guid
```


### Get Partition Info with gdisk

**Interactive partition viewer:**

```bash
gdisk -l /dev/block/sda
```


### Get Partition Usage and Filesystem Type

**Check mounted filesystems:**

```bash
df -h

# Include filesystem type
df -Th

# Show all partitions including unmounted
df -ah
```

**List mounted partitions with details:**

```bash
mount | grep -E "ext4|f2fs|erofs"
```

**Get filesystem type for specific partition:**

```bash
blkid /dev/block/by-name/system

# More detailed
blkid -o full /dev/block/by-name/system
```

**Check EROFS partitions (Android 12+):**

```bash
# List all EROFS mounts
mount | grep erofs

# Get EROFS mount points
grep -i erofs /proc/mounts
```


***

## 🧬 EROFS Filesystem Information

### BOARD_EROFS_PCLUSTER_SIZE

EROFS cluster size is a filesystem property, not a partition size:

**Find EROFS partitions:**

```bash
grep -i erofs /proc/mounts
```

**Get EROFS filesystem details:**

```bash
# For system partition (example)
dump.erofs /dev/block/mapper/system

# Show superblock info
dump.erofs -S /dev/block/mapper/system

# Show compression algorithm
dump.erofs /dev/block/mapper/system | grep -i "compress"
```

**Alternative method for EROFS cluster size:**

```bash
# Get from mount options
cat /proc/mounts | grep erofs | grep -o "cluster_size=[0-9]*"
```


***

## 🥾 Boot Image Parameters

### Extract Boot Image

**Pull boot image from device:**

```bash
# Standard boot
adb pull /dev/block/by-name/boot boot.img

# Vendor boot
adb pull /dev/block/by-name/vendor_boot vendor_boot.img

# Init boot (Android 13+)
adb pull /dev/block/by-name/init_boot init_boot.img

# For A/B devices (current slot)
adb pull /dev/block/by-name/boot_a boot.img
```

**Check boot image header version:**

```bash
# On device
file /dev/block/by-name/boot

# After pulling to PC
file boot.img
hexdump -C boot.img | head -20
```


### Unpack Boot Image (Multiple Methods)

**Method 1: Using unpackbootimg (AOSP tool):**

```bash
unpackbootimg -i boot.img
```

**Method 2: Using magiskboot:**

```bash
# Extract everything
magiskboot unpack boot.img

# List contents
ls -la

# Will extract:
# - kernel
# - ramdisk.cpio
# - second
# - dtb
# - header (v3+)
```

**Method 3: Using Android Boot Image Editor (supports Android 15/16):**

```bash
# Clone the tool
git clone https://github.com/cfig/Android_boot_image_editor

# Put boot.img in directory
cp boot.img Android_boot_image_editor/

# Unpack
cd Android_boot_image_editor
./gradlew unpack

# Check unpacked contents
ls -la build/unzip_boot/
```

**Method 4: Using AIK (Android Image Kitchen):**

```bash
# Extract boot image
./unpackimg.sh boot.img

# Contents will be in split_img/ and ramdisk/
```


### Boot Image Information Retrieval

**Get boot image header info:**

```bash
# Using magiskboot
magiskboot unpack boot.img
cat header

# Output includes:
# - BOARD_KERNEL_PAGESIZE
# - BOARD_KERNEL_BASE
# - BOARD_RAMDISK_OFFSET
# - BOARD_TAGS_OFFSET
# - BOARD_DTB_OFFSET
# - BOARD_KERNEL_CMDLINE
```

**Parse boot image header manually:**

```bash
# Check boot image version
od -A x -t x1z -v boot.img | head -5

# Extract kernel cmdline
strings boot.img | grep "androidboot"
```

**Get kernel version from boot image:**

```bash
# Extract kernel
magiskboot unpack boot.img

# Check kernel version
file kernel
strings kernel | grep "Linux version"
```

**Get DTB information:**

```bash
# Extract DTB
magiskboot unpack boot.img

# Check DTB
file dtb

# Decompile DTB to DTS (if available)
dtc -I dtb -O dts dtb -o dtb.dts
```


***

## 🔢 Get All Partition Sizes at Once

**List all partition sizes:**

```bash
for partition in /dev/block/by-name/*; do
    echo "$partition: $(blockdev --getsize64 $partition) bytes"
done
```

**Convert to human-readable format:**

```bash
for partition in /dev/block/by-name/*; do
    size=$(blockdev --getsize64 $partition)
    mb=$((size / 1024 / 1024))
    echo "$partition: ${mb}MB ($size bytes)"
done
```

**Export all sizes to file:**

```bash
for partition in /dev/block/by-name/*; do
    echo "$partition: $(blockdev --getsize64 $partition)"
done > /sdcard/partition_sizes.txt
```

**Generate BoardConfig.mk format:**

```bash
for partition in /dev/block/by-name/*; do
    name=$(basename $partition | tr '[:lower:]' '[:upper:]')
    size=$(blockdev --getsize64 $partition)
    echo "BOARD_${name}IMAGE_PARTITION_SIZE := $size"
done > /sdcard/boardconfig_sizes.txt
```


***

## 🎯 Android 16 Specific Commands

### Virtual A/B Partitions (Android 11+, enhanced in 16)

**Check if device uses Virtual A/B:**

```bash
getprop ro.virtual_ab.enabled

# Check compression
getprop ro.virtual_ab.compression.enabled
```

**Get snapshot status:**

```bash
# Show current snapshot state
snapshotctl dump

# List merge status
snapshotctl status
```

**Inspect COW (Copy-on-Write) images:**

```bash
# List COW images
ls -l /data/gsi/ota/

# Show COW operation details
dmctl list
```


### Generic System Image (GSI) Partitions

**Check if GSI is installed:**

```bash
getprop ro.system.is_gsi

# Get GSI version
getprop ro.gsid.image_running
```

**List DSU (Dynamic System Updates) partitions:**

```bash
# Show DSU images
ls -la /data/gsi/dsu/

# Get DSU status
getprop gsid.state
```


### Vendor DLKM Partitions (Android 13+, optimized in 16)

**List DLKM (Dynamic Loadable Kernel Modules) partitions:**

```bash
# Check vendor_dlkm
blockdev --getsize64 /dev/block/by-name/vendor_dlkm

# Check odm_dlkm (if exists)
blockdev --getsize64 /dev/block/by-name/odm_dlkm

# Check system_dlkm
blockdev --getsize64 /dev/block/by-name/system_dlkm
```

**Get DLKM mount info:**

```bash
mount | grep dlkm
```


***

## 🔍 Partition Verification \& Health

**Check partition integrity:**

```bash
# Check for bad blocks
badblocks -v /dev/block/by-name/userdata

# Filesystem check (requires unmounting)
e2fsck -n /dev/block/mapper/system
```

**Get SMART data (if supported):**

```bash
smartctl -a /dev/block/sda
```

**Check flash wear leveling:**

```bash
cat /sys/block/mmcblk0/device/life_time
cat /sys/block/mmcblk0/device/pre_eol_info
```

**Get partition alignment:**

```bash
# Check if partition is aligned
blockdev --getalignoff /dev/block/by-name/boot

# Get optimal IO size
blockdev --getioopt /dev/block/by-name/boot
```


***

## 🛠️ Repack Boot Images (Android 16 Compatible)

**Repack with magiskboot:**

```bash
# After modifications
magiskboot repack boot.img new_boot.img

# Sign for AVB
magiskboot sign new_boot.img
```

**Repack with Android Boot Image Editor:**

```bash
# After editing files in build/unzip_boot/
./gradlew pack

# Output: boot.img.signed
```

**Flash repacked image:**

```bash
# To current slot
fastboot flash boot new_boot.img

# To specific slot
fastboot flash boot_a new_boot.img
fastboot flash boot_b new_boot.img

# For vendor_boot
fastboot flash vendor_boot new_vendor_boot.img
```


***

## 📝 Quick Reference Script

**Save this as `partition_info.sh`:**

```bash
#!/system/bin/sh

echo "=== Android Partition Information ==="
echo ""
echo "Device: $(getprop ro.product.model)"
echo "Android Version: $(getprop ro.build.version.release)"
echo "API Level: $(getprop ro.build.version.sdk)"
echo ""

echo "=== Active Slot ==="
bootctl get-current-slot
echo ""

echo "=== Super Partition ==="
blockdev --getsize64 /dev/block/by-name/super | awk '{printf "Size: %.2f GB (%d bytes)\n", $1/1024/1024/1024, $1}'
echo ""

echo "=== Boot Images ==="
for img in boot vendor_boot init_boot dtbo; do
    if [ -e /dev/block/by-name/$img ]; then
        size=$(blockdev --getsize64 /dev/block/by-name/$img)
        mb=$((size / 1024 / 1024))
        echo "$img: ${mb}MB"
    fi
done
echo ""

echo "=== Dynamic Partitions ==="
lpdump /dev/block/by-name/super 2>/dev/null | grep -E "Name:|Size:" | head -20
echo ""

echo "=== EROFS Partitions ==="
mount | grep erofs
```

**Use it:**

```bash
adb push partition_info.sh /data/local/tmp/
adb shell chmod +x /data/local/tmp/partition_info.sh
adb shell su -c /data/local/tmp/partition_info.sh
```


***

## 📚 Additional Resources

**Tools for boot image manipulation:**

- [Android Boot Image Editor](https://github.com/cfig/Android_boot_image_editor) - Supports Android 15/16[^1]
- [Magiskboot](https://github.com/topjohnwu/Magisk) - Universal boot image tool
- [Android Image Kitchen](https://github.com/osm0sis/Android-Image-Kitchen) - Traditional unpacker
- [ravindu644/Kitchen](https://github.com/ravindu644/Kitchen) - Simple boot image tool[^2]

**Official documentation:**

- [Dynamic Partitions](https://source.android.com/docs/core/ota/dynamic_partitions)[^3]
- [Implement Dynamic Partitions](https://source.android.com/docs/core/ota/dynamic_partitions/implement)[^4]
- [Partition Tools](https://android.googlesource.com/platform/system/extras/+/master/partition_tools/)[^5]

***

## ⚠️ Important Notes

- Always backup before modifying partitions
- Use correct partition names for your device
- Slot suffixes (_a, _b) vary by device and Android version
- Some commands require root (su) or adb root
- Dynamic partitions (super) require lpdump for detailed info
- Android 16 uses boot image header v4/v5 - ensure tools are updated
- Virtual A/B devices have additional COW partition management
- EROFS is read-only; modifications require rebuilding system image

***

This guide is compatible with Android 10 through Android 16, including all modern partition schemes and boot image formats.
<span style="display:none">[^10][^11][^12][^13][^14][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://github.com/cfig/Android_boot_image_editor

[^2]: https://github.com/ravindu644/Kitchen

[^3]: https://source.android.com/docs/core/ota/dynamic_partitions

[^4]: https://source.android.com/docs/core/ota/dynamic_partitions/implement

[^5]: https://android.googlesource.com/platform/system/extras/+/master/partition_tools/

[^6]: Get-Partition-Size.md

[^7]: Simple-Commands.md

[^8]: Complete-MTE-Build-Configuration-Fix.md

[^9]: MTE-Root-Cause-Identified.md

[^10]: https://xdaforums.com/t/guide-how-to-create-a-new-dynamic-partition-in-the-partition-super.4691372/

[^11]: https://wiki.postmarketos.org/wiki/Android_dynamic_partitions

[^12]: https://www.youtube.com/watch?v=XEjDKGzd-3o

[^13]: https://source.android.com/docs/core/ota/dynamic_partitions/ab_launch

[^14]: https://www.youtube.com/watch?v=SmRwyHSgqKk

