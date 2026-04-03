#!/usr/bin/env bash
# =============================================================================
#  decode_overlays.sh
#  Fully automated Apktool framework installation and overlay APK decoding.
#
#  Everything is discovered from the dump — no manual file setup required.
#
#  What it finds automatically:
#    • framework-res.apk       (e.g. system/system/framework/framework-res.apk)
#    • framework-ext-res.apk   (e.g. system_ext/framework/framework-ext-res/framework-ext-res.apk)
#    • All *.apk files inside any "overlay" directory, at any depth
#
#  Usage:
#    chmod +x decode_overlays.sh
#    ./decode_overlays.sh [path/to/dump]
#
#  Optional argument: path to the dump root (defaults to ./dump)
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

# ── Resolve paths ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DUMP_DIR="${1:-./dump}"
DUMP_DIR="$(realpath "$DUMP_DIR")"

FRAMEWORK_DIR="$DUMP_DIR/.apktool_frameworks"   # apktool framework cache
OUTPUT_BASE="$SCRIPT_DIR/decoded_overlays"      # decoded output root

# ── Sanity checks ─────────────────────────────────────────────────────────────
header "Pre-flight checks"

if ! command -v apktool &>/dev/null; then
    error "apktool not found in PATH. Please install it first:"
    error "  https://apktool.org/docs/install"
    exit 1
fi

APKTOOL_VER="$(apktool --version 2>&1 | head -1)"
info "Using apktool: $APKTOOL_VER"

if [[ ! -d "$DUMP_DIR" ]]; then
    error "Dump folder not found: $DUMP_DIR"
    exit 1
fi

success "Dump root: $DUMP_DIR"

# ── Step 1 – Auto-discover framework APKs ────────────────────────────────────
header "Step 1 · Locating Framework APKs"

# framework-res.apk — must be installed first (pkgId 0x01).
# Typically at system/system/framework/framework-res.apk but search the whole dump.
FRAMEWORK_RES="$(find "$DUMP_DIR" \
    -not -path "$OUTPUT_BASE*" \
    -not -path "$FRAMEWORK_DIR*" \
    -type f -name "framework-res.apk" \
    | head -1)"

if [[ -z "$FRAMEWORK_RES" ]]; then
    error "Could not find framework-res.apk anywhere in: $DUMP_DIR"
    exit 1
fi
info "Found framework-res.apk  →  ${FRAMEWORK_RES#"$DUMP_DIR"/}"

# framework-ext-res.apk — optional, but common on MediaTek / MIUI devices.
FRAMEWORK_EXT="$(find "$DUMP_DIR" \
    -not -path "$OUTPUT_BASE*" \
    -not -path "$FRAMEWORK_DIR*" \
    -type f -name "framework-ext-res.apk" \
    | head -1)"

if [[ -n "$FRAMEWORK_EXT" ]]; then
    info "Found framework-ext-res.apk  →  ${FRAMEWORK_EXT#"$DUMP_DIR"/}"
else
    warn "framework-ext-res.apk not found (optional — continuing without it)."
fi

# ── Step 2 – Install frameworks into apktool ──────────────────────────────────
header "Step 2 · Installing Frameworks"

mkdir -p "$FRAMEWORK_DIR"

install_framework() {
    local file="$1"
    local label="$2"
    info "Installing $label …"
    if apktool if "$file" -p "$FRAMEWORK_DIR" 2>&1 | sed 's/^/    /'; then
        success "$label installed."
    else
        error "Failed to install $label — decoding may still work if it was cached."
    fi
}

# Order matters: framework-res.apk (0x01) before framework-ext-res.apk
install_framework "$FRAMEWORK_RES" "framework-res.apk"
[[ -n "$FRAMEWORK_EXT" ]] && install_framework "$FRAMEWORK_EXT" "framework-ext-res.apk"

# framework.jar and other *.jar files are DEX-only (no resources.arsc) — skip them.

# ── Step 3 – Discover all overlay APKs across the entire dump ─────────────────
header "Step 3 · Discovering Overlay APKs"

# Find every directory named "overlay" in the dump (any depth, any partition),
# then collect all *.apk files inside them recursively.
mapfile -t ALL_APKS < <(
    find "$DUMP_DIR" \
        -not -path "$OUTPUT_BASE*" \
        -not -path "$FRAMEWORK_DIR*" \
        -type d -name "overlay" \
    | while read -r overlay_dir; do
        find "$overlay_dir" -type f -iname "*.apk"
    done | sort -u
)

if [[ ${#ALL_APKS[@]} -eq 0 ]]; then
    warn "No overlay APKs found anywhere under: $DUMP_DIR"
    exit 0
fi

info "Found ${#ALL_APKS[@]} overlay APK(s) across all partitions:"
for apk in "${ALL_APKS[@]}"; do
    echo "  ${apk#"$DUMP_DIR"/}"
done

# ── Step 4 – Decode every overlay APK ────────────────────────────────────────
header "Step 4 · Decoding Overlay APKs"

DECODED=0
FAILED=0
SKIPPED=0

decode_apk() {
    local apk_path="$1"

    # Mirror the dump's directory structure under OUTPUT_BASE so:
    # product/overlay/MiuiFrameworkResOverlay.apk
    # → decoded_overlays/product/overlay/MiuiFrameworkResOverlay/
    #
    # product/overlay/DisplayCutoutEmulationCorner/DisplayCutoutEmulationCornerOverlay.apk
    # → decoded_overlays/product/overlay/DisplayCutoutEmulationCorner/DisplayCutoutEmulationCornerOverlay/
    #
    # mi_ext/product/overlay/GmsTelephonyOverlay.apk
    # → decoded_overlays/mi_ext/product/overlay/GmsTelephonyOverlay/
    local rel_path="${apk_path#"$DUMP_DIR"/}"
    local rel_dir
    rel_dir="$(dirname "$rel_path")"
    local apk_name
    apk_name="$(basename "$apk_path" .apk)"

    local out_dir="$OUTPUT_BASE/$rel_dir/$apk_name"

    # Skip if already decoded — delete the folder manually to force a re-decode.
    if [[ -d "$out_dir" ]]; then
        warn "Already decoded, skipping: $rel_path"
        (( SKIPPED++ )) || true
        return
    fi

    mkdir -p "$(dirname "$out_dir")"

    info "Decoding $rel_path …"

    if apktool d "$apk_path" \
        -p "$FRAMEWORK_DIR" \
        -o "$out_dir" \
        --force \
        2>&1 | sed 's/^/    /'; then
        success "Done → $out_dir"
        (( DECODED++ )) || true
    else
        error "Failed: $rel_path"
        (( FAILED++ )) || true
    fi
}

for apk in "${ALL_APKS[@]}"; do
    decode_apk "$apk"
done

# ── Summary ───────────────────────────────────────────────────────────────────
header "Summary"
echo -e "  ${GREEN}Decoded :${RESET} $DECODED"
echo -e "  ${YELLOW}Skipped :${RESET} $SKIPPED (already existed)"
echo -e "  ${RED}Failed  :${RESET} $FAILED"
echo
echo -e "  Output folder: ${BOLD}$OUTPUT_BASE${RESET}"
echo

if [[ $FAILED -gt 0 ]]; then
    error "$FAILED APK(s) failed to decode. Check output above."
    exit 1
fi

success "All done!"