#!/bin/bash
# ============================================================
# Perplexity Premium Patcher — local modding script
# Run this on your own machine (Windows WSL / macOS / Linux)
# ============================================================
# Prerequisites:
#   - Java 8+ (for apktool / uber-apk-signer)
#   - apktool: https://apktool.org/docs/install
#   - uber-apk-signer: https://github.com/nicechute/uber-apk-signer (or any APK signer)
#   - unzip, zip, grep, sed
# ============================================================

set -e

XAPK="$1"
if [ -z "$XAPK" ]; then
  echo "Usage: ./mod.sh path/to/Perplexity.xapk"
  exit 1
fi

WORKDIR="perplexity-mod-work"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# ── Step 1: Extract the XAPK (it's a zip) ──
echo "[1/7] Extracting XAPK..."
unzip -o "$XAPK" -d "$WORKDIR/xapk-contents"

# Find the base APK
BASE_APK=$(find "$WORKDIR/xapk-contents" -name "*.apk" -not -name "config.*" -not -name "split_*" | head -1)
if [ -z "$BASE_APK" ]; then
  # Some XAPKs name it differently
  BASE_APK=$(find "$WORKDIR/xapk-contents" -name "*.apk" | head -1)
fi
echo "    Base APK: $BASE_APK"

# ── Step 2: Decompile with apktool ──
echo "[2/7] Decompiling APK..."
apktool d "$BASE_APK" -o "$WORKDIR/decompiled" -f

# ── Step 3: Find all premium/subscription check points ──
echo "[3/7] Scanning for premium gates..."
echo ""
echo "=== SUBSCRIPTION CHECK LOCATIONS ==="

# Common patterns in Perplexity's smali:
# - Subscription status fields
# - isPremium / isPro / isSubscribed methods
# - BillingClient / Purchase verification
# - Feature flag checks
# - Paywall UI triggers

grep -rn "isPremium\|isPro\|isSubscribed\|isFreeTier\|isFreeUser\|hasPremium\|hasSubscription\|premiumStatus\|subscriptionStatus\|isPayingUser\|canAccessPro" \
  "$WORKDIR/decompiled/smali*/" 2>/dev/null | tee "$WORKDIR/premium-checks.txt" || true

echo ""
echo "=== BILLING / PURCHASE VERIFICATION ==="
grep -rn "BillingClient\|PurchasesUpdatedListener\|queryPurchases\|acknowledgePurchase\|BillingFlowParams\|SkuDetails\|ProductDetails\|isAcknowledged\|getPurchaseState" \
  "$WORKDIR/decompiled/smali*/" 2>/dev/null | tee -a "$WORKDIR/billing-checks.txt" || true

echo ""
echo "=== FEATURE FLAGS / GATES ==="
grep -rn "feature_gate\|feature_flag\|FeatureGate\|FeatureFlag\|isFeatureEnabled\|checkFeature\|gatekeeper\|isGated\|pro_feature\|premium_feature" \
  "$WORKDIR/decompiled/smali*/" 2>/dev/null | tee "$WORKDIR/feature-flags.txt" || true

echo ""
echo "=== PAYWALL / UPGRADE UI ==="
grep -rn "paywall\|Paywall\|upgrade_prompt\|UpgradePrompt\|showUpgrade\|showPaywall\|SubscriptionScreen\|PricingScreen\|upsell\|Upsell" \
  "$WORKDIR/decompiled/smali*/" 2>/dev/null | tee "$WORKDIR/paywall-ui.txt" || true

echo ""
echo "=== RATE LIMITING / QUERY LIMITS ==="
grep -rn "rateLimit\|rate_limit\|queryLimit\|query_limit\|dailyLimit\|daily_limit\|remainingQueries\|queriesLeft\|usageLimit\|maxQueries\|freeQueries\|free_queries" \
  "$WORKDIR/decompiled/smali*/" 2>/dev/null | tee "$WORKDIR/rate-limits.txt" || true

echo ""
echo "=== SERVER-SIDE SUBSCRIPTION CHECK (API) ==="
grep -rn "subscription/status\|/api/subscription\|/user/subscription\|premium/check\|entitlement\|Entitlement" \
  "$WORKDIR/decompiled/smali*/" 2>/dev/null | tee "$WORKDIR/server-checks.txt" || true

# ── Step 4: Patch premium checks ──
echo ""
echo "[4/7] Patching premium checks..."

# Patch all isPremium/isPro/isSubscribed methods to return true (const/4 v0, 0x1 + return v0)
find "$WORKDIR/decompiled/smali*/" -name "*.smali" | while read smali; do
  # Methods returning boolean for premium status — flip to return true
  sed -i -E '
    /\.method.*isPremium\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x0/ s/0x0/0x1/
    }
    /\.method.*isPro\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x0/ s/0x0/0x1/
    }
    /\.method.*isSubscribed\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x0/ s/0x0/0x1/
    }
    /\.method.*hasPremium\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x0/ s/0x0/0x1/
    }
    /\.method.*hasSubscription\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x0/ s/0x0/0x1/
    }
    /\.method.*isFreeTier\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x1/ s/0x1/0x0/
    }
    /\.method.*isFreeUser\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x1/ s/0x1/0x0/
    }
    /\.method.*isPayingUser\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x0/ s/0x0/0x1/
    }
  ' "$smali"
done

# ── Step 5: Patch feature gates to unlock pro features ──
find "$WORKDIR/decompiled/smali*/" -name "*.smali" | while read smali; do
  sed -i -E '
    /\.method.*isFeatureEnabled\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x0/ s/0x0/0x1/
    }
    /\.method.*isGated\(\)Z/,/\.end method/ {
      /const\/4 v0, 0x1/ s/0x1/0x0/
    }
  ' "$smali"
done

# ── Step 6: Remove paywall/upgrade dialogs (nop out show calls) ──
find "$WORKDIR/decompiled/smali*/" -name "*.smali" | while read smali; do
  # Comment out paywall show invocations
  sed -i -E '
    /invoke.*showPaywall/s/^/# /
    /invoke.*showUpgrade/s/^/# /
    /invoke.*UpgradePrompt/s/^/# /
  ' "$smali"
done

echo "    Patched premium boolean methods"
echo "    Patched feature gates"
echo "    Removed paywall dialogs"

# ── Step 7: Rebuild and sign ──
echo "[5/7] Rebuilding APK..."
apktool b "$WORKDIR/decompiled" -o "$WORKDIR/perplexity-patched-unsigned.apk"

echo "[6/7] Signing APK..."
# Using uber-apk-signer (drop the jar in same directory, or use any signer)
if command -v uber-apk-signer &>/dev/null; then
  uber-apk-signer -a "$WORKDIR/perplexity-patched-unsigned.apk" -o "$WORKDIR/out"
  SIGNED=$(find "$WORKDIR/out" -name "*.apk" | head -1)
elif [ -f "uber-apk-signer.jar" ]; then
  java -jar uber-apk-signer.jar -a "$WORKDIR/perplexity-patched-unsigned.apk" -o "$WORKDIR/out"
  SIGNED=$(find "$WORKDIR/out" -name "*.apk" | head -1)
else
  echo "    No signer found. Using apksigner or jarsigner fallback..."
  # Generate a debug keystore
  keytool -genkeypair -v -keystore "$WORKDIR/debug.keystore" -alias debug \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass android -keypass android \
    -dname "CN=Debug,OU=Debug,O=Debug,L=Debug,ST=Debug,C=US" 2>/dev/null
  # Align
  if command -v zipalign &>/dev/null; then
    zipalign -v 4 "$WORKDIR/perplexity-patched-unsigned.apk" "$WORKDIR/perplexity-aligned.apk"
  else
    cp "$WORKDIR/perplexity-patched-unsigned.apk" "$WORKDIR/perplexity-aligned.apk"
  fi
  # Sign
  if command -v apksigner &>/dev/null; then
    apksigner sign --ks "$WORKDIR/debug.keystore" --ks-pass pass:android \
      --out "$WORKDIR/perplexity-modded.apk" "$WORKDIR/perplexity-aligned.apk"
  else
    jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
      -keystore "$WORKDIR/debug.keystore" -storepass android \
      "$WORKDIR/perplexity-aligned.apk" debug
    mv "$WORKDIR/perplexity-aligned.apk" "$WORKDIR/perplexity-modded.apk"
  fi
  SIGNED="$WORKDIR/perplexity-modded.apk"
fi

echo "[7/7] Done!"
echo ""
echo "=== OUTPUT ==="
echo "Modded APK: $SIGNED"
echo ""
echo "=== INSTALL ==="
echo "1. Uninstall the original Perplexity from your phone"
echo "2. adb install '$SIGNED'"
echo "   OR transfer the APK to your phone and install manually"
echo ""
echo "=== WHAT WAS PATCHED ==="
echo "- Premium/Pro status checks flipped to return true"
echo "- Free tier checks flipped to return false"
echo "- Feature gates unlocked"
echo "- Paywall/upgrade dialogs removed"
echo ""
echo "=== IMPORTANT NOTES ==="
echo "- Server-side features (Pro Search with GPT-4/Claude) need a real subscription"
echo "  because Perplexity validates your account on their backend"
echo "- Client-side features (UI unlocks, ad removal, unlimited basic queries,"
echo "  file upload UI, collection features) should work"
echo "- You'll need to uninstall the Play Store version first (different signature)"
echo "- If split APKs are needed, install them with: adb install-multiple *.apk"
