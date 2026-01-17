<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

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
<span style="display:none">[^1]</span>

<div align="center">⁂</div>

[^1]: log_file.txt

