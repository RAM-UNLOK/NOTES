#!/usr/bin/env bash

# ==============================================================================
# Ultimate AOSP Build Environment Setup & Updater
# Target OS : Ubuntu / Kubuntu 26.04 LTS
# Target     : Android 16.x / AOSP Latest
# Hardware   : Intel i7-12700KF (20 Threads) & AMD RX 6800 XT
# Author     : Omkar Parte (Digimend Labs)
# Description: All-in-one installer – validates, updates, and configures the
#              complete AOSP build environment including Apktool, udev rules,
#              KVM, Flatpak apps, git-repo, and Android SDK paths.
# ==============================================================================

set -euo pipefail

# ── Colour helpers ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"; \
            echo -e "${BOLD}${CYAN}║  $*${RESET}"; \
            echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"; }

wait_bar() {
    local seconds="${1:-3}"
    local label="${2:-Waiting}"
    for ((i=seconds; i>0; i--)); do
        echo -ne "\r${CYAN}  ⏳ ${label} … ${i}s remaining   ${RESET}"
        sleep 1
    done
    echo -e "\r${GREEN}  ✔  ${label} complete.            ${RESET}"
}

# ── Root check ─────────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
    error "Please run with sudo:  sudo bash setup_aosp_kubuntu.sh"
    exit 1
fi

ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

echo -e "\n${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║   AOSP Build Environment – Ubuntu / Kubuntu 26.04 LTS   ║"
echo "  ║          All-in-one Installer  •  Digimend Labs           ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ═════════════════════════════════════════════════════════════════════════════
# STEP 1 – Optional Repository Setup
# ═════════════════════════════════════════════════════════════════════════════
header "Step 1/9 · Optional Repository Setup"

read -rp "  Enable Universe and Multiverse repositories? [y/N]: " ENABLE_REPOS
ENABLE_REPOS="${ENABLE_REPOS:-N}"

if [[ "$ENABLE_REPOS" =~ ^[Yy]$ ]]; then
    info "Enabling Universe and Multiverse …"
    add-apt-repository universe  -y
    add-apt-repository multiverse -y
    wait_bar 3 "Repos added"
else
    info "Skipping Universe/Multiverse (default)."
fi

# ═════════════════════════════════════════════════════════════════════════════
# STEP 2 – System Package Update & Upgrade
# ═════════════════════════════════════════════════════════════════════════════
header "Step 2/9 · System Package Update & Upgrade"

info "Running apt-get update …"
apt-get update -y
info "Running apt-get upgrade …"
apt-get upgrade -y
wait_bar 5 "System packages updated"
success "System packages are up to date."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 3 – git-core PPA
# ═════════════════════════════════════════════════════════════════════════════
header "Step 3/9 · Verifying & Updating git-core PPA"

add-apt-repository ppa:git-core/ppa -y
apt-get update -y
wait_bar 3 "git-core PPA ready"
success "git-core PPA verified."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 4 – Build Dependencies
# ═════════════════════════════════════════════════════════════════════════════
header "Step 4/9 · Installing Build Dependencies"

# ── 4a: Core build tools ──────────────────────────────────────────────────────
info "Installing core build tools …"
apt-get install -y \
    bc bison build-essential ccache curl flex \
    gnupg gperf make schedtool zip unzip \
    apt-transport-https software-properties-common wget
wait_bar 5 "Core build tools"
success "Core build tools installed."

info "Setting ccache max size to 100 GB …"
ccache -M 100G
success "ccache max cache size → 100 GB"

# ── 4b: Git & version control ─────────────────────────────────────────────────
info "Installing git, git-core, git-lfs …"
apt-get install -y git git-core git-lfs
wait_bar 3 "Git tools"
success "Git and git-lfs installed."

# ── 4c: Java (JDK / JRE) ──────────────────────────────────────────────────────
info "Installing default JDK / JRE …"
apt-get install -y default-jre default-jdk
wait_bar 5 "Java JDK/JRE"
success "Java installed."

JAVA_MAJOR="$(java -version 2>&1 | grep -oP '(?<=version ")\d+' | head -1)"
if [[ "$JAVA_MAJOR" -lt 8 ]]; then
    error "Apktool and AOSP require Java 8+. Found Java $JAVA_MAJOR. Aborting."
    exit 1
fi
info "Java version: $JAVA_MAJOR (compatible ✔)"

# ── 4d: Compression & archive libraries ───────────────────────────────────────
info "Installing compression & archive libraries …"
apt-get install -y \
    bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev brotli \
    lz4 lzop liblzma-dev squashfs-tools \
    p7zip-full p7zip-rar rar sharutils uudeview mpack arj cabextract rename
wait_bar 4 "Compression & archive libs"
success "Compression libraries installed."

# ── 4e: 32-bit & multi-arch libraries ─────────────────────────────────────────
info "Installing 32-bit & multi-arch libraries …"
dpkg --add-architecture i386 || true
apt-get update -y
apt-get install -y \
    libc6-dev-i386 lib32ncurses-dev lib32z1-dev lib32stdc++6
wait_bar 4 "32-bit libs"
success "32-bit libraries installed."

# ── 4f: Image & graphics libraries ────────────────────────────────────────────
info "Installing image & graphics libraries …"
apt-get install -y \
    imagemagick libgl1-mesa-dev libx11-dev libsdl2-dev \
    pngcrush optipng fontconfig
wait_bar 3 "Image/graphics libs"
success "Image libraries installed."

# ── 4g: SSL, XML & network libraries ──────────────────────────────────────────
info "Installing SSL, XML & network libraries …"
apt-get install -y \
    libssl-dev openssl \
    libxml2-utils xsltproc libexpat1-dev \
    libcurl4-openssl-dev nghttp2 libnghttp2-dev \
    rsync aria2
wait_bar 3 "SSL/XML/network libs"
success "Network libraries installed."

# ── 4h: Misc build & scripting tools ──────────────────────────────────────────
info "Installing misc build & scripting tools …"
apt-get install -y \
    fakeroot dpkg-dev patchelf policycoreutils \
    policycoreutils-python-utils automake \
    python3-networkx asciidoc xmlto docbook2x \
    libxml-sax-base-perl libxml-simple-perl libswitch-perl \
    maven pwgen minicom \
    xorg-dev zlib1g-dev libz-dev gettext
wait_bar 4 "Misc build tools"
success "Misc build tools installed."

# ── 4i: Python environment ────────────────────────────────────────────────────
info "Installing Python 3 environment …"
apt-get install -y \
    python3 python3-full python3-pip python3-protobuf \
    python-is-python3 python3-venv
wait_bar 3 "Python 3 environment"
success "Python 3 environment installed."

# ── 4j: Clang, CMake, Ninja & compiler extras ─────────────────────────────────
info "Installing Clang, CMake, Ninja, and compiler extras …"
apt-get install -y \
    clang cmake ninja-build \
    libncurses-dev libncurses6 libelf-dev
wait_bar 4 "Clang / Ninja / CMake"
success "Clang, CMake, and Ninja installed."

# ── 4k: Android-specific tools ────────────────────────────────────────────────
info "Installing Android-specific tools …"
apt-get install -y \
    android-sdk-libsparse-utils erofs-utils
wait_bar 3 "Android tools"
success "Android-specific tools installed."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 5 – KVM / Virtualization
# ═════════════════════════════════════════════════════════════════════════════
header "Step 5/9 · KVM / Virtualization Support (Cuttlefish / Emulator)"

apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils cpu-checker
usermod -aG kvm     "$ACTUAL_USER"
usermod -aG libvirt "$ACTUAL_USER"
wait_bar 3 "KVM setup"
success "KVM and libvirt configured for user: $ACTUAL_USER"

# ═════════════════════════════════════════════════════════════════════════════
# STEP 6 – Flatpak & Apps
# ═════════════════════════════════════════════════════════════════════════════
header "Step 6/9 · Flatpak & Apps (Telegram, Chrome, Android Studio)"

apt-get install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

info "Installing / updating Flatpak apps from Flathub …"
flatpak install -y --or-update flathub \
    org.telegram.desktop \
    com.google.Chrome \
    com.google.AndroidStudio
flatpak update -y
wait_bar 4 "Flatpak apps"
success "Flatpak apps installed and updated."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 7 – Android SDK Environment Variables in ~/.bashrc
# ═════════════════════════════════════════════════════════════════════════════
header "Step 7/9 · AOSP Environment Variables (~/.bashrc)"

if grep -q "# --- AOSP ENV START ---" "$ACTUAL_HOME/.bashrc"; then
    info "Existing AOSP env block found – removing stale entries …"
    sed -i '/# --- AOSP ENV START ---/,/# --- AOSP ENV END ---/d' "$ACTUAL_HOME/.bashrc"
fi

cat >> "$ACTUAL_HOME/.bashrc" <<'EOL'
# --- AOSP ENV START ---
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR="${HOME}/.ccache"
export CCACHE_SIZE=100G

# Android SDK / NDK base directories
export ANDROID_HOME="${HOME}/Android/Sdk"
export ANDROID_SDK_ROOT="${HOME}/Android/Sdk"
export NDK_HOME="${ANDROID_HOME}/ndk/30.0.14904198"

# PATH – custom bin, platform-tools, cmdline-tools, build-tools, emulator
export PATH="${HOME}/.bin:${PATH}"
export PATH="${ANDROID_HOME}/platform-tools:${PATH}"
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${PATH}"
export PATH="${ANDROID_HOME}/build-tools/37.0.0:${PATH}"
export PATH="${ANDROID_HOME}/emulator:${PATH}"
# --- AOSP ENV END ---
EOL

chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bashrc"
wait_bar 2 "bashrc updated"
success "AOSP environment variables written to ~/.bashrc"

# ═════════════════════════════════════════════════════════════════════════════
# STEP 8 – git-repo Tool + Git Identity
# ═════════════════════════════════════════════════════════════════════════════
header "Step 8/9 · git-repo Tool & Git Identity"

info "Downloading latest Google git-repo …"
sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.bin"
rm -f "$ACTUAL_HOME/.bin/repo"
sudo -u "$ACTUAL_USER" curl -fsSL \
    https://storage.googleapis.com/git-repo-downloads/repo \
    -o "$ACTUAL_HOME/.bin/repo"
chmod a+rx "$ACTUAL_HOME/.bin/repo"
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bin/repo"
wait_bar 3 "git-repo downloaded"
success "git-repo installed to ~/.bin/repo"

info "Configuring Git identity …"
sudo -u "$ACTUAL_USER" git config --global user.name  "Omkar Parte"
sudo -u "$ACTUAL_USER" git config --global user.email "88646966+RAM-UNLOK@users.noreply.github.com"
sudo -u "$ACTUAL_USER" git config --global color.ui   true
success "Git identity configured."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 9 – Android udev Rules (51-android) via snowdream upstream
# ═════════════════════════════════════════════════════════════════════════════
header "Step 9/9 · Android udev Rules (51-android)"

RULES_FILE="/etc/udev/rules.d/51-android.rules"
RULES_URL="https://raw.githubusercontent.com/snowdream/51-android/refs/heads/master/51-android.rules"

info "Downloading 51-android.rules from snowdream/51-android …"
curl -fsSL "$RULES_URL" -o "$RULES_FILE"

if [[ ! -s "$RULES_FILE" ]]; then
    error "Download failed or file is empty: $RULES_FILE"
    exit 1
fi

chmod a+r "$RULES_FILE"
chown root:root "$RULES_FILE"
wait_bar 3 "udev rules installed"
success "51-android.rules installed to $RULES_FILE"

info "Reloading udev rules …"
udevadm control --reload-rules
udevadm trigger
success "udev rules reloaded."

# ═════════════════════════════════════════════════════════════════════════════
# APKTOOL – All-in-one Install
# ═════════════════════════════════════════════════════════════════════════════
header "Bonus · Apktool Installation"

INSTALL_DIR="/usr/local/bin"
APKTOOL_JAR="$INSTALL_DIR/apktool.jar"
APKTOOL_WRAPPER="$INSTALL_DIR/apktool"
APKTOOL_VERSION="3.0.2"
APKTOOL_JAR_URL="https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_${APKTOOL_VERSION}.jar"
APKTOOL_WRAPPER_URL="https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool"

info "Downloading apktool wrapper script …"
curl -fsSL "$APKTOOL_WRAPPER_URL" -o "$APKTOOL_WRAPPER"

info "Downloading apktool_${APKTOOL_VERSION}.jar from Bitbucket …"
curl -fsSL --progress-bar "$APKTOOL_JAR_URL" -o "$APKTOOL_JAR"

if [[ ! -s "$APKTOOL_JAR" ]]; then
    error "Apktool JAR download failed or file is empty."
    exit 1
fi

# Set permissions
# JAR: 644 rw-r--r--   (Java only needs read, not execute on JARs)
# Wrapper: 755 rwxr-xr-x
chown root:root "$APKTOOL_JAR"
chmod 644       "$APKTOOL_JAR"
chown root:root "$APKTOOL_WRAPPER"
chmod 755       "$APKTOOL_WRAPPER"
wait_bar 3 "Apktool installed"

INSTALLED_APKTOOL_VER="$(apktool --version 2>&1 | head -1)"
success "Apktool $INSTALLED_APKTOOL_VER is ready!"

# ═════════════════════════════════════════════════════════════════════════════
# DONE
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║         ✅  Setup Complete – All Steps Finished!         ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e " ${BOLD}What was configured:${RESET}"
echo "  ✔  Universe / Multiverse repos (if selected)"
echo "  ✔  System packages updated & upgraded"
echo "  ✔  git-core PPA (latest Git)"
echo "  ✔  AOSP build dependencies (split into sections with timers)"
echo "  ✔  KVM / libvirt for Cuttlefish & Android Emulator"
echo "  ✔  Flatpak – Telegram, Chrome, Android Studio"
echo "  ✔  AOSP SDK / NDK PATH injected into ~/.bashrc"
echo "  ✔  Google git-repo installed to ~/.bin/repo"
echo "  ✔  Git identity set"
echo "  ✔  51-android.rules downloaded from snowdream/51-android"
echo "  ✔  Apktool ${APKTOOL_VERSION} + wrapper installed to /usr/local/bin/"
echo ""
echo -e " ${CYAN}Next step:${RESET}  source ~/.bashrc  (or open a new terminal)"
echo ""
