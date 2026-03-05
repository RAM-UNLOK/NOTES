#!/bin/bash
# ============================================================
#  APK Zipalign + Sign Script
#  Usage: ./apk_sign.sh <input.apk> [options]
# ============================================================

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Banner ───────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║     APK  Zipalign + Sign Tool         ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# ── Usage ────────────────────────────────────────────────────
usage() {
    echo -e "${BOLD}Usage:${NC}"
    echo "  $0 <input.apk> [OPTIONS]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  --ks <keystore.jks>    Path to your existing JKS keystore"
    echo "  --ks-pass <password>   Keystore password"
    echo "  --key-alias <alias>    Key alias in the keystore"
    echo "  --key-pass <password>  Key password (defaults to --ks-pass)"
    echo "  --auto-key             Auto-generate a new keystore"
    echo "  --out <output.apk>     Output APK name (default: input_signed.apk)"
    echo "  --skip-align           Skip zipalign step"
    echo "  -h, --help             Show this help"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  # Use your own key:"
    echo "  $0 MyApp.apk --ks release.jks --ks-pass mypass --key-alias mykey"
    echo ""
    echo "  # Auto-generate a key:"
    echo "  $0 MyApp.apk --auto-key"
    echo ""
    exit 1
}

# ── Argument Parsing ─────────────────────────────────────────
INPUT_APK=""
KEYSTORE=""
KS_PASS=""
KEY_ALIAS=""
KEY_PASS=""
AUTO_KEY=false
OUTPUT_APK=""
SKIP_ALIGN=false

if [ $# -eq 0 ]; then usage; fi

INPUT_APK="$1"
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ks)        KEYSTORE="$2";   shift 2 ;;
        --ks-pass)   KS_PASS="$2";    shift 2 ;;
        --key-alias) KEY_ALIAS="$2";  shift 2 ;;
        --key-pass)  KEY_PASS="$2";   shift 2 ;;
        --auto-key)  AUTO_KEY=true;   shift   ;;
        --out)       OUTPUT_APK="$2"; shift 2 ;;
        --skip-align) SKIP_ALIGN=true; shift  ;;
        -h|--help)   usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

# ── Validate Input ───────────────────────────────────────────
if [ -z "$INPUT_APK" ]; then
    echo -e "${RED}Error: No input APK specified.${NC}"
    usage
fi

if [ ! -f "$INPUT_APK" ]; then
    echo -e "${RED}Error: File not found: $INPUT_APK${NC}"
    exit 1
fi

# ── Check Required Tools ─────────────────────────────────────
check_tool() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${RED}Error: '$1' not found. Please install Android SDK build-tools.${NC}"
        echo "  On Debian/Ubuntu: sudo apt install aapt"
        echo "  Or set your PATH to include Android SDK build-tools."
        exit 1
    fi
}

check_tool zipalign
check_tool apksigner
check_tool keytool

# ── Set Defaults ─────────────────────────────────────────────
BASENAME=$(basename "$INPUT_APK" .apk)
ALIGNED_APK="${BASENAME}_aligned.apk"
OUTPUT_APK="${OUTPUT_APK:-${BASENAME}_signed.apk}"
AUTO_KS_FILE="auto_generated_key.jks"
WORK_DIR=$(dirname "$INPUT_APK")

# ── Mode Validation ───────────────────────────────────────────
if [ "$AUTO_KEY" = false ] && [ -z "$KEYSTORE" ]; then
    echo -e "${YELLOW}No keystore specified. Use --ks <file> or --auto-key.${NC}"
    echo ""
    read -rp "$(echo -e ${CYAN}Auto-generate a keystore? [y/N]: ${NC})" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        AUTO_KEY=true
    else
        echo -e "${RED}Aborted.${NC}"
        exit 1
    fi
fi

# ── Auto-generate Keystore ────────────────────────────────────
if [ "$AUTO_KEY" = true ]; then
    echo -e "\n${CYAN}${BOLD}[ Auto-generating keystore ]${NC}"

    KS_PASS="android123"
    KEY_ALIAS="releasekey"
    KEY_PASS="android123"
    KEYSTORE="$AUTO_KS_FILE"

    if [ -f "$KEYSTORE" ]; then
        echo -e "${YELLOW}Found existing auto-generated keystore: $KEYSTORE — reusing it.${NC}"
    else
        keytool -genkeypair \
            -keystore "$KEYSTORE" \
            -alias "$KEY_ALIAS" \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -storepass "$KS_PASS" \
            -keypass "$KEY_PASS" \
            -dname "CN=Auto Generated, OU=ROM Build, O=AGC, L=Unknown, ST=Unknown, C=US" \
            2>/dev/null

        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to generate keystore.${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Keystore generated: $KEYSTORE${NC}"
        echo -e "  Alias:    ${BOLD}$KEY_ALIAS${NC}"
        echo -e "  Password: ${BOLD}$KS_PASS${NC}"
    fi
fi

# ── Validate Keystore ─────────────────────────────────────────
if [ ! -f "$KEYSTORE" ]; then
    echo -e "${RED}Error: Keystore not found: $KEYSTORE${NC}"
    exit 1
fi

# Fill key-pass default
KEY_PASS="${KEY_PASS:-$KS_PASS}"

# Prompt for missing passwords
if [ -z "$KS_PASS" ]; then
    read -rsp "$(echo -e ${CYAN}Keystore password: ${NC})" KS_PASS
    echo ""
fi
if [ -z "$KEY_ALIAS" ]; then
    read -rp "$(echo -e ${CYAN}Key alias: ${NC})" KEY_ALIAS
fi
if [ -z "$KEY_PASS" ]; then
    read -rsp "$(echo -e ${CYAN}Key password [press Enter if same as keystore]: ${NC})" KEY_PASS
    echo ""
    KEY_PASS="${KEY_PASS:-$KS_PASS}"
fi

# ── Step 1: Remove old signature (if any) ────────────────────
echo -e "\n${CYAN}${BOLD}[ Step 1/3 ] Stripping old signature...${NC}"
UNSIGNED_APK="${BASENAME}_unsigned.apk"
cp "$INPUT_APK" "$UNSIGNED_APK"

# Remove META-INF from the copy using zip
zip -d "$UNSIGNED_APK" "META-INF/*" &>/dev/null || true
echo -e "${GREEN}✓ Old signature removed (if present)${NC}"

# ── Step 2: Zipalign ─────────────────────────────────────────
if [ "$SKIP_ALIGN" = true ]; then
    echo -e "\n${YELLOW}[ Step 2/3 ] Skipping zipalign (--skip-align set)${NC}"
    ALIGNED_APK="$UNSIGNED_APK"
else
    echo -e "\n${CYAN}${BOLD}[ Step 2/3 ] Running zipalign...${NC}"
    rm -f "$ALIGNED_APK"

    zipalign -P 16 -v 4 "$UNSIGNED_APK" "$ALIGNED_APK" > /tmp/zipalign_out.txt 2>&1

    if [ $? -ne 0 ]; then
        echo -e "${RED}zipalign failed! Output:${NC}"
        cat /tmp/zipalign_out.txt
        rm -f "$UNSIGNED_APK"
        exit 1
    fi

    # Verify alignment
    zipalign -c -P 16 -v 4 "$ALIGNED_APK" > /tmp/zipalign_verify.txt 2>&1
    if grep -q "Verification successful" /tmp/zipalign_verify.txt; then
        echo -e "${GREEN}✓ Zipalign successful — all files correctly aligned${NC}"
    else
        echo -e "${RED}✗ Zipalign verification failed!${NC}"
        grep "BAD" /tmp/zipalign_verify.txt | head -20
        rm -f "$UNSIGNED_APK" "$ALIGNED_APK"
        exit 1
    fi

    rm -f "$UNSIGNED_APK"
fi

# ── Step 3: Sign ─────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}[ Step 3/3 ] Signing APK...${NC}"
rm -f "$OUTPUT_APK"

apksigner sign \
    --ks "$KEYSTORE" \
    --ks-pass "pass:$KS_PASS" \
    --ks-key-alias "$KEY_ALIAS" \
    --key-pass "pass:$KEY_PASS" \
    --out "$OUTPUT_APK" \
    "$ALIGNED_APK" 2>/tmp/sign_out.txt

if [ $? -ne 0 ]; then
    echo -e "${RED}Signing failed! Error:${NC}"
    cat /tmp/sign_out.txt
    rm -f "$ALIGNED_APK"
    exit 1
fi

# Verify signature
apksigner verify --verbose "$OUTPUT_APK" > /tmp/verify_out.txt 2>&1
if grep -q "Verified using" /tmp/verify_out.txt; then
    SCHEME=$(grep "Verified using" /tmp/verify_out.txt | head -1 | sed 's/.*: //')
    echo -e "${GREEN}✓ APK signed and verified${NC}"
    echo -e "  Signature scheme: ${BOLD}$SCHEME${NC}"
else
    echo -e "${YELLOW}⚠ Signing succeeded but verification check inconclusive.${NC}"
fi

# ── Cleanup ───────────────────────────────────────────────────
[ "$SKIP_ALIGN" = false ] && rm -f "$ALIGNED_APK"

# ── Summary ───────────────────────────────────────────────────
FILESIZE=$(du -sh "$OUTPUT_APK" | cut -f1)
echo -e "\n${GREEN}${BOLD}═══════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ Done!${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════${NC}"
echo -e "  Input APK  : ${BOLD}$INPUT_APK${NC}"
echo -e "  Output APK : ${BOLD}$OUTPUT_APK${NC} (${FILESIZE})"
echo -e "  Keystore   : ${BOLD}$KEYSTORE${NC}"
echo -e "  Key alias  : ${BOLD}$KEY_ALIAS${NC}"
if [ "$AUTO_KEY" = true ]; then
    echo -e "\n${YELLOW}  ⚠  Auto-generated key saved as: $AUTO_KS_FILE${NC}"
    echo -e "${YELLOW}     Keep this file — you need the same key for future updates!${NC}"
fi
echo ""
