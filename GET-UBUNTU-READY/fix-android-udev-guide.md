# Fix Android USB Device Detection on Linux

This guide will help you set up udev rules to enable ADB (Android Debug Bridge) access to Android devices on Linux without requiring root privileges.

## Problem

When connecting an Android device to Linux, you may encounter:
- Device not detected by `adb devices`
- "no permissions" error
- Missing `/etc/udev/rules.d/51-android.rules` file

## Solution

Use the provided script to automatically create the udev rules file with common Android vendor IDs, including MediaTek, Samsung, Google, and others.

---

## Installation Guide

### Step 1: Create the Script

Copy the script below and save it as `fix-android-udev.sh`:

```bash
#!/usr/bin/env bash
set -e

RULES_FILE="/etc/udev/rules.d/51-android.rules"

echo "Creating $RULES_FILE with common Android vendors..."

cat > "$RULES_FILE" <<'EOF'
# Android udev rules
SUBSYSTEM=="usb", ATTR{idVendor}=="0502", MODE="0666", GROUP="plugdev"   # Acer
SUBSYSTEM=="usb", ATTR{idVendor}=="0B05", MODE="0666", GROUP="plugdev"   # ASUS
SUBSYSTEM=="usb", ATTR{idVendor}=="413C", MODE="0666", GROUP="plugdev"   # Dell
SUBSYSTEM=="usb", ATTR{idVendor}=="0489", MODE="0666", GROUP="plugdev"   # Foxconn
SUBSYSTEM=="usb", ATTR{idVendor}=="18D1", MODE="0666", GROUP="plugdev"   # Google
SUBSYSTEM=="usb", ATTR{idVendor}=="0BB4", MODE="0666", GROUP="plugdev"   # HTC
SUBSYSTEM=="usb", ATTR{idVendor}=="12D1", MODE="0666", GROUP="plugdev"   # Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="17EF", MODE="0666", GROUP="plugdev"   # Lenovo
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0666", GROUP="plugdev"   # LG
SUBSYSTEM=="usb", ATTR{idVendor}=="22B8", MODE="0666", GROUP="plugdev"   # Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="0955", MODE="0666", GROUP="plugdev"   # Nvidia
SUBSYSTEM=="usb", ATTR{idVendor}=="04E8", MODE="0666", GROUP="plugdev"   # Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="0FCE", MODE="0666", GROUP="plugdev"   # Sony / Sony Ericsson
SUBSYSTEM=="usb", ATTR{idVendor}=="0930", MODE="0666", GROUP="plugdev"   # Toshiba
SUBSYSTEM=="usb", ATTR{idVendor}=="19D2", MODE="0666", GROUP="plugdev"   # ZTE
SUBSYSTEM=="usb", ATTR{idVendor}=="0E8D", MODE="0666", GROUP="plugdev"   # MediaTek
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev"   # Xiaomi
SUBSYSTEM=="usb", ATTR{idVendor}=="2A70", MODE="0666", GROUP="plugdev"   # OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="1D91", MODE="0666", GROUP="plugdev"   # Vivo
SUBSYSTEM=="usb", ATTR{idVendor}=="2D95", MODE="0666", GROUP="plugdev"   # Realme / Oppo
EOF

echo "Setting correct permissions..."

# Ensure group exists (change to plugdev/adbusers as your distro uses)
if ! getent group plugdev >/dev/null 2>&1; then
  echo "Creating plugdev group..."
  groupadd plugdev
fi

# Add current user to plugdev group
if [ -n "$SUDO_USER" ]; then
  usermod -aG plugdev "$SUDO_USER"
  echo "Added $SUDO_USER to plugdev group"
else
  echo "Warning: Could not determine user. Please run: sudo usermod -aG plugdev YOUR_USERNAME"
fi

chmod a+r "$RULES_FILE"

echo "Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

echo ""
echo "✓ Done! Android udev rules installed successfully."
echo ""
echo "IMPORTANT: Log out and log back in for group changes to take effect,"
echo "           then reconnect your Android device."
echo ""
echo "To verify your device:"
echo "  1. Enable USB debugging on your Android device"
echo "  2. Connect via USB"
echo "  3. Run: adb devices"
```

### Step 2: Make the Script Executable

Open a terminal in the directory where you saved the script and run:

```bash
chmod +x fix-android-udev.sh
```

### Step 3: Run the Script

Execute the script with sudo (root privileges are required to modify system files):

```bash
sudo ./fix-android-udev.sh
```

**Alternative method** (if the above doesn't work):

```bash
sudo bash fix-android-udev.sh
```

### Step 4: Log Out and Log Back In

For the group membership changes to take effect, you must log out of your session and log back in (or reboot).

### Step 5: Connect Your Android Device

1. Enable **USB Debugging** on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times to enable Developer Options
   - Go to Settings → Developer Options
   - Enable "USB Debugging"

2. Connect your device via USB cable

3. Verify the connection:

```bash
adb devices
```

You should see your device listed. If prompted on your phone, allow USB debugging.

---

## Troubleshooting

### Device Still Not Detected

If your device is still not recognized, find its vendor ID:

```bash
lsusb
```

Look for your device in the output (e.g., `Bus 001 Device 005: ID 0e8d:201d MediaTek Inc.`)

The vendor ID is the first 4-digit hex code after `ID` (e.g., `0e8d` for MediaTek).

Add a new rule to `/etc/udev/rules.d/51-android.rules`:

```bash
SUBSYSTEM=="usb", ATTR{idVendor}=="XXXX", MODE="0666", GROUP="plugdev"   # Your Device
```

Replace `XXXX` with your actual vendor ID, then reload:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Check Group Membership

Verify you're in the plugdev group:

```bash
groups
```

If `plugdev` is not listed, add yourself manually:

```bash
sudo usermod -aG plugdev $USER
```

Then log out and log back in.

### ADB Server Issues

If `adb devices` shows your device as "unauthorized":
- Check your phone screen for an authorization prompt
- Accept the prompt and optionally check "Always allow from this computer"

If ADB still doesn't work, restart the ADB server:

```bash
adb kill-server
adb start-server
adb devices
```

---

## Supported Vendors

The script includes rules for these major Android device manufacturers:

- Acer
- ASUS
- Dell
- Foxconn
- Google (Pixel, Nexus)
- HTC
- Huawei
- Lenovo
- LG
- Motorola
- Nvidia
- Samsung
- Sony / Sony Ericsson
- Toshiba
- ZTE
- **MediaTek** (MTK chipsets)
- Xiaomi
- OnePlus
- Vivo
- Realme / Oppo

---

## What This Script Does

1. Creates `/etc/udev/rules.d/51-android.rules` with USB vendor rules
2. Sets MODE="0666" to allow read/write access for all users
3. Assigns devices to the `plugdev` group
4. Creates the `plugdev` group if it doesn't exist
5. Adds your user to the `plugdev` group
6. Sets correct file permissions (readable by all)
7. Reloads udev rules without requiring a reboot

---

## Manual Installation (Alternative)

If you prefer not to use the script:

1. Create the file manually:
```bash
sudo nano /etc/udev/rules.d/51-android.rules
```

2. Paste the rules (see script content above)

3. Save and exit (Ctrl+X, Y, Enter)

4. Set permissions:
```bash
sudo chmod a+r /etc/udev/rules.d/51-android.rules
```

5. Add yourself to plugdev group:
```bash
sudo usermod -aG plugdev $USER
```

6. Reload udev:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

7. Log out and log back in

---

## License

This script and guide are provided as-is for free use and modification.

## Credits

Based on common Android udev rules from the Android development community and various Linux distributions.
