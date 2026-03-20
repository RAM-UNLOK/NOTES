#!/usr/bin/env bash

# ==============================================================================
# Ultimate AOSP 16.2 Build Environment Setup & Updater for Kubuntu 24.04 LTS
# Target: Android 16.2 / android-16.0.0_r4
# Hardware Optimization: Intel i7-12700KF (20 Threads) & AMD RX 6800 XT
# Description: Automates the installation of dependencies, validates existing 
#              tools, forcefully updates outdated components, and optimizes network.
# ==============================================================================

set -e

echo "=========================================================="
echo " Initiating AOSP Build Setup & Validator for Kubuntu 24.04 LTS"
echo "=========================================================="
echo ""

ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run this script with sudo (e.g., sudo bash setup_aosp_kubuntu.sh)"
  exit 1
fi

echo "--> 1/9 Optional Repository Setup"
# BACKGROUND: Check if Universe/Multiverse should be added.
read -p "Do you want to enable Universe and Multiverse repositories? [y/N]: " ENABLE_REPOS
ENABLE_REPOS=${ENABLE_REPOS:-N}

if [[ "$ENABLE_REPOS" =~ ^[Yy]$ ]]; then
    echo "--> Enabling universe and multiverse repositories..."
    add-apt-repository universe -y
    add-apt-repository multiverse -y
    wait
else
    echo "--> Skipping repository enablement (Default)."
fi

echo "--> 2/9 Verifying System Packages & Forcing Updates..."
# BACKGROUND: Updates the APT cache and forcefully upgrades all existing system packages.
apt-get update -y
apt-get upgrade -y
wait

echo "--> 3/9 Verifying & Updating official git-core PPA..."
add-apt-repository ppa:git-core/ppa -y
apt-get update -y
wait

echo "--> 4/9 Verifying Build Tools, Dependencies, and Libraries..."
# BACKGROUND: Installs required compilers and tools. 'ninja-build' will heavily utilize 
# the 20 threads on your i7-12700KF to blaze through the AOSP source.
apt-get install -y \
  bc bison build-essential ccache curl flex git git-core gnupg gperf \
  imagemagick lib32ncurses-dev lib32z1-dev libc6-dev-i386 libgl1-mesa-dev \
  libssl-dev libx11-dev libxml2-utils unzip xorg-dev xsltproc zip zlib1g-dev \
  default-jre default-jdk nghttp2 libnghttp2-dev fakeroot dpkg-dev \
  libcurl4-openssl-dev git-lfs patchelf policycoreutils-python-utils \
  automake lzop python3-networkx bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev \
  squashfs-tools pngcrush schedtool lz4 make optipng maven pwgen libswitch-perl \
  policycoreutils minicom libxml-sax-base-perl libxml-simple-perl p7zip-full \
  p7zip-rar sharutils rar uudeview mpack arj cabextract rename liblzma-dev brotli \
  libexpat1-dev gettext libz-dev asciidoc xmlto docbook2x \
  python3 python3-full python3-pip python3-protobuf python-is-python3 python3-venv \
  libncurses6 fontconfig rsync openssl clang cmake ninja-build libncurses-dev \
  lib32stdc++6 libelf-dev libsdl2-dev android-sdk-libsparse-utils erofs-utils aria2 \
  wget apt-transport-https software-properties-common
wait

echo "--> 5/9 Verifying Virtualization Support (KVM / Cuttlefish / Emulator)..."
# BACKGROUND: Sets up Virtualization so your RX 6800 XT can be utilized via hardware 
# acceleration for the Android Emulator and AOSP Cuttlefish.
apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils cpu-checker
usermod -aG kvm "$ACTUAL_USER"
usermod -aG libvirt "$ACTUAL_USER"
wait

echo "--> 6/9 Verifying Flatpak & Apps (Telegram, Google Chrome)..."
# BACKGROUND: Ensures Flatpak is installed and actively updates Telegram/Chrome if they exist.
apt-get install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "--> Checking Flathub for app updates/installations..."
flatpak install -y --or-update flathub org.telegram.desktop com.google.Chrome
flatpak update -y
wait

echo "=========================================================="
echo " Hardware-Specific Limits & Network Fixes"
echo "=========================================================="

echo "--> Configuring Open File Limits (i7-12700KF Hardware Optimization)..."
# BACKGROUND: Your 20-thread CPU will try to open thousands of files simultaneously.
# The standard Linux file limit (1,024) will cause a crash. Setting this to 1,048,576
# prevents IO throttling and crashes during heavy parallel compilation.
read -p "Do you want to configure Open File Limits for high-thread (i7-12700KF) builds?[Y/n]: " SET_FILE_LIMITS
SET_FILE_LIMITS=${SET_FILE_LIMITS:-Y} # Defaults to Y if user just presses Enter

if [[ "$SET_FILE_LIMITS" =~ ^[Yy]$ ]]; then
    echo "--> Applying 1048576 open file limit for $ACTUAL_USER..."
    cat > /etc/security/limits.d/99-aosp.conf <<EOF
$ACTUAL_USER soft nofile 1048576
$ACTUAL_USER hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF
    echo "✓ High compute file limits applied."
else
    echo "--> Skipping Open File Limits configuration."
fi

echo "--> Updating TCP Window Scaling and Network Tweaks..."
cat > /etc/sysctl.d/99-aosp-net.conf <<EOF
net.ipv4.tcp_window_scaling=1
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
EOF
sysctl --system > /dev/null

echo "=========================================================="
echo " Verifying Android SDK, NDK, and Build Tools"
echo "=========================================================="

ANDROID_SDK_PATH="$ACTUAL_HOME/Android/Sdk"
CMDLINE_TOOLS_DIR="$ANDROID_SDK_PATH/cmdline-tools/latest"

sudo -u "$ACTUAL_USER" mkdir -p "$ANDROID_SDK_PATH"

if[ -f "$CMDLINE_TOOLS_DIR/bin/sdkmanager" ]; then
    echo "--> SDK Command Line Tools found. Forcing update of existing Android tools..."
    set +e
    yes | sudo -u "$ACTUAL_USER" ANDROID_HOME="$ANDROID_SDK_PATH" "$CMDLINE_TOOLS_DIR/bin/sdkmanager" --sdk_root="$ANDROID_SDK_PATH" --licenses > /dev/null 2>&1
    sudo -u "$ACTUAL_USER" ANDROID_HOME="$ANDROID_SDK_PATH" "$CMDLINE_TOOLS_DIR/bin/sdkmanager" --sdk_root="$ANDROID_SDK_PATH" --update > /dev/null
    set -e
else
    echo "--> SDK Command Line Tools missing or broken. Downloading latest version..."
    sudo -u "$ACTUAL_USER" mkdir -p "$ANDROID_SDK_PATH/cmdline-tools"
    wget -q --show-progress -O /tmp/cmdline-tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    
    echo "--> Extracting Command Line Tools..."
    sudo -u "$ACTUAL_USER" unzip -q /tmp/cmdline-tools.zip -d /tmp/
    rm -rf "$CMDLINE_TOOLS_DIR"
    sudo -u "$ACTUAL_USER" mv /tmp/cmdline-tools "$CMDLINE_TOOLS_DIR"
    rm -f /tmp/cmdline-tools.zip
fi

echo "--> Verifying explicit SDK components (Platform-Tools, Build-Tools, Emulator, NDK)..."
set +e 
yes | sudo -u "$ACTUAL_USER" ANDROID_HOME="$ANDROID_SDK_PATH" "$CMDLINE_TOOLS_DIR/bin/sdkmanager" --sdk_root="$ANDROID_SDK_PATH" --licenses > /dev/null 2>&1
sudo -u "$ACTUAL_USER" ANDROID_HOME="$ANDROID_SDK_PATH" "$CMDLINE_TOOLS_DIR/bin/sdkmanager" --sdk_root="$ANDROID_SDK_PATH" \
    "platform-tools" \
    "build-tools;36.1.0" \
    "emulator" \
    "ndk;28.0.3005884" > /dev/null
set -e

echo "--> Validating ~/.bashrc for stale SDK Paths..."
# BACKGROUND: Searches for our block, deletes it if found, and injects a fresh one.
if grep -q "# --- AOSP ENV START ---" "$ACTUAL_HOME/.bashrc"; then
    echo "--> Old AOSP paths found. Scrubbing and rewriting to ensure they are up to date..."
    sed -i '/# --- AOSP ENV START ---/,/# --- AOSP ENV END ---/d' "$ACTUAL_HOME/.bashrc"
fi

cat >> "$ACTUAL_HOME/.bashrc" <<'EOL'
# --- AOSP ENV START ---
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

# Base SDK and NDK Directories
export ANDROID_HOME=${HOME}/Android/Sdk
export ANDROID_SDK_ROOT=${HOME}/Android/Sdk
export NDK_HOME=${ANDROID_HOME}/ndk/28.0.3005884

# Appending Tools to PATH so they can be run redundantly from any terminal
export PATH=${HOME}/.bin:${PATH}
export PATH=${ANDROID_HOME}/platform-tools:${PATH}
export PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${PATH}
export PATH=${ANDROID_HOME}/build-tools/36.1.0:${PATH}
export PATH=${ANDROID_HOME}/emulator:${PATH}
# --- AOSP ENV END ---
EOL
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bashrc"
echo "✓ AOSP Environment variables verified and forcefully written to ~/.bashrc"

echo "=========================================================="
echo " Source Control (Repo & Git) Configuration"
echo "=========================================================="

echo "--> 7/9 Verifying and forcefully updating Google's git-repo tool..."
sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.bin"
rm -f "$ACTUAL_HOME/.bin/repo"
sudo -u "$ACTUAL_USER" curl -s -o "$ACTUAL_HOME/.bin/repo" https://storage.googleapis.com/git-repo-downloads/repo
chmod a+rx "$ACTUAL_HOME/.bin/repo"
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bin/repo"

echo "--> 8/9 Enforcing Git Identity and Network Workarounds..."
sudo -u "$ACTUAL_USER" git config --global user.name "Omkar Parte"
sudo -u "$ACTUAL_USER" git config --global user.email "rakmoparte@gmail.com"
sudo -u "$ACTUAL_USER" git config --global color.ui true

sudo -u "$ACTUAL_USER" git config --global http.postBuffer 524288000
sudo -u "$ACTUAL_USER" git config --global http.maxRequestBuffer 100M
sudo -u "$ACTUAL_USER" git config --global core.compression 0
sudo -u "$ACTUAL_USER" git config --global fetch.prune true
sudo -u "$ACTUAL_USER" git config --global pack.windowMemory 10m
sudo -u "$ACTUAL_USER" git config --global pack.packSizeLimit 20m

echo "=========================================================="
echo " Android udev Rules Configuration"
echo "=========================================================="

echo "--> 9/9 Forcing Update of USB (udev) Rules for Fastboot / ADB Devices..."
RULES_FILE="/etc/udev/rules.d/51-android.rules"

cat > "$RULES_FILE" <<'EOF'
# Android udev rules for adb/fastboot connectivity
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
SUBSYSTEM=="usb", ATTR{idVendor}=="0FCE", MODE="0666", GROUP="plugdev" # Sony
SUBSYSTEM=="usb", ATTR{idVendor}=="0930", MODE="0666", GROUP="plugdev" # Toshiba
SUBSYSTEM=="usb", ATTR{idVendor}=="19D2", MODE="0666", GROUP="plugdev" # ZTE
SUBSYSTEM=="usb", ATTR{idVendor}=="0E8D", MODE="0666", GROUP="plugdev" # MediaTek
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev" # Xiaomi
SUBSYSTEM=="usb", ATTR{idVendor}=="2A70", MODE="0666", GROUP="plugdev" # OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="1D91", MODE="0666", GROUP="plugdev" # Vivo
SUBSYSTEM=="usb", ATTR{idVendor}=="2D95", MODE="0666", GROUP="plugdev" # Realme/Oppo
EOF

if ! getent group plugdev >/dev/null 2>&1; then
    groupadd plugdev
fi

usermod -aG plugdev "$ACTUAL_USER"
chmod a+r "$RULES_FILE"

# Reload the Linux device manager to apply the rules immediately
udevadm control --reload-rules
udevadm trigger
wait

echo "=========================================================="
echo " ✓ ALL VERIFICATIONS AND UPDATES COMPLETE!"
echo "=========================================================="
echo ""
echo " REMINDER: Set your CCACHE limit inside your specific build directory:"
echo " Example: export USE_CCACHE=1 && ccache -M 150G"
echo ""
echo " IMPORTANT NEXT STEPS:"
echo " 1. SYSTEM REBOOT is highly recommended. KVM (Virtualization), Linux limits,"
echo "    and plugdev groups strictly require a fresh login."
echo ""
echo " 2. Verify Android tool installations post-reboot:"
echo "    $ adb --version"
echo "    $ fastboot --version"
echo "    $ repo version"