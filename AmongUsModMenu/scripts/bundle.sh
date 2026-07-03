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
