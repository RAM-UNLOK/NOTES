#!/usr/bin/env bash

# ==============================================================================
# Ultimate AOSP Build Environment Setup & Updater
# Target OS : Ubuntu / Kubuntu 26.04 LTS
# Target    : Android 16.x / AOSP Latest
# Hardware  : Intel i7-12700KF (20 Threads) & AMD RX 6800 XT
# Author    : Omkar Parte (Digimend Labs)
# Description: All-in-one installer – validates, updates, and configures the
#              complete AOSP build environment including Apktool, udev rules,
#              KVM, Flatpak apps, git-repo, and Android SDK paths.
# ==============================================================================

set -Eeuo pipefail   # -E ensures ERR traps are inherited by functions/subshells

# ── Colour helpers ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*" | tee -a "$LOG_FILE"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2 | tee -a "$LOG_FILE" >&2; }
header()  {
  echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}" | tee -a "$LOG_FILE"
  echo -e "${BOLD}${CYAN}║  $*${RESET}" | tee -a "$LOG_FILE"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}" | tee -a "$LOG_FILE"
}

# ── Error trap: prints file, line, function, and the failing command ───────────
_on_error() {
  local exit_code=$?
  local line_no=${BASH_LINENO[0]}
  local cmd="$BASH_COMMAND"
  local func="${FUNCNAME[1]:-main}"
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
  echo -e "${RED}[FATAL] Script aborted!${RESET}" >&2
  echo -e "${RED}  File    : ${BASH_SOURCE[1]:-$0}${RESET}" >&2
  echo -e "${RED}  Line    : $line_no${RESET}" >&2
  echo -e "${RED}  Function: $func${RESET}" >&2
  echo -e "${RED}  Command : $cmd${RESET}" >&2
  echo -e "${RED}  Exit    : $exit_code${RESET}" >&2
  echo -e "${RED}  Log     : $LOG_FILE${RESET}" >&2
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
  echo "[FATAL] line=$line_no func=$func cmd='$cmd' exit=$exit_code" >> "$LOG_FILE"
  exit "$exit_code"
}
trap '_on_error' ERR

# ── Interrupt / kill cleanup ───────────────────────────────────────────────────
trap 'echo -e "\n${YELLOW}[WARN] Interrupted by user (Ctrl+C). Exiting.${RESET}"; exit 130' INT TERM

# ── Log file setup (before any other output) ──────────────────────────────────
LOG_DIR="/var/log/aosp-setup"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup_$(date +%Y%m%d_%H%M%S).log"
echo "=== AOSP Setup Log — $(date) ===" > "$LOG_FILE"
info "Logging to: $LOG_FILE"

# ── Root check ─────────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  error "Please run with sudo: sudo bash setup_aosp_kubuntu.sh"
  exit 1
fi

ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

if [[ -z "$ACTUAL_USER" || -z "$ACTUAL_HOME" ]]; then
  error "Could not determine the actual user's home directory. Is SUDO_USER set?"
  exit 1
fi

echo -e "\n${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║    AOSP Build Environment – Ubuntu / Kubuntu 26.04 LTS  ║"
echo "  ║         All-in-one Installer • Digimend Labs             ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
info "Running as root on behalf of user: ${BOLD}$ACTUAL_USER${RESET}"
info "Home directory: $ACTUAL_HOME"

# ── Helpers ────────────────────────────────────────────────────────────────────

# wait_bar <seconds> <label>
# FIX: function was never closed in original script — all subsequent code was
#      silently inside the function body and never ran at the top level.
wait_bar() {
  local seconds="${1:-3}"
  local label="${2:-Waiting}"
  for ((i=seconds; i>0; i--)); do
    echo -ne "\r${CYAN} ⏳ ${label} … ${i}s remaining ${RESET}"
    sleep 1
  done
  echo -e "\r${GREEN} ✔ ${label} complete.                   ${RESET}"
}

# run_as_user <cmd...> — run a command as the non-root actual user
run_as_user() {
  sudo -u "$ACTUAL_USER" "$@"
}

# apt_install <packages...> — install with error details on failure
apt_install() {
  if ! apt-get install -y "$@" >> "$LOG_FILE" 2>&1; then
    error "apt-get install failed for: $*"
    error "Check $LOG_FILE for details."
    exit 1
  fi
}

# ═════════════════════════════════════════════════════════════════════════════
# STEP 1 – Optional Repository Setup
# ═════════════════════════════════════════════════════════════════════════════
header "Step 1/9 · Optional Repository Setup"

read -rp "  Enable Universe and Multiverse repositories? [y/N]: " ENABLE_REPOS
ENABLE_REPOS="${ENABLE_REPOS:-N}"

if [[ "$ENABLE_REPOS" =~ ^[Yy]$ ]]; then
  info "Enabling Universe and Multiverse …"
  add-apt-repository universe -y  >> "$LOG_FILE" 2>&1
  add-apt-repository multiverse -y >> "$LOG_FILE" 2>&1
  wait_bar 3 "Repos added"
  success "Universe and Multiverse enabled."
else
  info "Skipping Universe/Multiverse (default)."
fi

# ═════════════════════════════════════════════════════════════════════════════
# STEP 2 – System Package Update & Upgrade
# ═════════════════════════════════════════════════════════════════════════════
header "Step 2/9 · System Package Update & Upgrade"

info "Running apt-get update …"
apt-get update -y >> "$LOG_FILE" 2>&1
info "Running apt-get upgrade …"
apt-get upgrade -y >> "$LOG_FILE" 2>&1
wait_bar 5 "System packages updated"
success "System packages are up to date."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 3 – git-core PPA
# ═════════════════════════════════════════════════════════════════════════════
header "Step 3/9 · Verifying & Updating git-core PPA"

add-apt-repository ppa:git-core/ppa -y >> "$LOG_FILE" 2>&1
apt-get update -y >> "$LOG_FILE" 2>&1
wait_bar 3 "git-core PPA ready"
success "git-core PPA verified."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 4 – Build Dependencies
# ═════════════════════════════════════════════════════════════════════════════
header "Step 4/9 · Installing Build Dependencies"

# ── 4a: Core build tools (ccache installed here) ──────────────────────────────
info "Installing core build tools …"
apt_install \
  bc bison build-essential ccache curl flex \
  gnupg gperf make schedtool zip unzip \
  apt-transport-https software-properties-common wget
wait_bar 5 "Core build tools"
success "Core build tools installed."

# ── ccache configuration ───────────────────────────────────────────────────────
# FIX 1: Verify ccache binary is present before configuring
if ! command -v ccache &>/dev/null; then
  error "ccache was not found in PATH after installation. Something went wrong with apt."
  error "Try: sudo apt-get install --reinstall ccache"
  exit 1
fi

# FIX 2: Create the ccache directory as the actual user, with correct ownership.
#         Previously, ccache -M was called as root with no CCACHE_DIR set,
#         which wrote config to /root/.cache/ccache — NOT the build user's dir.
CCACHE_USER_DIR="$ACTUAL_HOME/.ccache"
info "Creating ccache directory: $CCACHE_USER_DIR"
run_as_user mkdir -p "$CCACHE_USER_DIR"

# FIX 3: Run ccache -M as the actual build user, pointing at their CCACHE_DIR,
#         so the max_size is written to the correct user's ccache.conf.
info "Setting ccache max size to 50G for user $ACTUAL_USER …"
if ! CCACHE_DIR="$CCACHE_USER_DIR" run_as_user ccache -M 50G >> "$LOG_FILE" 2>&1; then
  error "ccache -M 50G failed. Check $LOG_FILE for details."
  exit 1
fi

# Verify the setting was applied
CCACHE_MAX_APPLIED=$(CCACHE_DIR="$CCACHE_USER_DIR" run_as_user ccache -p 2>/dev/null \
  | grep -E "^(max_size|cache_size_threshold)" | head -1 || true)
success "ccache configured → $(CCACHE_DIR="$CCACHE_USER_DIR" run_as_user ccache -p 2>/dev/null | grep max_size | head -1)"
info "ccache binary: $(command -v ccache)  version: $(ccache --version | head -1)"

# ── 4b: Git & version control ─────────────────────────────────────────────────
info "Installing git, git-lfs …"
apt_install git git-lfs
wait_bar 3 "Git tools"
success "Git and git-lfs installed."

# ── 4c: Java (JDK / JRE) ──────────────────────────────────────────────────────
info "Installing default JDK / JRE …"
apt_install default-jre default-jdk
wait_bar 5 "Java JDK/JRE"
success "Java installed."

JAVA_MAJOR="$(java -version 2>&1 | grep -oP '(?<=version ")\d+' | head -1)"
if [[ -z "$JAVA_MAJOR" ]]; then
  error "Could not determine Java version. 'java' may not be in PATH."
  exit 1
fi
if [[ "$JAVA_MAJOR" -lt 8 ]]; then
  error "Apktool and AOSP require Java 8+. Found Java $JAVA_MAJOR. Aborting."
  exit 1
fi
success "Java version: $JAVA_MAJOR (compatible ✔)"

# ── 4d: Compression & archive libraries ───────────────────────────────────────
info "Installing compression & archive libraries …"
apt_install \
  bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev brotli \
  lz4 lzop liblzma-dev squashfs-tools \
  p7zip-full 7zip unrar-free sharutils uudeview mpack arj cabextract rename
wait_bar 4 "Compression & archive libs"
success "Compression libraries installed."

# ── 4e: 32-bit & multi-arch libraries ─────────────────────────────────────────
info "Installing 32-bit & multi-arch libraries …"
dpkg --add-architecture i386 || true
apt-get update -y >> "$LOG_FILE" 2>&1
apt_install libc6-dev-i386 lib32ncurses-dev lib32z1-dev lib32stdc++6
wait_bar 4 "32-bit libs"
success "32-bit libraries installed."

# ── 4f: Image & graphics libraries ────────────────────────────────────────────
info "Installing image & graphics libraries …"
apt_install \
  imagemagick libgl1-mesa-dev libx11-dev libsdl2-dev \
  pngcrush optipng fontconfig
wait_bar 3 "Image/graphics libs"
success "Image libraries installed."

# ── 4g: SSL, XML & network libraries ──────────────────────────────────────────
info "Installing SSL, XML & network libraries …"
apt_install \
  libssl-dev openssl \
  libxml2-utils xsltproc libexpat1-dev \
  libcurl4-openssl-dev nghttp2 libnghttp2-dev \
  rsync aria2
wait_bar 3 "SSL/XML/network libs"
success "Network libraries installed."

# ── 4h: Misc build & scripting tools ──────────────────────────────────────────
info "Installing misc build & scripting tools …"
apt_install \
  fakeroot dpkg-dev patchelf policycoreutils \
  policycoreutils-python-utils automake \
  python3-networkx asciidoc xmlto docbook2x \
  libxml-sax-base-perl libxml-simple-perl libswitch-perl \
  maven pwgen minicom \
  xorg-dev zlib1g-dev gettext
wait_bar 4 "Misc build tools"
success "Misc build tools installed."

# ── 4i: Python environment ────────────────────────────────────────────────────
info "Installing Python 3 environment …"
apt_install \
  python3 python3-full python3-pip python3-protobuf \
  python-is-python3 python3-venv
wait_bar 3 "Python 3 environment"
success "Python 3 environment installed."

# ── 4j: Clang, CMake, Ninja & compiler extras ─────────────────────────────────
info "Installing Clang, CMake, Ninja, and compiler extras …"
apt_install \
  clang cmake ninja-build \
  libncurses-dev libncurses6 libelf-dev
wait_bar 4 "Clang / Ninja / CMake"
success "Clang, CMake, and Ninja installed."

# ── 4k: Android-specific tools ────────────────────────────────────────────────
info "Installing Android-specific tools …"
apt_install android-sdk-libsparse-utils erofs-utils
wait_bar 3 "Android tools"
success "Android-specific tools installed."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 5 – KVM / Virtualization
# ═════════════════════════════════════════════════════════════════════════════
header "Step 5/9 · KVM / Virtualization Support (Cuttlefish / Emulator)"

# qemu-kvm is a virtual package on Ubuntu 26.04 — auto-detect the real provider
if apt-cache show qemu-system-x86-hwe &>/dev/null 2>&1; then
  QEMU_PKG="qemu-system-x86-hwe"
elif apt-cache show qemu-system-x86 &>/dev/null 2>&1; then
  QEMU_PKG="qemu-system-x86"
else
  error "Neither qemu-system-x86-hwe nor qemu-system-x86 found. Check your apt sources."
  exit 1
fi
info "Using QEMU package: $QEMU_PKG"
apt_install "$QEMU_PKG" libvirt-daemon-system libvirt-clients bridge-utils cpu-checker virtinst
usermod -aG kvm     "$ACTUAL_USER"
usermod -aG libvirt "$ACTUAL_USER"
wait_bar 3 "KVM setup"
success "KVM and libvirt configured for user: $ACTUAL_USER"

# ═════════════════════════════════════════════════════════════════════════════
# STEP 6 – Flatpak & Apps
# ═════════════════════════════════════════════════════════════════════════════
header "Step 6/9 · Flatpak & Apps (Telegram, Chrome, Android Studio)"

apt_install flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1

info "Installing / updating Flatpak apps from Flathub …"
flatpak install -y --or-update flathub \
  org.telegram.desktop \
  com.google.Chrome \
  com.google.AndroidStudio >> "$LOG_FILE" 2>&1
flatpak update -y >> "$LOG_FILE" 2>&1
wait_bar 4 "Flatpak apps"
success "Flatpak apps installed and updated."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 7 – Android SDK Environment Variables in ~/.bashrc
# ═════════════════════════════════════════════════════════════════════════════
header "Step 7/9 · AOSP Environment Variables (~/.bashrc)"

BASHRC_FILE="$ACTUAL_HOME/.bashrc"

if grep -q "# --- AOSP ENV START ---" "$BASHRC_FILE" 2>/dev/null; then
  info "Existing AOSP env block found – removing stale entries …"
  sed -i '/# --- AOSP ENV START ---/,/# --- AOSP ENV END ---/d' "$BASHRC_FILE"
fi

# FIX 4: Use CCACHE_MAXSIZE (the correct env var, not CCACHE_SIZE).
#         CCACHE_SIZE is not a recognised ccache variable — it is silently
#         ignored at build time. CCACHE_MAXSIZE is the correct override.
cat >> "$BASHRC_FILE" <<'EOL'
# --- AOSP ENV START ---
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR="${HOME}/.ccache"
export CCACHE_MAXSIZE=50G          # Correct env var (not CCACHE_SIZE)

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

# ccache compiler symlinks (speeds up detection by AOSP build system)
export PATH="/usr/lib/ccache:$PATH"
# --- AOSP ENV END ---
EOL

chown "$ACTUAL_USER:$ACTUAL_USER" "$BASHRC_FILE"
wait_bar 2 "bashrc updated"
success "AOSP environment variables written to ~/.bashrc"

# ═════════════════════════════════════════════════════════════════════════════
# STEP 8 – git-repo Tool + Git Identity
# ═════════════════════════════════════════════════════════════════════════════
header "Step 8/9 · git-repo Tool & Git Identity"

info "Downloading latest Google git-repo …"
run_as_user mkdir -p "$ACTUAL_HOME/.bin"
rm -f "$ACTUAL_HOME/.bin/repo"

REPO_URL="https://storage.googleapis.com/git-repo-downloads/repo"
if ! run_as_user curl -fsSL "$REPO_URL" -o "$ACTUAL_HOME/.bin/repo" >> "$LOG_FILE" 2>&1; then
  error "Failed to download git-repo from: $REPO_URL"
  error "Check network connectivity and retry."
  exit 1
fi
if [[ ! -s "$ACTUAL_HOME/.bin/repo" ]]; then
  error "git-repo download produced an empty file. Aborting."
  exit 1
fi

chmod a+rx "$ACTUAL_HOME/.bin/repo"
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.bin/repo"
wait_bar 3 "git-repo downloaded"
success "git-repo installed to ~/.bin/repo"

info "Configuring Git identity …"
run_as_user git config --global user.name  "Omkar Parte"
run_as_user git config --global user.email "88646966+RAM-UNLOK@users.noreply.github.com"
run_as_user git config --global color.ui   true
success "Git identity configured."

# ═════════════════════════════════════════════════════════════════════════════
# STEP 9 – Android udev Rules (51-android) via snowdream upstream
# ═════════════════════════════════════════════════════════════════════════════
header "Step 9/9 · Android udev Rules (51-android)"

RULES_FILE="/etc/udev/rules.d/51-android.rules"
RULES_URL="https://raw.githubusercontent.com/snowdream/51-android/refs/heads/master/51-android.rules"

info "Downloading 51-android.rules from snowdream/51-android …"
if ! curl -fsSL "$RULES_URL" -o "$RULES_FILE" >> "$LOG_FILE" 2>&1; then
  error "Download of 51-android.rules failed."
  error "URL: $RULES_URL"
  error "Check your internet connection or the URL."
  exit 1
fi

if [[ ! -s "$RULES_FILE" ]]; then
  error "Downloaded rules file is empty: $RULES_FILE"
  exit 1
fi

chmod a+r "$RULES_FILE"
chown root:root "$RULES_FILE"
wait_bar 3 "udev rules installed"
success "51-android.rules installed to $RULES_FILE"

info "Reloading udev rules …"
if ! udevadm control --reload-rules; then
  warn "udevadm --reload-rules failed. You may need to reboot for udev rules to take effect."
fi
udevadm trigger || warn "udevadm trigger failed — not critical, rules will apply after reboot."
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
if ! curl -fsSL "$APKTOOL_WRAPPER_URL" -o "$APKTOOL_WRAPPER" >> "$LOG_FILE" 2>&1; then
  error "Failed to download Apktool wrapper from: $APKTOOL_WRAPPER_URL"
  exit 1
fi

info "Downloading apktool_${APKTOOL_VERSION}.jar from Bitbucket …"
if ! curl -fsSL --progress-bar "$APKTOOL_JAR_URL" -o "$APKTOOL_JAR"; then
  error "Failed to download Apktool JAR from: $APKTOOL_JAR_URL"
  error "Verify the version $APKTOOL_VERSION exists at:"
  error "  https://bitbucket.org/iBotPeaches/apktool/downloads/"
  exit 1
fi

if [[ ! -s "$APKTOOL_JAR" ]]; then
  error "Apktool JAR download produced an empty file. Aborting."
  exit 1
fi

# JAR: 644 rw-r--r-- (only read needed by Java)
# Wrapper: 755 rwxr-xr-x
chown root:root "$APKTOOL_JAR"    && chmod 644 "$APKTOOL_JAR"
chown root:root "$APKTOOL_WRAPPER" && chmod 755 "$APKTOOL_WRAPPER"
wait_bar 3 "Apktool installed"

INSTALLED_APKTOOL_VER="$(apktool --version 2>&1 | head -1)"
success "Apktool $INSTALLED_APKTOOL_VER is ready!"

# ═════════════════════════════════════════════════════════════════════════════
# DONE
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║       ✅  Setup Complete – All Steps Finished!          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${BOLD}What was configured:${RESET}"
echo "   ✔  Universe / Multiverse repos (if selected)"
echo "   ✔  System packages updated & upgraded"
echo "   ✔  git-core PPA (latest Git)"
echo "   ✔  AOSP build dependencies (split into sections with timers)"
echo "   ✔  ccache → max 50G at $CCACHE_USER_DIR (owned by $ACTUAL_USER)"
echo "   ✔  KVM / libvirt for Cuttlefish & Android Emulator"
echo "   ✔  Flatpak – Telegram, Chrome, Android Studio"
echo "   ✔  AOSP SDK / NDK PATH + CCACHE_MAXSIZE injected into ~/.bashrc"
echo "   ✔  Google git-repo installed to ~/.bin/repo"
echo "   ✔  Git identity set"
echo "   ✔  51-android.rules downloaded from snowdream/51-android"
echo "   ✔  Apktool ${APKTOOL_VERSION} + wrapper installed to /usr/local/bin/"
echo ""
echo -e "  ${CYAN}Next step:${RESET}  source ~/.bashrc   (or open a new terminal)"
echo -e "  ${CYAN}Full log :${RESET}  $LOG_FILE"
echo ""
