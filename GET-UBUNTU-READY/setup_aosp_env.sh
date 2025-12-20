#!/usr/bin/env bash

# Combined AOSP Environment Setup + Android udev Rules Fix
# Compatible with Ubuntu 25.10
# Run with: bash setup_aosp_env.sh

set -e

echo "=========================================="
echo "AOSP Build Environment Setup (Ubuntu 25.10)"
echo "=========================================="
echo ""

# Store the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

echo "Enabling universe repository..."
sudo add-apt-repository universe -y
wait

echo ""
echo "Updating and Upgrading System..."
sudo apt-get update && apt-get upgrade -y
wait

echo ""
echo "Adding git-core PPA..."
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt-get update && apt-get upgrade -y
wait

echo ""
echo "Installing Essential Build Tools..."
sudo apt-get install -y bc bison build-essential ccache curl flex git \
g++-multilib gcc-multilib gnupg gperf imagemagick lib32ncurses-dev \
lib32z1-dev libc6-dev-i386 libgl1-mesa-dev libssl-dev libx11-dev
wait

echo ""
echo "Installing Additional Libraries and Utilities..."
sudo apt-get install -y libxml2-utils unzip xorg-dev xsltproc zip zlib1g-dev \
default-jre default-jdk nghttp2 libnghttp2-dev fakeroot dpkg-dev \
libcurl4-openssl-dev git-lfs patchelf policycoreutils-python-utils
wait

echo ""
echo "Installing Kernel-Related Packages..."
sudo apt-get install -y git automake flex lzop bison gperf build-essential zip curl \
zlib1g-dev g++-multilib python3-networkx libxml2-utils bzip2 libbz2-dev libbz2-1.0 \
libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev lz4 \
make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom \
libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 xorg-dev libx11-dev \
lib32z1-dev libgl1-mesa-dev xsltproc unzip
wait

echo ""
echo "Installing Archive and Compression Tools..."
sudo apt-get install -y unace unrar zip unzip p7zip-full p7zip-rar sharutils rar \
uudeview mpack arj cabextract rename liblzma-dev brotli lz4 \
libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev asciidoc xmlto docbook2x
wait

echo ""
echo "Installing Python Dependencies and Dev Tools..."
sudo apt-get install -y python3 python3-full python3-pip python3-protobuf \
python-is-python3 python3-venv libncurses6 fontconfig rsync openssl clang cmake ninja-build \
libncurses-dev lib32stdc++6 libelf-dev libsdl2-dev android-sdk-libsparse-utils erofs-utils
wait

echo ""
echo ""
echo "=========================================="
echo "Configuring Android SDK Paths"
echo "=========================================="
echo ""

ANDROID_SDK_PATH="$ACTUAL_HOME/Android/Sdk"

# Verify Android SDK exists

echo ""
echo "Setting up Android SDK Platform Tools Path..."
if ! grep -q "ANDROID_HOME" "$ACTUAL_HOME/.bashrc"; then
cat >> "$ACTUAL_HOME/.bashrc" <<'EOL'

# AOSP Build Configuration
export USE_CCACHE=1
ccache -M 150G

# Android SDK Configuration (Android Studio)
export ANDROID_HOME=${HOME}/Android/Sdk
export ANDROID_SDK_ROOT=${HOME}/Android/Sdk
export PATH=${HOME}/.bin:${PATH}
export PATH=${ANDROID_HOME}/platform-tools:${PATH}
export PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${PATH}
export PATH=${ANDROID_HOME}/build-tools/36.1.0:${PATH}
EOL
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bashrc"
    echo "✓ Added Android SDK paths to ~/.bashrc"
else
    echo "✓ ANDROID_HOME already configured in ~/.bashrc"
fi

# Create symlinks for system-wide access

echo ""
echo "Setting up git-repo..."
sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.bin"
sudo -u "$ACTUAL_USER" curl -o "$ACTUAL_HOME/.bin/repo" https://storage.googleapis.com/git-repo-downloads/repo
chmod a+rx "$ACTUAL_HOME/.bin/repo"
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bin/repo"
wait

echo ""
echo "Configuring Git..."
sudo -u "$ACTUAL_USER" git config --global user.name "Omkar Parte"
sudo -u "$ACTUAL_USER" git config --global user.email "rakmoparte@gmail.com"

echo ""
echo "Flatpak Installation (optional)..."
sudo apt install -y flatpak plasma-discover-backend-flatpak
wait
sudo -u "$ACTUAL_USER" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
wait

echo ""
echo "=========================================="
echo "Android udev Rules Configuration"
echo "=========================================="
echo ""

RULES_FILE="/etc/udev/rules.d/51-android.rules"

echo "Creating $RULES_FILE with common Android vendors..."

sudo tee "$RULES_FILE" >/dev/null <<\'EOF\'
# Android udev rules

SUBSYSTEM=="usb", ATTR{idVendor}=="0502", MODE="0666", GROUP="plugdev" # Acer
SUBSYSTEM=="usb", ATTR{idVendor}=="0B05", MODE="0666", GROUP="plugdev" # ASUS
SUBSYSTEM=="usb", ATTR{idVendor}=="413C", MODE="0666", GROUP="plugdev" # Dell
SUBSYSTEM=="usb", ATTR{idVendor}=="0489", MODE="0666", GROUP="plugdev" # Foxconn
SUBSYSTEM=="usb", ATTR{idVendor}=="18D1", MODE="0666", GROUP="plugdev" # Google
SUBSYSTEM=="usb", ATTR{idVendor}=="0BB4", MODE="0666", GROUP="plugdev" # HTC
SUBSYSTEM=="usb", ATTR{idVendor}=="12D1", MODE="0666", GROUP="plugdev" # Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="17EF", MODE="0666", GROUP="plugdev" # Lenovo
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0666", GROUP="plugdev" # LG
SUBSYSTEM=="usb", ATTR{idVendor}=="22B8", MODE="0666", GROUP="plugdev" # Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="0955", MODE="0666", GROUP="plugdev" # Nvidia
SUBSYSTEM=="usb", ATTR{idVendor}=="04E8", MODE="0666", GROUP="plugdev" # Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="0FCE", MODE="0666", GROUP="plugdev" # Sony / Sony Ericsson
SUBSYSTEM=="usb", ATTR{idVendor}=="0930", MODE="0666", GROUP="plugdev" # Toshiba
SUBSYSTEM=="usb", ATTR{idVendor}=="19D2", MODE="0666", GROUP="plugdev" # ZTE
SUBSYSTEM=="usb", ATTR{idVendor}=="0E8D", MODE="0666", GROUP="plugdev" # MediaTek
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev" # Xiaomi
SUBSYSTEM=="usb", ATTR{idVendor}=="2A70", MODE="0666", GROUP="plugdev" # OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="1D91", MODE="0666", GROUP="plugdev" # Vivo
SUBSYSTEM=="usb", ATTR{idVendor}=="2D95", MODE="0666", GROUP="plugdev" # Realme / Oppo
EOF

echo ""
echo "Setting correct permissions..."

# Ensure group exists
if ! getent group plugdev >/dev/null 2>&1; then
echo "Creating plugdev group..."
sudo groupadd plugdev
fi

# Add user to plugdev group
sudo usermod -aG plugdev "$ACTUAL_USER"
echo "Added $ACTUAL_USER to plugdev group"

sudo chmod a+r "$RULES_FILE"

echo ""
echo "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger
wait

echo ""
echo "=========================================="
echo "✓ Installation Complete!"
echo "=========================================="
echo ""
echo "Changes made from original scripts:"
echo "1. Added 'add-apt-repository universe' to enable universe repository"
echo "2. Replaced 'liblz4-tool' with 'lz4' (deprecated package in Ubuntu 24.10+)"
echo "3. FIXED: Uses exact Android Studio SDK paths:"
echo "   - platform-tools (adb, fastboot)"
echo "   - cmdline-tools/latest/bin (sdkmanager, avdmanager)"
echo "   - build-tools/36.1.0 (aapt, zipalign, apksigner, etc.)"
echo "4. FIXED: Added ANDROID_SDK_ROOT environment variable"
echo "6. Added explicit wait commands after each installation section"
echo "7. Combined both scripts into single workflow (AOSP setup → udev rules)"
echo "8. Improved user detection when running with sudo"
echo ""
echo "Configured Android SDK paths:"
echo "  - Platform Tools: ~/Android/Sdk/platform-tools"
echo "  - Command Line Tools: ~/Android/Sdk/cmdline-tools/latest"
echo "  - Build Tools: ~/Android/Sdk/build-tools/36.1.0"
echo ""
echo "IMPORTANT NEXT STEPS:"
echo "1. Log out and log back in for PATH and group changes to take effect"
echo "2. After logging back in, verify installations:"
echo "   - adb --version"
echo "   - fastboot --version"
echo "   - aapt version"
echo "   - repo version"
echo "3. Enable USB debugging on your Android device"
echo "4. Connect device via USB and run: adb devices"
echo ""
