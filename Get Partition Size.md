<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# Make it into proper bash markdown like last time

Certainly! Here is the previous answer formatted neatly with separate fenced bash code blocks for each command, plus descriptions, matching the style you requested:

# 📏 How to Retrieve BoardConfig Variables Using Commands

> Use these commands on a rooted device or with proper permissions (e.g., `adb root` or `su`), and adjust partition names as needed.

## Partition Sizes

**BOARD_BOOTIMAGE_PARTITION_SIZE**
Get the size of the `boot` partition in bytes:

```bash
blockdev --getsize64 /dev/block/by-name/boot
```

**BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE**
Get the size of the `vendor_boot` partition in bytes:

```bash
blockdev --getsize64 /dev/block/by-name/vendor_boot
```

**BOARD_DTBOIMG_PARTITION_SIZE**
Get the size of the `dtbo` partition in bytes:

```bash
blockdev --getsize64 /dev/block/by-name/dtbo
```

**BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE**
Get the size of the `init_boot` partition in bytes (if it exists):

```bash
blockdev --getsize64 /dev/block/by-name/init_boot
```

**BOARD_SUPER_PARTITION_SIZE**
Get the size of the `super` partition in bytes:

```bash
blockdev --getsize64 /dev/block/by-name/super
```

**BOARD_MEDIATEK_DYNAMIC_PARTITIONS_SIZE**
Usually matches the `super` partition or check all partitions:

```bash
blockdev --getsize64 /dev/block/by-name/super
```

or

```bash
cat /proc/partitions
```

**BOARD_EROFS_PCLUSTER_SIZE**
EROFS cluster size is a filesystem property, not a partition size:

```bash
grep -i erofs /proc/mounts
```

Identify the erofs partition, then:

```bash
dumpe2fs /dev/block/by-name/<erofs-partition-name> | grep -i cluster
```


## Kernel and Boot Image Parameters

These values are found inside the boot image header and **cannot be retrieved by `blockdev`**.

To get these, first pull the boot image from the device:

```bash
adb pull /dev/block/by-name/boot boot.img
```

Then unpack and inspect it using tools on your PC:

```bash
unpackbootimg -i boot.img
```

This will output details like:

- `BOARD_KERNEL_PAGESIZE` (page size)
- `BOARD_KERNEL_BASE` (kernel load address)
- `BOARD_DTB_OFFSET` (offset of the DTB)
- `BOARD_RAMDISK_OFFSET` (ramdisk offset)
- `BOARD_KERNEL_TAGS_OFFSET` (kernel tags offset)


### Useful tips:

- Partition names (`boot`, `vendor_boot`, etc.) may vary slightly depending on the device. Confirm with:

```bash
ls -l /dev/block/by-name/
```

- Use root permission when needed:

```bash
adb root
adb shell
# or
su
```

Let me know if you'd like me to prepare this as a standalone Markdown file, or add more detailed explanations!

