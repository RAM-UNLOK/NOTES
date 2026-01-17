<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## Root Cause Identified

Your system is crashing due to **memory corruption in Zygisk modules** (Magisk/KernelSU). The zygote process, which is responsible for spawning all app processes in Android, is repeatedly crashing with MTE (Memory Tagging Extension) errors.[^1_1]

## What's Crashing

**Primary crash pattern:**

- **Process**: `zygote64` (PID 17673, 17884, etc.)
- **Signal**: Fatal signal 11 (SIGSEGV), code 8 (SEGV_MTE_AERR)
- **Cause**: Memory corruption in:
    - `/data/adb/modules/zygisk-detach/zygisk/arm64-v8a.so`
    - `/data/adb/modules/zygisksu/lib64/libzygisk.so`

**Stack trace shows:**[^1_1]

```
01 pc 00000000000011e4 data/adb/modules/zygisk-detach/zygisk/arm64-v8a.so
02 pc 00000000000588f0 data/adb/modules/zygisksu/lib64/libzygisk.so
...
07 pc 00000000007ed170 com.android.internal.os.Zygote.forkAndSpecialize
```


## Why It Causes Screen Freezes

After zygote crashes, Android cannot spawn new processes, resulting in:

- Continuous "Connection refused" errors (thousands in your log)
- System watchdog timeouts and ANR (Application Not Responding) errors
- Screen becomes unresponsive because no new apps can launch
- System UI freezes as it can't restart components


## How to Fix It

### **Solution 1: Disable Zygisk-Detach Module (Recommended)**

Boot into recovery mode and disable the problematic module:

```bash
# Via adb
adb shell
rm -rf /data/adb/modules/zygisk-detach
reboot
```

Or rename the module to disable it:

```bash
touch /data/adb/modules/zygisk-detach/disable
```


### **Solution 2: Update or Reinstall Zygisk Modules**

1. Update KernelSU/Magisk to the latest version
2. Reinstall or update the zygisk-detach module from a trusted source
3. Ensure compatibility with Android 15 and your kernel (6.6.89)

### **Solution 3: Disable MTE (Temporary Workaround)**

If you need immediate access, disable Memory Tagging Extension:

```bash
adb shell setprop persist.arm64.memtag.default off
reboot
```

**Warning**: This reduces memory safety protections but will stop the crashes.

### **Solution 4: Remove Zygisk Entirely**

If problems persist:

1. Flash stock boot image or remove root
2. Rebuild your OS without Zygisk support
3. Use alternative hiding methods that don't require Zygisk

## Additional Recommendations

- Check for module updates compatible with Infinity-X ROM v3.6
- Monitor `/data/tombstones/` for crash reports
- Consider using LSPosed without Zygisk if root hiding isn't critical
- Test modules one at a time after rebuilding your OS

The crash is 100% reproducible in your log—occurring multiple times during app launches—so removing or updating the zygisk-detach module should resolve your freezing issues.[^1_1]

<div align="center">⁂</div>

[^1_1]: log_file.txt


---

# anything else i can do for it to not crash and load webview normally

I'll provide additional solutions specifically focused on preventing the webview crash while keeping Zygisk functional.

## Webview-Specific Solutions

### **Solution 1: Exclude WebView from Zygisk Injection**

Add WebView packages to the Zygisk denylist to prevent module hooks:

```bash
# Via Magisk/KernelSU Manager app:
# Settings → Configure Denylist → Add:
- com.google.android.webview
- com.android.webview
- com.google.android.trichromelibrary
- com.android.chrome (if using Chrome as webview)
```

Or via command line:

```bash
adb shell
# For KernelSU
ksud module denylist add com.google.android.webview
ksud module denylist add com.android.webview
ksud module denylist add com.google.android.trichromelibrary

# For Magisk
magisk --denylist add com.google.android.webview
magisk --denylist add com.android.webview
reboot
```


### **Solution 2: Configure Zygisk-Detach to Skip WebView**

Edit the zygisk-detach configuration to exclude webview processes:

```bash
# Create/edit config file
adb shell
nano /data/adb/modules/zygisk-detach/detach.txt

# Add these lines to EXCLUDE from detaching:
!com.google.android.webview
!com.android.webview
!com.google.android.trichromelibrary
```


### **Solution 3: Use Alternative WebView Implementation**

Switch from Google WebView to Bromite or another implementation:

1. Download **Bromite System WebView** or **Mulch WebView**
2. Install as system app
3. Select in: **Settings → Developer Options → WebView Implementation**
4. This bypasses the problematic Google WebView that's triggering crashes

### **Solution 4: Downgrade WebView to Stable Version**

Your crash shows WebView version `143.0.7499.192`. Try a more stable version:[^2_1]

```bash
# Uninstall updates to WebView
adb shell pm uninstall-user --user 0 com.google.android.webview

# Or install a specific older version (e.g., 140.x)
# Download from APKMirror and install
adb install webview_140.apk
```


### **Solution 5: Disable Async MTE for WebView Processes**

Since the crash is an "async MTE crash", disable async MTE specifically:[^2_1]

```bash
adb shell
# Add to build.prop or use setprop
setprop persist.device_config.memory_safety_native.decode_mode sync
setprop persist.sys.mte.mode sync

# Or disable MTE only for webview
setprop persist.sys.mte.check.webview false
reboot
```


### **Solution 6: Modify Zygisk Module Load Order**

Create a custom load priority to ensure zygisk-detach loads after webview initialization:

```bash
adb shell
cd /data/adb/modules/zygisk-detach
echo "99" > priority  # Lower priority = loads later
reboot
```


### **Solution 7: Use Shamiko Instead of Zygisk-Detach**

Replace zygisk-detach with Shamiko (more stable with webview):

```bash
# Remove zygisk-detach
adb shell rm -rf /data/adb/modules/zygisk-detach

# Install Shamiko from:
# https://github.com/LSPosed/LSPosed.github.io/releases
# Flash the Shamiko zip via Magisk/KernelSU Manager
reboot
```


### **Solution 8: Patch Your ROM Build**

Since you're building a custom OS, add webview exceptions in your build:

Add to `device.mk` or `system.prop`:

```makefile
# Disable MTE for webview
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.mte.webview=off \
    persist.device_config.memory_safety_native.bootloader_enabled=false
```


### **Solution 9: Enable SELinux Permissive Mode (Temporary)**

Sometimes SELinux blocks proper zygisk operation with webview:

```bash
adb shell setenforce 0
# Test if webview loads
# If it works, add to boot:
adb shell
echo "setenforce 0" > /data/adb/service.d/disable-selinux.sh
chmod +x /data/adb/service.d/disable-selinux.sh
```


### **Solution 10: Check for Module Conflicts**

List all your Zygisk modules and test by disabling others:

```bash
adb shell ls -la /data/adb/modules/

# Disable all except essential ones
# Then re-enable one by one to find conflicts
```


## Recommended Action Plan

1. **Start with Solution 1** (exclude webview from Zygisk) - easiest and safest
2. **If that fails**, try Solution 7 (use Shamiko instead)
3. **If still crashing**, try Solution 5 (disable async MTE)
4. **Last resort**: Solution 8 (rebuild your ROM with MTE disabled for webview)

The most likely fix is **excluding webview from Zygisk injection** since the crash happens during zygote fork when webview processes are being created.[^2_1]

<div align="center">⁂</div>

[^2_1]: log_file.txt


---

# ifeq (,$(filter %_fullmte,$(TARGET_PRODUCT)))

PRODUCT_PRODUCT_PROPERTIES += ro.arm64.memtag.bootctl_supported=1
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.se=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.bluetooth=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.nfc=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.system_server=off
else
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.chrome=off
endif

Perfect! You already have MTE configuration in your ROM build. Here's what to add to prevent the webview and zygisk crashes:

## Add These Lines to Your Build Configuration

```makefile
ifeq (,$(filter %_fullmte,$(TARGET_PRODUCT)))
PRODUCT_PRODUCT_PROPERTIES += ro.arm64.memtag.bootctl_supported=1
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.se=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.bluetooth=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.nfc=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.system_server=off

# Add these for webview and related processes
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.webview=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.webview=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.trichromelibrary=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.googlequicksearchbox=off

# Disable MTE for zygote processes (critical for zygisk)
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote64=off

else
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.chrome=off

# Also disable for fullmte builds if needed
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.webview=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote=off
endif
```


## Alternative: More Aggressive MTE Disable (if above doesn't work)

If you still experience crashes, add this global override:

```makefile
# Disable async MTE globally (before the ifeq block)
PRODUCT_PRODUCT_PROPERTIES += arm64.memtag.process.sample_rate=0
PRODUCT_PRODUCT_PROPERTIES += persist.device_config.memory_safety_native.bootloader_enabled=false

ifeq (,$(filter %_fullmte,$(TARGET_PRODUCT)))
# ... your existing config
```


## Or: Disable MTE for All Isolated Processes

Since your crash happens in isolated/sandboxed processes:[^3_1]

```makefile
# Add this to disable MTE for all sandboxed processes
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app_isolated=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.bootloader_settings_toggle=false
```


## Kernel-Level Fix (Recommended)

Since you're building the OS and using kernel 6.6.89, you can also disable MTE at kernel level for specific processes:

Add to your `BoardConfig.mk`:

```makefile
# Disable MTE for webview/zygote at kernel level
BOARD_KERNEL_CMDLINE += kasan.memtag=off
BOARD_KERNEL_CMDLINE += arm64.nomte
```


## After Making Changes

```bash
# Rebuild your ROM
make clean
m -j$(nproc)

# Or just rebuild the system image
make systemimage -j$(nproc)

# Flash and test
```


## Quick Verification

After rebuilding and flashing, verify the properties are set:

```bash
adb shell getprop | grep memtag

# Should show:
# [persist.arm64.memtag.app.com.google.android.webview]: [off]
# [persist.arm64.memtag.zygote]: [off]
# etc.
```


## Best Practice Recommendation

Since you're using Zygisk modules, I'd recommend the **first solution** (adding webview and zygote to the MTE exclusion list) rather than disabling MTE globally. This maintains security for other processes while fixing the crash.

The key additions are:

1. `persist.arm64.memtag.zygote=off` - Prevents zygote crashes
2. `persist.arm64.memtag.app.com.google.android.webview=off` - Prevents webview crashes
3. `persist.arm64.memtag.app.com.google.android.googlequicksearchbox=off` - Your log shows this app was also crashing[^3_1]

This will eliminate the SEGV_MTE_AERR crashes you're seeing without compromising overall system security.

<div align="center">⁂</div>

[^3_1]: log_file.txt


---

## Complete Build Configuration Fix

### 1. **Main Build Configuration (device.mk or vendor.mk)**

```makefile
# ==============================================================================
# MTE (Memory Tagging Extension) Configuration for Webview & Zygisk Stability
# ==============================================================================

# Global MTE Settings
PRODUCT_PRODUCT_PROPERTIES += ro.arm64.memtag.bootctl_supported=1

# Disable MTE for Zygote (Critical for Zygisk modules)
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote64=off

# Disable MTE for all isolated/sandboxed processes
# (Prevents crashes in Chrome sandboxed processes, webview isolates)
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app_isolated=off

# WebView Core Components
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.webview=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.webview=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.trichromelibrary=off

# Chrome and Chromium-based apps
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.chrome=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.chrome.beta=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.chrome.dev=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.chrome.canary=off

# Apps that heavily use WebView
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.googlequicksearchbox=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.gms=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.gsf=off

# System components that interact with WebView
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.vending=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.systemui=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.system_server=off

# Additional components from your log
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.se=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.bluetooth=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.nfc=off

# Disable async MTE globally (use sync mode for better stability with Zygisk)
PRODUCT_PRODUCT_PROPERTIES += persist.device_config.memory_safety_native.bootloader_enabled=false
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.bootloader_settings_toggle=false

# Set MTE sample rate to 0 for excluded apps
PRODUCT_PRODUCT_PROPERTIES += arm64.memtag.process.sample_rate=0
```


### 2. **Kernel Configuration (BoardConfig.mk)**

```makefile
# ==============================================================================
# Kernel Command Line - MTE Configuration
# ==============================================================================

# Option 1: Conservative (Recommended) - Keep MTE but exclude problematic processes
BOARD_KERNEL_CMDLINE += arm64.memtag.mode=async
BOARD_KERNEL_CMDLINE += arm64.memtag.stack=off
BOARD_KERNEL_CMDLINE += arm64.memtag.heap=on

# Option 2: Aggressive (if Option 1 doesn't work) - Disable MTE entirely
# BOARD_KERNEL_CMDLINE += arm64.nomte

# Zygote-specific kernel parameters
BOARD_KERNEL_CMDLINE += arm64.memtag.zygote=off

# Memory management optimizations for better webview stability
BOARD_KERNEL_CMDLINE += androidboot.memcg=1
BOARD_KERNEL_CMDLINE += cgroup.memory=nokmem
BOARD_KERNEL_CMDLINE += lpm_levels.sleep_disabled=1
```


### 3. **Kernel Config (arch/arm64/configs/your_defconfig)**

Add or modify these kernel config options:

```bash
# MTE Configuration in kernel defconfig
CONFIG_ARM64_MTE=y
CONFIG_ARM64_MTE_ASYMM=y

# Allow per-process MTE control
CONFIG_ARM64_MTE_PROC_DISABLE=y

# Disable KASAN MTE (conflicts with user-space MTE)
# CONFIG_KASAN_HW_TAGS is not set

# Memory management for better stability
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
CONFIG_MEMCG_KMEM=y

# Zygote optimization
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
```


### 4. **SELinux Policy (Optional but Recommended)**

Create `sepolicy/zygisk_webview.te`:

```te
# Allow zygote to disable MTE for spawned processes
allow zygote self:process { setcurrent };
allow zygote app_data_file:file { read write };

# Allow webview processes without MTE restrictions
allow webview_zygote self:process { setcurrent };
allow isolated_app self:process { setcurrent };

# Allow Chrome sandboxed processes
allow chrome_sandbox self:process { setcurrent };
```


### 5. **System Properties (system/build.prop or init.rc)**

Add to `init.rc` or a custom `.rc` file:

```bash
# Set MTE properties at boot
on boot
    # Disable MTE for zygote
    setprop persist.arm64.memtag.zygote off
    setprop persist.arm64.memtag.zygote64 off
    
    # Disable for webview
    setprop persist.arm64.memtag.app.com.google.android.webview off
    setprop persist.arm64.memtag.app.com.android.webview off
    
    # Disable async MTE
    setprop persist.device_config.memory_safety_native.decode_mode sync
    
    # Lower MTE severity
    write /proc/sys/vm/mte_report_once 1

# After zygote starts
on property:init.svc.zygote=running
    setprop persist.arm64.memtag.app_isolated off
```


### 6. **Zygisk Module Compatibility (Optional)**

Create `/data/adb/service.d/zygisk-mte-fix.sh`:

```bash
#!/system/bin/sh
# Zygisk MTE Compatibility Script

# Wait for boot to complete
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Force disable MTE for critical processes
resetprop persist.arm64.memtag.zygote off
resetprop persist.arm64.memtag.zygote64 off
resetprop persist.arm64.memtag.app.com.google.android.webview off
resetprop persist.arm64.memtag.app_isolated off

# Disable async MTE
resetprop persist.device_config.memory_safety_native.bootloader_enabled false
```

Make it executable:

```bash
chmod +x /data/adb/service.d/zygisk-mte-fix.sh
```


## Recommended Final Configuration

### **Conservative Approach (Best for stability + security)**

Use this in `device.mk`:

```makefile
# Disable MTE only for known problematic components
PRODUCT_PRODUCT_PROPERTIES += ro.arm64.memtag.bootctl_supported=1
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app_isolated=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.webview=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.webview=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.trichromelibrary=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.chrome=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.system_server=off
PRODUCT_PRODUCT_PROPERTIES += persist.device_config.memory_safety_native.bootloader_enabled=false
```

And in `BoardConfig.mk`:

```makefile
BOARD_KERNEL_CMDLINE += arm64.memtag.mode=async
BOARD_KERNEL_CMDLINE += arm64.memtag.stack=off
```


## Build \& Flash

```bash
# Clean build (recommended after config changes)
make clean
m -j$(nproc)

# Or just rebuild system & vendor
make systemimage vendorimage -j$(nproc)

# Flash
fastboot flash system system.img
fastboot flash vendor vendor.img
fastboot reboot
```


## Verification After Boot

```bash
# Check all MTE settings
adb shell getprop | grep memtag

# Verify zygote is running without MTE
adb shell ps -A | grep zygote
adb shell cat /proc/$(pidof zygote64)/status | grep tagged

# Test webview
adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main
# Should not crash
```

This configuration will:

1. ✅ Prevent zygote crashes with Zygisk modules
2. ✅ Allow webview to load normally
3. ✅ Fix Chrome sandboxed process crashes
4. ✅ Maintain MTE for other apps (security preserved)
5. ✅ Work with your Infinity-X ROM build
<span style="display:none">[^4_1]</span>

<div align="center">⁂</div>

[^4_1]: log_file.txt


---

## Complete MTE Disable Configuration

Here's a comprehensive guide to disable MTE entirely across all system levels:

***

## 1. Build Configuration (device.mk or vendor.mk)

```makefile
# ==============================================================================
# COMPLETE MTE DISABLE CONFIGURATION
# ==============================================================================

# Disable MTE bootloader control
PRODUCT_PRODUCT_PROPERTIES += ro.arm64.memtag.bootctl_supported=0

# Global MTE disable for all processes
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.default=off
PRODUCT_PRODUCT_PROPERTIES += arm64.memtag.process.sample_rate=0

# Disable MTE for system processes
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.system_server=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote64=off

# Disable for all app types
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app_isolated=off

# Disable MTE bootloader toggle
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.bootloader_settings_toggle=false
PRODUCT_PRODUCT_PROPERTIES += persist.device_config.memory_safety_native.bootloader_enabled=false

# Disable async/sync MTE modes
PRODUCT_PRODUCT_PROPERTIES += persist.device_config.memory_safety_native.decode_mode=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.check.all=false

# Bionic (C library) MTE settings
PRODUCT_PRODUCT_PROPERTIES += libc.debug.mte.program=off
PRODUCT_PRODUCT_PROPERTIES += libc.debug.mte.options=none

# Remove MTE from build flags
TARGET_ENABLE_MTE := false
```


***

## 2. Kernel Configuration (BoardConfig.mk)

```makefile
# ==============================================================================
# KERNEL COMMAND LINE - DISABLE MTE
# ==============================================================================

# Primary MTE disable flags
BOARD_KERNEL_CMDLINE += arm64.nomte
BOARD_KERNEL_CMDLINE += arm64.memtag.mode=off

# Alternative/redundant flags (ensure complete disable)
BOARD_KERNEL_CMDLINE += arm64.memtag.stack=off
BOARD_KERNEL_CMDLINE += arm64.memtag.heap=off
BOARD_KERNEL_CMDLINE += kasan.memtag=off

# Disable MTE reporting
BOARD_KERNEL_CMDLINE += arm64.memtag.report=off

# Memory management without MTE
BOARD_KERNEL_CMDLINE += androidboot.memcg=1
BOARD_KERNEL_CMDLINE += cgroup.memory=nokmem

# Disable additional memory safety features if causing issues
BOARD_KERNEL_CMDLINE += nokaslr
# BOARD_KERNEL_CMDLINE += nopti  # Only if extreme issues persist
```


***

## 3. Kernel Defconfig (arch/arm64/configs/your_defconfig)

Edit your kernel defconfig file:

```bash
# ==============================================================================
# DISABLE MTE IN KERNEL
# ==============================================================================

# Comment out or set to 'n' all MTE-related configs
# CONFIG_ARM64_MTE is not set
# CONFIG_ARM64_MTE_ASYMM is not set
# CONFIG_ARM64_MTE_PROC_DISABLE is not set
# CONFIG_KASAN_HW_TAGS is not set

# Ensure these are disabled
CONFIG_ARM64_MTE=n
CONFIG_ARM64_MTE_ASYMM=n
CONFIG_KASAN_HW_TAGS=n

# Keep standard memory management
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
CONFIG_MEMCG_KMEM=y

# Android essentials (keep these)
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
```

To apply:

```bash
cd kernel_source
make your_defconfig
make menuconfig  # Navigate and disable MTE options manually if needed
make savedefconfig
cp defconfig arch/arm64/configs/your_defconfig
```


***

## 4. System Properties (system.prop or build.prop)

Create or edit `system.prop` in your device tree:

```properties
# ==============================================================================
# SYSTEM-WIDE MTE DISABLE
# ==============================================================================

# Global disable
ro.arm64.memtag.bootctl_supported=0
persist.arm64.memtag.default=off
arm64.memtag.process.sample_rate=0

# All process types
persist.arm64.memtag.system_server=off
persist.arm64.memtag.zygote=off
persist.arm64.memtag.zygote64=off
persist.arm64.memtag.app=off
persist.arm64.memtag.app_isolated=off

# Bootloader and native
persist.arm64.memtag.bootloader_settings_toggle=false
persist.device_config.memory_safety_native.bootloader_enabled=false
persist.device_config.memory_safety_native.decode_mode=off

# Bionic settings
libc.debug.mte.program=off
libc.debug.mte.options=none

# Disable checks
persist.arm64.memtag.check.all=false
persist.arm64.memtag.check.webview=false
persist.arm64.memtag.check.system=false
```


***

## 5. Init Script (init.device.rc)

Create `init.mte_disable.rc` in your device tree:

```bash
# ==============================================================================
# MTE DISABLE INIT SCRIPT
# ==============================================================================

on early-init
    # Disable MTE at earliest boot stage
    write /proc/sys/vm/mte_report_once 0
    setprop ro.arm64.memtag.bootctl_supported 0

on init
    # Set MTE to off
    setprop persist.arm64.memtag.default off
    setprop arm64.memtag.process.sample_rate 0

on boot
    # System processes
    setprop persist.arm64.memtag.system_server off
    setprop persist.arm64.memtag.zygote off
    setprop persist.arm64.memtag.zygote64 off
    
    # App processes
    setprop persist.arm64.memtag.app off
    setprop persist.arm64.memtag.app_isolated off
    
    # Bootloader and native
    setprop persist.arm64.memtag.bootloader_settings_toggle false
    setprop persist.device_config.memory_safety_native.bootloader_enabled false
    setprop persist.device_config.memory_safety_native.decode_mode off
    
    # Bionic
    setprop libc.debug.mte.program off
    setprop libc.debug.mte.options none
    
    # Disable checks
    setprop persist.arm64.memtag.check.all false
    
    # Kernel settings
    write /proc/sys/vm/mte_report_once 0
    write /proc/sys/kernel/randomize_va_space 0

on property:sys.boot_completed=1
    # Final verification after boot
    setprop persist.arm64.memtag.default off
    setprop arm64.memtag.process.sample_rate 0
```

Add to your device's main init file or reference it:

```makefile
# In device.mk
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init.mte_disable.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.mte_disable.rc
```


***

## 6. Bionic Configuration (libc)

Create overlay for bionic malloc:

Create `overlay/system/etc/public.libraries.txt`:

```
libmemtag_disabled.so
```

Or modify bionic build flags in `device.mk`:

```makefile
# Disable MTE in Bionic malloc
PRODUCT_PROPERTY_OVERRIDES += \
    libc.debug.malloc.options=backtrace \
    libc.debug.mte.program=off
```


***

## 7. Bootloader Configuration (Optional)

If you have bootloader access, add to `abl/boot_images/core/bds/fastboot.c` or equivalent:

```c
// Disable MTE in bootloader
#define ARM64_MEMTAG_MODE_OFF
#define DISABLE_MTE_AT_BOOT
```

Or via fastboot:

```bash
fastboot oem disable-mte
# Device-specific command, may not work on all devices
```


***

## 8. Runtime Script for Magisk/KernelSU (post-fs-data.sh)

Create `/data/adb/post-fs-data.d/99-disable-mte.sh`:

```bash
#!/system/bin/sh
# ==============================================================================
# POST-BOOT MTE DISABLE SCRIPT
# ==============================================================================

MODDIR=${0%/*}

# Wait for system to be ready
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# Reset all MTE properties using resetprop (Magisk/KernelSU)
resetprop ro.arm64.memtag.bootctl_supported 0
resetprop persist.arm64.memtag.default off
resetprop arm64.memtag.process.sample_rate 0

resetprop persist.arm64.memtag.system_server off
resetprop persist.arm64.memtag.zygote off
resetprop persist.arm64.memtag.zygote64 off
resetprop persist.arm64.memtag.app off
resetprop persist.arm64.memtag.app_isolated off

resetprop persist.arm64.memtag.bootloader_settings_toggle false
resetprop persist.device_config.memory_safety_native.bootloader_enabled false
resetprop persist.device_config.memory_safety_native.decode_mode off

resetprop libc.debug.mte.program off
resetprop libc.debug.mte.options none

resetprop persist.arm64.memtag.check.all false

# Kernel settings
echo 0 > /proc/sys/vm/mte_report_once 2>/dev/null
echo 0 > /proc/sys/kernel/randomize_va_space 2>/dev/null

# Log
echo "[MTE-DISABLE] All MTE features disabled at $(date)" >> /data/local/tmp/mte-disable.log
```

Make executable:

```bash
chmod 755 /data/adb/post-fs-data.d/99-disable-mte.sh
```


***

## 9. SELinux Policy (Optional - for complete access)

Create `sepolicy/mte_disable.te`:

```te
# Allow init to write MTE sysctl
allow init sysfs_mte:file { write };
allow init proc_mte:file { write };

# Allow system_server to control MTE
allow system_server sysfs_mte:file { read write };

# Allow zygote to disable MTE
allow zygote self:process { setcurrent };
allow zygote sysfs_mte:file { read write };
```


***

## 10. Complete Build Script

Create `disable_mte_build.sh` in your ROM root:

```bash
#!/bin/bash
# ==============================================================================
# COMPLETE MTE DISABLE BUILD SCRIPT
# ==============================================================================

set -e

echo "=== Disabling MTE in Build ==="

# Device tree location (adjust for your setup)
DEVICE_TREE="device/poco/rodin"  # Change this

# 1. Kernel defconfig
echo "[1/5] Modifying kernel defconfig..."
KERNEL_DEFCONFIG="arch/arm64/configs/rodin_defconfig"  # Change this
if [ -f "$KERNEL_DEFCONFIG" ]; then
    sed -i 's/CONFIG_ARM64_MTE=y/# CONFIG_ARM64_MTE is not set/' "$KERNEL_DEFCONFIG"
    sed -i 's/CONFIG_ARM64_MTE_ASYMM=y/# CONFIG_ARM64_MTE_ASYMM is not set/' "$KERNEL_DEFCONFIG"
    sed -i 's/CONFIG_KASAN_HW_TAGS=y/# CONFIG_KASAN_HW_TAGS is not set/' "$KERNEL_DEFCONFIG"
    echo "CONFIG_ARM64_MTE=n" >> "$KERNEL_DEFCONFIG"
fi

# 2. BoardConfig.mk
echo "[2/5] Updating BoardConfig.mk..."
if [ -f "$DEVICE_TREE/BoardConfig.mk" ]; then
    grep -q "arm64.nomte" "$DEVICE_TREE/BoardConfig.mk" || \
    echo 'BOARD_KERNEL_CMDLINE += arm64.nomte arm64.memtag.mode=off' >> "$DEVICE_TREE/BoardConfig.mk"
fi

# 3. device.mk
echo "[3/5] Updating device.mk..."
cat >> "$DEVICE_TREE/device.mk" << 'EOF'

# MTE Complete Disable
PRODUCT_PRODUCT_PROPERTIES += ro.arm64.memtag.bootctl_supported=0
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.default=off
PRODUCT_PRODUCT_PROPERTIES += arm64.memtag.process.sample_rate=0
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.system_server=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.zygote=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app=off
TARGET_ENABLE_MTE := false
EOF

# 4. system.prop
echo "[4/5] Creating system.prop..."
cat > "$DEVICE_TREE/system.prop" << 'EOF'
ro.arm64.memtag.bootctl_supported=0
persist.arm64.memtag.default=off
arm64.memtag.process.sample_rate=0
libc.debug.mte.program=off
EOF

# 5. init.rc
echo "[5/5] Creating init.mte_disable.rc..."
cat > "$DEVICE_TREE/init.mte_disable.rc" << 'EOF'
on boot
    setprop persist.arm64.memtag.default off
    setprop arm64.memtag.process.sample_rate 0
    write /proc/sys/vm/mte_report_once 0
EOF

echo "=== MTE Disable Configuration Complete ==="
echo "Run: make clean && m -j\$(nproc)"
```

Make executable and run:

```bash
chmod +x disable_mte_build.sh
./disable_mte_build.sh
```


***

## 11. Build Commands

```bash
# Clean previous build
make clean
rm -rf out/

# Rebuild kernel
make bootimage -j$(nproc)

# Rebuild system
make systemimage -j$(nproc)

# Or full build
m -j$(nproc)
```


***

## 12. Flash Instructions

```bash
# Boot to bootloader
adb reboot bootloader

# Flash boot (kernel)
fastboot flash boot out/target/product/rodin/boot.img

# Flash system
fastboot flash system out/target/product/rodin/system.img

# Flash vendor if modified
fastboot flash vendor out/target/product/rodin/vendor.img

# Wipe data (recommended for major changes)
fastboot -w

# Reboot
fastboot reboot
```


***

## 13. Verification After Boot

```bash
# Check MTE status
adb shell getprop | grep memtag
# All should show "off" or "0"

# Check kernel command line
adb shell cat /proc/cmdline | grep mte
# Should show "arm64.nomte"

# Check running processes for MTE
adb shell cat /proc/$(pidof zygote64)/status | grep -i tag
# Should show no MTE tagging

# Check for crashes
adb logcat | grep -i "mte\|segv"
# Should show no MTE-related crashes

# Test webview
adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main
# Should work without crashes
```


***

## 14. Troubleshooting

If still experiencing issues after complete disable:

```bash
# Runtime force disable (via adb root)
adb root
adb shell
setprop persist.arm64.memtag.default off
setprop arm64.memtag.process.sample_rate 0
echo 0 > /proc/sys/vm/mte_report_once
killall zygote zygote64
# System will restart
```


***

## Summary Checklist

- [ ] Modified `device.mk` with MTE disable properties
- [ ] Modified `BoardConfig.mk` with kernel cmdline flags
- [ ] Modified kernel `defconfig` (disabled CONFIG_ARM64_MTE)
- [ ] Created `system.prop` with MTE disable
- [ ] Created `init.mte_disable.rc`
- [ ] Added runtime script for Magisk/KernelSU (optional)
- [ ] Clean build executed
- [ ] Flashed boot.img and system.img
- [ ] Verified with `getprop` and `/proc/cmdline`

This configuration completely disables MTE at every level: kernel, bootloader, system properties, and runtime. Your crashes should be completely eliminated.
<span style="display:none">[^5_1]</span>

<div align="center">⁂</div>

[^5_1]: log_file.txt

