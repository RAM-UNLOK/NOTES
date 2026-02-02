<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# remake taking contents from these too make a new single markdown dont create merged markdown file with all sections including ADB/Fastboot commands, logging, APKTool, Java decompilation, error troubleshooting,

Here's your complete standalone MTE configuration markdown based on the attached files:

***

<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# 🛡️ Complete MTE Configuration Guide for Android

**Comprehensive guide for configuring ARM Memory Tagging Extension (MTE) in Android builds to fix crashes with Zygisk modules and WebView.**

***

## 📋 Table of Contents

1. [Root Cause Analysis](#root-cause-analysis)
2. [Build Configuration Fix](#build-configuration-fix)
3. [Complete MTE Disable Configuration](#complete-mte-disable-configuration)
4. [WebView-Specific Solutions](#webview-specific-solutions)
5. [Verification \& Testing](#verification-testing)

***

## 🔍 Root Cause Analysis

### What's Happening

Your system crashes due to **memory corruption in Zygisk modules** (Magisk/KernelSU) triggered by MTE (Memory Tagging Extension). The zygote process, responsible for spawning all Android app processes, repeatedly crashes with MTE errors.

**Primary crash pattern:**

- **Process**: `zygote64` (PID varies)
- **Signal**: Fatal signal 11 (SIGSEGV), code 8 (SEGV_MTE_AERR)
- **Cause**: Memory corruption in:
    - `/data/adb/modules/zygisk-detach/zygisk/arm64-v8a.so`
    - `/data/adb/modules/zygisksu/lib64/libzygisk.so`

**Stack trace pattern:**

```
01 pc 00000000000011e4 data/adb/modules/zygisk-detach/zygisk/arm64-v8a.so
02 pc 00000000000588f0 data/adb/modules/zygisksu/lib64/libzygisk.so
...
07 pc 00000000007ed170 com.android.internal.os.Zygote.forkAndSpecialize
```


### Why Screen Freezes Occur

After zygote crashes, Android cannot spawn new processes:

- Continuous "Connection refused" errors
- System watchdog timeouts and ANR (Application Not Responding)
- Screen becomes unresponsive (no new apps can launch)
- System UI freezes as components can't restart

***

## 🔧 Build Configuration Fix

### Conservative Approach (Recommended)

This configuration disables MTE only for problematic components while maintaining security for other apps.

#### 1. Main Build Configuration (device.mk or vendor.mk)

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

# Additional system components
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.se=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.google.android.bluetooth=off
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.app.com.android.nfc=off

# Disable async MTE globally (use sync mode for better stability with Zygisk)
PRODUCT_PRODUCT_PROPERTIES += persist.device_config.memory_safety_native.bootloader_enabled=false
PRODUCT_PRODUCT_PROPERTIES += persist.arm64.memtag.bootloader_settings_toggle=false

# Set MTE sample rate to 0 for excluded apps
PRODUCT_PRODUCT_PROPERTIES += arm64.memtag.process.sample_rate=0
```


#### 2. Kernel Configuration (BoardConfig.mk)

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


#### 3. Kernel Defconfig (arch/arm64/configs/your_defconfig)

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


#### 4. SELinux Policy (Optional but Recommended)

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


#### 5. System Properties (init.rc)

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


#### 6. Zygisk Module Compatibility (Optional)

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

Make executable:

```bash
chmod +x /data/adb/service.d/zygisk-mte-fix.sh
```


***

## ❌ Complete MTE Disable Configuration

Use this if the conservative approach doesn't resolve issues.

### 1. Build Configuration (device.mk or vendor.mk)

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


### 2. Kernel Configuration (BoardConfig.mk)

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
```


### 3. Kernel Defconfig

```bash
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
```


### 4. System Properties (system.prop)

```properties
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

# Bionic settings
libc.debug.mte.program=off
libc.debug.mte.options=none

# Disable checks
persist.arm64.memtag.check.all=false
```


### 5. Init Script (init.mte_disable.rc)

```bash
on early-init
    write /proc/sys/vm/mte_report_once 0
    setprop ro.arm64.memtag.bootctl_supported 0

on init
    setprop persist.arm64.memtag.default off
    setprop arm64.memtag.process.sample_rate 0

on boot
    setprop persist.arm64.memtag.system_server off
    setprop persist.arm64.memtag.zygote off
    setprop persist.arm64.memtag.zygote64 off
    setprop persist.arm64.memtag.app off
    setprop persist.arm64.memtag.app_isolated off
    setprop libc.debug.mte.program off
    setprop libc.debug.mte.options none
    write /proc/sys/vm/mte_report_once 0

on property:sys.boot_completed=1
    setprop persist.arm64.memtag.default off
    setprop arm64.memtag.process.sample_rate 0
```


***

## 🌐 WebView-Specific Solutions

### Solution 1: Exclude WebView from Zygisk Injection

**Via Magisk/KernelSU Manager:**

```
Settings → Configure Denylist → Add:
- com.google.android.webview
- com.android.webview
- com.google.android.trichromelibrary
- com.android.chrome
```

**Via command line:**

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


### Solution 2: Configure Zygisk-Detach to Skip WebView

```bash
adb shell
nano /data/adb/modules/zygisk-detach/detach.txt

# Add these lines to EXCLUDE from detaching:
!com.google.android.webview
!com.android.webview
!com.google.android.trichromelibrary
```


### Solution 3: Use Alternative WebView

Switch to Bromite or Mulch WebView:

1. Download **Bromite System WebView** or **Mulch WebView**
2. Install as system app
3. Select in: **Settings → Developer Options → WebView Implementation**

### Solution 4: Disable Async MTE for WebView

```bash
adb shell
setprop persist.device_config.memory_safety_native.decode_mode sync
setprop persist.sys.mte.mode sync
setprop persist.sys.mte.check.webview false
reboot
```


### Solution 5: Use Shamiko Instead of Zygisk-Detach

```bash
# Remove zygisk-detach
adb shell rm -rf /data/adb/modules/zygisk-detach

# Install Shamiko from:
# https://github.com/LSPosed/LSPosed.github.io/releases
# Flash via Magisk/KernelSU Manager
reboot
```


***

## ✅ Verification \& Testing

### Build \& Flash

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


### Verification After Boot

**Check MTE settings:**

```bash
adb shell getprop | grep memtag
```

**Verify zygote is running without MTE:**

```bash
adb shell ps -A | grep zygote
adb shell cat /proc/$(pidof zygote64)/status | grep tagged
```

**Check kernel command line:**

```bash
adb shell cat /proc/cmdline | grep mte
```

**Test WebView:**

```bash
adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main
# Should not crash
```

**Check for crashes:**

```bash
adb logcat | grep -i "mte\|segv"
# Should show no MTE-related crashes
```


***

## 🎯 Results

With proper configuration, you should achieve:

1. ✅ Prevent zygote crashes with Zygisk modules
2. ✅ Allow webview to load normally
3. ✅ Fix Chrome sandboxed process crashes
4. ✅ Maintain MTE for other apps (security preserved with conservative approach)
5. ✅ Stable system with no screen freezes

***

## 📊 Configuration Comparison

| Approach | MTE Status | Security Level | Compatibility | Use Case |
| :-- | :-- | :-- | :-- | :-- |
| **Conservative** | Partial (excludes problematic apps) | High | Best | Production ROMs |
| **Complete Disable** | Fully disabled | Medium | Maximum | Development/troubleshooting |


***

## 🔧 Troubleshooting

**If still experiencing crashes:**

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

**Check module conflicts:**

```bash
adb shell ls -la /data/adb/modules/
# Disable all except essential ones
# Re-enable one by one to find conflicts
```


***

## ⚠️ Important Notes

- **Conservative approach recommended** for maintaining security while fixing crashes
- **Test thoroughly** after implementing changes
- **Monitor** `/data/tombstones/` for crash reports
- **Keep modules updated** for compatibility with Android 15+
- **Backup** before making system-level changes

***

This configuration eliminates SEGV_MTE_AERR crashes without compromising overall system security when using the conservative approach.
<span style="display:none">[^1][^2][^3]</span>

<div align="center">⁂</div>

[^1]: Complete-MTE-Build-Configuration-Fix.md

[^2]: MTE-Root-Cause-Identified.md

[^3]: Simple-Commands.md

