#!/usr/bin/env bash
# Merge XAPK splits → inject libmodmenu.so → resign → single installable APK.
set -e
cd "$(dirname "$0")/.."

XAPK="${1:?usage: bundle.sh AmongUs_2026.6.5.xapk}"
OUT="AmongUs_modded.apk"
WORK=".build"
rm -rf "$WORK" && mkdir -p "$WORK/splits"

echo "[1/6] extracting XAPK..."
unzip -q "$XAPK" -d "$WORK/splits"

echo "[2/6] merging splits with APKEditor..."
if [ ! -f tools/APKEditor.jar ]; then
    curl -L -o tools/APKEditor.jar \
        https://github.com/REAndroid/APKEditor/releases/download/V1.4.4/APKEditor-1.4.4.jar
fi
java -jar tools/APKEditor.jar m -i "$WORK/splits" -o "$WORK/merged.apk"

echo "[3/6] decompiling merged APK..."
java -jar tools/apktool.jar d -f -o "$WORK/dec" "$WORK/merged.apk"

echo "[4/6] injecting libmodmenu.so ..."
for abi in arm64-v8a armeabi-v7a; do
    if [ -f "libs/$abi/libmodmenu.so" ]; then
        mkdir -p "$WORK/dec/lib/$abi"
        cp "libs/$abi/libmodmenu.so" "$WORK/dec/lib/$abi/"
        echo "    + lib/$abi/libmodmenu.so"
    fi
done

echo "[4b/6] smali-patching launcher activity to load libmodmenu ..."
# Find the launcher activity name from AndroidManifest.xml
LAUNCH_ACT=$(python3 - <<'PY'
import re, pathlib
m = pathlib.Path(".build/dec/AndroidManifest.xml").read_text()
# Find any activity that contains a MAIN + LAUNCHER intent-filter
acts = re.findall(r'<activity[^>]*android:name="([^"]+)"[^>]*>(.*?)</activity>', m, re.S)
for name, body in acts:
    if 'android.intent.action.MAIN' in body and 'android.intent.category.LAUNCHER' in body:
        print(name); break
PY
)
echo "    launcher: $LAUNCH_ACT"

# Resolve to smali path (handles com.a.b -> smali*/com/a/b.smali, plus $Inner classes)
SMALI_REL=$(echo "$LAUNCH_ACT" | tr '.' '/').smali
SMALI_FILE=$(find "$WORK/dec" -type f -path "*/smali*/$SMALI_REL" | head -1)
if [ -z "$SMALI_FILE" ]; then
    # unity default fallback
    SMALI_FILE=$(find "$WORK/dec" -type f -name 'UnityPlayerActivity.smali' | head -1)
fi
echo "    smali:    $SMALI_FILE"

# Patch: inject System.loadLibrary("modmenu") at the top of onCreate.
# If onCreate has no .locals declaration or is missing, we insert it into the
# static initializer (<clinit>). We prefer onCreate because that's after
# ClassLoader is fully wired.
python3 - "$SMALI_FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text()

inject = '''
    const-string v0, "modmenu"
    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V
'''

# Find the onCreate method and inject right after .locals line
pat = re.compile(
    r'(\.method[^\n]*\bonCreate\(Landroid/os/Bundle;\)V\n\s*\.locals\s+)(\d+)(\n)',
    re.M)
def repl(m):
    n = int(m.group(2))
    new_n = max(n, 1)
    return f"{m.group(1)}{new_n}{m.group(3)}{inject}"
new, count = pat.subn(repl, s, count=1)
if count == 0:
    # No onCreate — try to add it via <clinit>
    clinit = re.compile(r'(\.method static constructor <clinit>\(\)V\n\s*\.locals\s+)(\d+)(\n)', re.M)
    def rc(m):
        n = int(m.group(2))
        return f"{m.group(1)}{max(n,1)}{m.group(3)}{inject}"
    new, count = clinit.subn(rc, s, count=1)

if count == 0:
    # Insert a fresh <clinit>
    inject_clinit = f"""
.method static constructor <clinit>()V
    .locals 1
    {inject.strip()}
    return-void
.end method
"""
    new = s.replace("# direct methods", "# direct methods" + inject_clinit, 1)
    if new == s:
        # last resort: append before end of class
        new = s + inject_clinit

p.write_text(new)
print(f"  patched loadLibrary hook into {p.name}")
PY

echo "[5/6] rebuilding APK..."
java -jar tools/apktool.jar b "$WORK/dec" -o "$WORK/unsigned.apk"
zipalign -p -f 4 "$WORK/unsigned.apk" "$WORK/aligned.apk"

echo "[6/6] signing..."
if [ ! -f key.jks ]; then
    keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 \
        -alias au -storepass password -keypass password \
        -dname "CN=AU, OU=Home, O=Home, L=Void, S=Void, C=US" >/dev/null 2>&1
fi
apksigner sign --ks key.jks --ks-pass pass:password --key-pass pass:password \
               --out "$OUT" "$WORK/aligned.apk"
apksigner verify "$OUT"

echo
echo "[✓] $OUT ready — sideload it."
