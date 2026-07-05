# Perplexity Premium Patcher

Patches Perplexity's client-side premium checks. Flips subscription booleans, unlocks feature gates, removes paywall dialogs.

## What it unlocks

**Client-side (works):**
- Premium UI elements and layouts
- Ad removal / nag removal
- Feature gates (collections, file uploads, etc.)
- Upgrade prompt removal
- Rate limit bypass (client-side checks only)

**Server-side (needs real subscription):**
- Pro Search (GPT-4 / Claude / model selection) — validated by Perplexity's backend
- Higher API rate limits enforced server-side

## Prerequisites

- **apktool** — https://apktool.org/docs/install
- **Java 8+** — for apktool and signing
- **One of:** uber-apk-signer, apksigner (Android SDK), or keytool+jarsigner (JDK)

### Quick install (Linux/macOS)

```bash
# apktool
brew install apktool        # macOS
sudo apt install apktool    # Ubuntu/Debian

# uber-apk-signer (optional, makes signing easier)
wget https://github.com/nicechute/uber-apk-signer/releases/latest/download/uber-apk-signer.jar
```

### Quick install (Windows)

```powershell
# Install apktool via chocolatey or download from https://apktool.org
choco install apktool

# Or use WSL and follow the Linux instructions
```

## Usage

```bash
chmod +x mod.sh
./mod.sh path/to/Perplexity.xapk
```

The script will:
1. Extract the XAPK
2. Decompile the base APK
3. Scan and list all premium check locations
4. Patch boolean methods (isPremium, isPro, isSubscribed → true)
5. Patch feature gates (isGated → false, isFeatureEnabled → true)
6. Remove paywall/upgrade dialog calls
7. Rebuild and sign the APK

## Install the modded APK

```bash
# Uninstall original first (different signature)
adb uninstall ai.perplexity.app.android

# Install modded version
adb install perplexity-mod-work/out/perplexity-patched-unsigned-aligned-signed.apk

# Or if split APKs are needed:
adb install-multiple *.apk
```

Or just transfer the APK to your phone and install from the file manager (enable "Install from unknown sources" first).

## Manual patching

If the automated script misses something, check the scan output files:
- `premium-checks.txt` — all isPremium/isPro/isSubscribed locations
- `billing-checks.txt` — BillingClient and purchase verification
- `feature-flags.txt` — feature gates and flags
- `paywall-ui.txt` — paywall and upgrade prompt locations
- `rate-limits.txt` — query/rate limit checks
- `server-checks.txt` — server-side subscription API calls

Open the listed smali files and flip the relevant `const/4 v0, 0x0` to `0x1` (or vice versa for free-tier checks).
