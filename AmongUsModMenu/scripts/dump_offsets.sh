#!/usr/bin/env bash
# Runs Il2CppDumper on a merged Among Us APK and writes jni/offsets.h with the
# fresh field offsets & role enum. Requires .NET runtime + Il2CppDumper.
set -e
cd "$(dirname "$0")/.."

XAPK="${1:?usage: dump_offsets.sh AmongUs.xapk}"
WORK=".dump"; rm -rf "$WORK"; mkdir -p "$WORK/split"

echo "[1/4] extract xapk"
unzip -q "$XAPK" -d "$WORK/split"
BASE=$(find "$WORK/split" -maxdepth 2 -name 'base.apk' | head -1)
[ -f "$BASE" ] || BASE=$(find "$WORK/split" -maxdepth 2 -name 'AmongUs.apk' | head -1)

echo "[2/4] pull il2cpp + metadata"
unzip -q -o "$BASE" 'lib/arm64-v8a/libil2cpp.so' \
                      'assets/bin/Data/Managed/Metadata/global-metadata.dat' \
                      -d "$WORK/"

if [ ! -f tools/Il2CppDumper.dll ]; then
    echo "[!] Install Il2CppDumper into ./tools first:"
    echo "    curl -L -o tools/Il2CppDumper.zip https://github.com/Perfare/Il2CppDumper/releases/latest/download/Il2CppDumper-net6-linux-x64.zip"
    echo "    unzip -d tools tools/Il2CppDumper.zip"
    exit 1
fi

echo "[3/4] dump"
dotnet tools/Il2CppDumper.dll \
    "$WORK/lib/arm64-v8a/libil2cpp.so" \
    "$WORK/assets/bin/Data/Managed/Metadata/global-metadata.dat" \
    "$WORK/out"

echo "[4/4] rewrite jni/offsets.h from dump.cs"
python3 scripts/parse_offsets.py "$WORK/out/dump.cs" jni/offsets.h
echo "[✓] jni/offsets.h refreshed"
