#!/usr/bin/env bash
# =============================================================================
#  install_apktool.sh
#  Installs the latest Apktool on Ubuntu.
#
#  Usage:
#    chmod +x install_apktool.sh
#    sudo ./install_apktool.sh
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

# ── Must run as root ──────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
    error "Please run as root:  sudo ./install_apktool.sh"
    exit 1
fi

# ── Config ────────────────────────────────────────────────────────────────────
INSTALL_DIR="/usr/local/bin"
APKTOOL_JAR="$INSTALL_DIR/apktool.jar"
APKTOOL_WRAPPER="$INSTALL_DIR/apktool"

# ── Step 1 – Java ─────────────────────────────────────────────────────────────
header "Step 1 · Java"

if command -v java &>/dev/null; then
    JAVA_VER="$(java -version 2>&1 | head -1)"
    success "Java already installed: $JAVA_VER"
else
    info "Java not found. Installing default JRE …"
    apt-get update -qq
    apt-get install -y default-jre
    success "Default JRE installed."
fi

# Verify Java version is 8 or higher
JAVA_MAJOR="$(java -version 2>&1 | grep -oP '(?<=version ")\d+' | head -1)"
if [[ "$JAVA_MAJOR" -lt 8 ]]; then
    error "Apktool requires Java 8+. Found: Java $JAVA_MAJOR"
    exit 1
fi
info "Java version: $JAVA_MAJOR (compatible)"

# ── Step 2 – Fetch latest Apktool version ─────────────────────────────────────
header "Step 2 · Fetching Latest Apktool Version"

if ! command -v curl &>/dev/null; then
    info "Installing curl …"
    apt-get install -y curl
fi

info "Checking latest release on GitHub …"
LATEST_TAG="$(curl -fsSL "https://api.github.com/repos/iBotPeaches/Apktool/releases/latest" \
    | grep -oP '"tag_name":\s*"v?\K[^"]+' | head -1)"

if [[ -z "$LATEST_TAG" ]]; then
    error "Could not fetch latest version from GitHub. Check your internet connection."
    exit 1
fi

info "Latest version: $LATEST_TAG"
JAR_URL="https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_${LATEST_TAG}.jar"

# ── Step 3 – Download Apktool JAR ─────────────────────────────────────────────
header "Step 3 · Downloading apktool_${LATEST_TAG}.jar"

info "Downloading from Bitbucket …"
curl -fsSL --progress-bar "$JAR_URL" -o "$APKTOOL_JAR"

if [[ ! -s "$APKTOOL_JAR" ]]; then
    error "Download failed or file is empty: $APKTOOL_JAR"
    exit 1
fi

# JAR: owned by root, readable by everyone, not writable by others
# 644 = rw-r--r-- (Java doesn't need +x on JARs, just readable)
chown root:root "$APKTOOL_JAR"
chmod 644 "$APKTOOL_JAR"
success "JAR saved to: $APKTOOL_JAR  (permissions: 644 root:root)"

# ── Step 4 – Install wrapper script ───────────────────────────────────────────
header "Step 4 · Installing Wrapper Script"

cat > "$APKTOOL_WRAPPER" << 'EOF'
#!/usr/bin/env bash
exec java -jar /usr/local/bin/apktool.jar "$@"
EOF

# Wrapper: owned by root, executable by everyone, not writable by others
# 755 = rwxr-xr-x
chown root:root "$APKTOOL_WRAPPER"
chmod 755 "$APKTOOL_WRAPPER"
success "Wrapper installed to: $APKTOOL_WRAPPER  (permissions: 755 root:root)"

# ── Step 5 – Verify ───────────────────────────────────────────────────────────
header "Step 5 · Verifying Installation"

INSTALLED_VER="$(apktool --version 2>&1 | head -1)"
success "apktool $INSTALLED_VER is ready!"
echo
echo -e "  Run ${BOLD}apktool --help${RESET} to get started."
echo -e "  Or use your decode script: ${BOLD}./decode_overlays.sh${RESET}"
echo
