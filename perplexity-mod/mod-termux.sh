#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Perplexity Premium Patcher — Termux (Android) version
# ============================================================
#
# SETUP (run once):
#   pkg update && pkg upgrade
#   pkg install openjdk-17 wget unzip zip sed grep
#   pip install apktool       # or install manually below
#
# If apktool isn't in pip:
#   wget https://raw.githubusercontent.com/nicechute/apktool/master/scripts/linux/apktool
#   wget https://bitbucket.org/nicechute/apktool/downloads/apktool_2.9.3.jar -O apktool.jar
#   chmod +x apktool
#   mv apktool apktool.jar $PREFIX/bin/
#
# USAGE:
#   termux-setup-storage        # grant storage access (run once)
#   chmod +x mod-termux.sh
#   ./mod-termux.sh ~/storage/downloads/Perplexity.xapk
#
# ============================================================

set -e

# ── Colors ──
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
RST='\033[0m'

banner() { echo -e "\n${CYN}[$1/8]${RST} $2"; }
ok()     { echo -e "  ${GRN}✓${RST} $1"; }
warn()   { echo -e "  ${YLW}⚠${RST} $1"; }
fail()   { echo -e "  ${RED}✗${RST} $1"; exit 1; }

# ── Check dependencies ──
check_deps() {
  local missing=()
  command -v java    &>/dev/null || missing+=(openjdk-17)
  command -v unzip   &>/dev/null || missing+=(unzip)
  command -v zip     &>/dev/null || missing+=(zip)
  command -v sed     &>/dev/null || missing+=(sed)
  command -v grep    &>/dev/null || missing+=(grep)
  command -v apktool &>/dev/null || missing+=(apktool)

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}Missing packages: ${missing[*]}${RST}"
    echo ""
    echo "Run this to install everything:"
    echo -e "${CYN}  pkg update && pkg install openjdk-17 wget unzip zip${RST}"
    echo ""
    echo "For apktool, download manually:"
    echo -e "${CYN}  wget https://raw.githubusercontent.com/nicechute/apktool/master/scripts/linux/apktool -O \$PREFIX/bin/apktool${RST}"
    echo -e "${CYN}  wget https://bitbucket.org/nicechute/apktool/downloads/apktool_2.9.3.jar -O \$PREFIX/bin/apktool.jar${RST}"
    echo -e "${CYN}  chmod +x \$PREFIX/bin/apktool${RST}"
    exit 1
  fi
  ok "All dependencies found"
}

# ── Input ──
XAPK="$1"
if [ -z "$XAPK" ]; then
  echo -e "${CYN}Perplexity Premium Patcher — Termux Edition${RST}"
  echo ""
  echo "Usage: ./mod-termux.sh /path/to/Perplexity.xapk"
  echo ""
  echo "Common paths:"
  echo "  ~/storage/downloads/Perplexity.xapk"
  echo "  ~/storage/shared/Download/Perplexity.xapk"
  echo ""
  echo "Run 'termux-setup-storage' first if you haven't."
  exit 1
fi

if [ ! -f "$XAPK" ]; then
  fail "File not found: $XAPK"
fi

echo -e "${CYN}╔══════════════════════════════════════╗${RST}"
echo -e "${CYN}║  Perplexity Premium Patcher v1.0     ║${RST}"
echo -e "${CYN}║  Termux Edition                      ║${RST}"
echo -e "${CYN}╚══════════════════════════════════════╝${RST}"
echo ""

WORKDIR="$HOME/perplexity-mod"
OUTDIR="$HOME/storage/downloads"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

banner 1 "Checking dependencies..."
check_deps

# ── Step 2: Extract XAPK ──
banner 2 "Extracting XAPK..."
unzip -o "$XAPK" -d "$WORKDIR/xapk" > /dev/null 2>&1
ok "Extracted to $WORKDIR/xapk"

# Find base APK (skip config/split APKs)
BASE_APK=""
for apk in "$WORKDIR/xapk/"*.apk; do
  name=$(basename "$apk")
  case "$name" in
    config.* | split_*) continue ;;
    *) BASE_APK="$apk"; break ;;
  esac
done

if [ -z "$BASE_APK" ]; then
  BASE_APK=$(find "$WORKDIR/xapk" -name "*.apk" | head -1)
fi

if [ -z "$BASE_APK" ]; then
  fail "No APK found inside the XAPK"
fi
ok "Base APK: $(basename "$BASE_APK") ($(du -sh "$BASE_APK" | cut -f1))"

# Save split APKs for later
SPLITS=()
for apk in "$WORKDIR/xapk/"*.apk; do
  [ "$apk" = "$BASE_APK" ] && continue
  SPLITS+=("$apk")
done
if [ ${#SPLITS[@]} -gt 0 ]; then
  ok "Found ${#SPLITS[@]} split APK(s)"
fi

# ── Step 3: Decompile ──
banner 3 "Decompiling (this takes a minute on phone)..."
apktool d "$BASE_APK" -o "$WORKDIR/dec" -f --no-res 2>/dev/null || \
apktool d "$BASE_APK" -o "$WORKDIR/dec" -f 2>/dev/null
ok "Decompiled"

# ── Step 4: Scan for premium checks ──
banner 4 "Scanning for premium gates..."

SCAN_DIR="$WORKDIR/dec/smali"
[ -d "$WORKDIR/dec/smali_classes2" ] && SCAN_DIR="$WORKDIR/dec/smali*"

FOUND=0

echo -e "\n  ${YLW}── Premium/Subscription Booleans ──${RST}"
HITS=$(grep -rn "isPremium\|isPro\|isSubscribed\|hasPremium\|hasSubscription\|isFreeTier\|isFreeUser\|isPayingUser\|canAccessPro" \
  $SCAN_DIR/ 2>/dev/null | wc -l)
echo -e "  Found: ${GRN}$HITS${RST} locations"
FOUND=$((FOUND + HITS))

echo -e "\n  ${YLW}── Feature Gates ──${RST}"
HITS=$(grep -rn "feature_gate\|FeatureGate\|isFeatureEnabled\|isGated\|pro_feature\|premium_feature" \
  $SCAN_DIR/ 2>/dev/null | wc -l)
echo -e "  Found: ${GRN}$HITS${RST} locations"
FOUND=$((FOUND + HITS))

echo -e "\n  ${YLW}── Paywall / Upgrade UI ──${RST}"
HITS=$(grep -rn "paywall\|Paywall\|showUpgrade\|showPaywall\|UpgradePrompt\|SubscriptionScreen\|upsell\|Upsell" \
  $SCAN_DIR/ 2>/dev/null | wc -l)
echo -e "  Found: ${GRN}$HITS${RST} locations"
FOUND=$((FOUND + HITS))

echo -e "\n  ${YLW}── Rate / Query Limits ──${RST}"
HITS=$(grep -rn "rateLimit\|rate_limit\|queryLimit\|dailyLimit\|remainingQueries\|freeQueries\|maxQueries" \
  $SCAN_DIR/ 2>/dev/null | wc -l)
echo -e "  Found: ${GRN}$HITS${RST} locations"
FOUND=$((FOUND + HITS))

echo -e "\n  ${YLW}── Billing / Purchases ──${RST}"
HITS=$(grep -rn "BillingClient\|queryPurchases\|acknowledgePurchase\|getPurchaseState\|ProductDetails" \
  $SCAN_DIR/ 2>/dev/null | wc -l)
echo -e "  Found: ${GRN}$HITS${RST} locations"
FOUND=$((FOUND + HITS))

echo ""
ok "Total scan hits: $FOUND"

# ── Step 5: Patch ──
banner 5 "Patching smali..."

PATCHED=0
find $SCAN_DIR/ -name "*.smali" -type f | while IFS= read -r smali; do
  sed -i -E '
    /\.method.*isPremium\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x0/const\/4 v0, 0x1/
    }
    /\.method.*isPro\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x0/const\/4 v0, 0x1/
    }
    /\.method.*isSubscribed\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x0/const\/4 v0, 0x1/
    }
    /\.method.*hasPremium\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x0/const\/4 v0, 0x1/
    }
    /\.method.*hasSubscription\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x0/const\/4 v0, 0x1/
    }
    /\.method.*isPayingUser\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x0/const\/4 v0, 0x1/
    }
    /\.method.*canAccessPro\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x0/const\/4 v0, 0x1/
    }
    /\.method.*isFreeTier\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x1/const\/4 v0, 0x0/
    }
    /\.method.*isFreeUser\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x1/const\/4 v0, 0x0/
    }
    /\.method.*isFeatureEnabled\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x0/const\/4 v0, 0x1/
    }
    /\.method.*isGated\(\)Z/,/\.end method/ {
      s/const\/4 v0, 0x1/const\/4 v0, 0x0/
    }
  ' "$smali" 2>/dev/null
done

# Remove paywall invocations
find $SCAN_DIR/ -name "*.smali" -type f | while IFS= read -r smali; do
  sed -i -E '
    /invoke.*showPaywall/s/^/#/
    /invoke.*showUpgrade/s/^/#/
    /invoke.*[Uu]psell/s/^/#/
  ' "$smali" 2>/dev/null
done

ok "Premium booleans flipped"
ok "Free-tier checks inverted"
ok "Feature gates unlocked"
ok "Paywall dialogs removed"

# ── Step 6: Rebuild ──
banner 6 "Rebuilding APK (patience, phones are slow)..."
apktool b "$WORKDIR/dec" -o "$WORKDIR/patched.apk" 2>/dev/null
ok "Built: patched.apk"

# ── Step 7: Sign ──
banner 7 "Signing..."

KEYSTORE="$WORKDIR/mod.keystore"
keytool -genkeypair -v -keystore "$KEYSTORE" -alias mod \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass modpass -keypass modpass \
  -dname "CN=Mod,OU=Mod,O=Mod,L=Mod,ST=Mod,C=US" 2>/dev/null

if command -v apksigner &>/dev/null; then
  apksigner sign --ks "$KEYSTORE" --ks-pass pass:modpass \
    --out "$WORKDIR/perplexity-premium.apk" "$WORKDIR/patched.apk"
else
  jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
    -keystore "$KEYSTORE" -storepass modpass \
    "$WORKDIR/patched.apk" mod 2>/dev/null
  mv "$WORKDIR/patched.apk" "$WORKDIR/perplexity-premium.apk"
fi
ok "Signed"

# ── Step 8: Copy to Downloads ──
banner 8 "Finishing up..."

if [ -d "$OUTDIR" ]; then
  cp "$WORKDIR/perplexity-premium.apk" "$OUTDIR/Perplexity-Premium-Modded.apk"
  ok "Copied to Downloads"
  FINAL="$OUTDIR/Perplexity-Premium-Modded.apk"
else
  FINAL="$WORKDIR/perplexity-premium.apk"
  warn "No Downloads folder found, APK is at: $FINAL"
fi

# Copy splits if they exist
if [ ${#SPLITS[@]} -gt 0 ]; then
  mkdir -p "$WORKDIR/install-bundle"
  cp "$WORKDIR/perplexity-premium.apk" "$WORKDIR/install-bundle/"
  for s in "${SPLITS[@]}"; do
    cp "$s" "$WORKDIR/install-bundle/"
  done
  ok "Split APKs bundled in $WORKDIR/install-bundle/"
fi

echo ""
echo -e "${GRN}╔══════════════════════════════════════╗${RST}"
echo -e "${GRN}║            DONE                      ║${RST}"
echo -e "${GRN}╚══════════════════════════════════════╝${RST}"
echo ""
echo -e "  Modded APK: ${CYN}$FINAL${RST}"
echo -e "  Size: $(du -sh "$FINAL" | cut -f1)"
echo ""
echo -e "  ${YLW}To install:${RST}"
echo "  1. Uninstall original Perplexity first"
echo "  2. Open your file manager → Downloads"
echo "  3. Tap Perplexity-Premium-Modded.apk"
echo "  4. Allow 'Install from unknown sources' if prompted"
echo ""

if [ ${#SPLITS[@]} -gt 0 ]; then
  echo -e "  ${YLW}If app crashes (missing splits), install all APKs:${RST}"
  echo "  adb install-multiple $WORKDIR/install-bundle/*.apk"
  echo "  OR use SAI (Split APKs Installer) from Play Store"
  echo ""
fi

echo -e "  ${YLW}Note:${RST} Pro Search (GPT-4/Claude models) is server-verified."
echo "  Client-side unlocks (UI, features, ads, nags) will work."
echo ""

# Cleanup decompiled to save space
rm -rf "$WORKDIR/dec" "$WORKDIR/xapk"
ok "Cleaned up temp files"
