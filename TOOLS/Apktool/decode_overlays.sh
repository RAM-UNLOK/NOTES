#!/usr/bin/env bash
# =============================================================================
#  decode_overlays.sh
#  Automates Apktool framework installation and overlay APK decoding.
#
#  Folder structure expected:
#    overlaytodecode/
#      framework-res.apk
#      framework-ext-res.apk
#      framework.jar
#      product/overlay/*.apk
#      vendor/overlay/*.apk
#
#  Usage:
#    chmod +x decode_overlays.sh
#    ./decode_overlays.sh [path/to/overlaytodecode]
#
#  Optional argument: path to the root folder (defaults to ./overlaytodecode)
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
ROOT_DIR="${1:-./overlaytodecode}"
ROOT_DIR="$(realpath "$ROOT_DIR")"

FRAMEWORK_DIR="$ROOT_DIR/frameworks"          # where apktool stores installed frameworks
OUTPUT_BASE="$ROOT_DIR/decoded"               # where decoded APKs will land

# ── Sanity checks ─────────────────────────────────────────────────────────────
header "Pre-flight checks"

if ! command -v apktool &>/dev/null; then
    error "apktool not found in PATH. Please install it first:"
    error "  https://apktool.org/docs/install"
    exit 1
fi

APKTOOL_VER="$(apktool --version 2>&1 | head -1)"
info "Using apktool: $APKTOOL_VER"

if [[ ! -d "$ROOT_DIR" ]]; then
    error "Root folder not found: $ROOT_DIR"
    exit 1
fi

# Check for required framework files
FRAMEWORK_RES="$ROOT_DIR/framework-res.apk"
FRAMEWORK_EXT="$ROOT_DIR/framework-ext-res.apk"
# framework.jar is a code-only DEX library (no resources.arsc) — not installable as a framework

[[ -f "$FRAMEWORK_RES" ]] || { error "Missing: $FRAMEWORK_RES"; exit 1; }
[[ -f "$FRAMEWORK_EXT" ]] || warn "Not found (optional): $FRAMEWORK_EXT"

success "Root folder: $ROOT_DIR"

# ── Create output directories ─────────────────────────────────────────────────
mkdir -p "$FRAMEWORK_DIR"
mkdir -p "$OUTPUT_BASE/product"
mkdir -p "$OUTPUT_BASE/vendor"

# ── Step 1 – Install frameworks ───────────────────────────────────────────────
header "Step 1 · Installing Frameworks"

install_framework() {
    local file="$1"
    local label="$2"
    if [[ -f "$file" ]]; then
        info "Installing $label …"
        apktool if "$file" -p "$FRAMEWORK_DIR"
        success "$label installed."
    else
        warn "Skipping $label (file not found)."
    fi
}

# Order matters — framework-res.apk (pkgId 0x01) must come first
install_framework "$FRAMEWORK_RES" "framework-res.apk"
install_framework "$FRAMEWORK_EXT" "framework-ext-res.apk"
# framework.jar is skipped — it's a DEX library with no resources.arsc

# ── Step 2 – Decode overlay APKs ─────────────────────────────────────────────
header "Step 2 · Decoding Overlay APKs"

DECODED=0
FAILED=0
SKIPPED=0

decode_apk() {
    local apk_path="$1"
    local out_subdir="$2"   # "product" or "vendor"

    local apk_name
    apk_name="$(basename "$apk_path" .apk)"   # strip .apk for the output folder name

    local out_dir="$OUTPUT_BASE/$out_subdir/$apk_name"

    # Skip if already decoded (remove folder manually to re-decode)
    if [[ -d "$out_dir" ]]; then
        warn "Already decoded, skipping: $apk_name  →  $out_dir"
        (( SKIPPED++ )) || true
        return
    fi

    info "Decoding [$out_subdir] $apk_name …"

    if apktool d "$apk_path" \
            -p "$FRAMEWORK_DIR" \
            -o "$out_dir" \
            --force \
            2>&1 | sed 's/^/    /'; then
        success "Done → $out_dir"
        (( DECODED++ )) || true
    else
        error "Failed to decode: $apk_path"
        (( FAILED++ )) || true
    fi
}

# Decode product overlays
PRODUCT_DIR="$ROOT_DIR/product/overlay"
if [[ -d "$PRODUCT_DIR" ]]; then
    mapfile -t PRODUCT_APKS < <(find "$PRODUCT_DIR" -maxdepth 1 -iname "*.apk" | sort)
    if [[ ${#PRODUCT_APKS[@]} -eq 0 ]]; then
        warn "No APKs found in: $PRODUCT_DIR"
    else
        info "Found ${#PRODUCT_APKS[@]} APK(s) in product/overlay"
        for apk in "${PRODUCT_APKS[@]}"; do
            decode_apk "$apk" "product"
        done
    fi
else
    warn "product/overlay folder not found, skipping."
fi

# Decode vendor overlays
VENDOR_DIR="$ROOT_DIR/vendor/overlay"
if [[ -d "$VENDOR_DIR" ]]; then
    mapfile -t VENDOR_APKS < <(find "$VENDOR_DIR" -maxdepth 1 -iname "*.apk" | sort)
    if [[ ${#VENDOR_APKS[@]} -eq 0 ]]; then
        warn "No APKs found in: $VENDOR_DIR"
    else
        info "Found ${#VENDOR_APKS[@]} APK(s) in vendor/overlay"
        for apk in "${VENDOR_APKS[@]}"; do
            decode_apk "$apk" "vendor"
        done
    fi
else
    warn "vendor/overlay folder not found, skipping."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
header "Summary"
echo -e "  ${GREEN}Decoded :${RESET}  $DECODED"
echo -e "  ${YELLOW}Skipped :${RESET}  $SKIPPED  (already existed)"
echo -e "  ${RED}Failed  :${RESET}  $FAILED"
echo
echo -e "  Output folder: ${BOLD}$OUTPUT_BASE${RESET}"
echo

if [[ $FAILED -gt 0 ]]; then
    error "$FAILED APK(s) failed to decode. Check output above."
    exit 1
fi

success "All done!"
