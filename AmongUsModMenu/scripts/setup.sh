#!/usr/bin/env bash
# Fetches ImGui + KittyMemory + And64InlineHook into jni/.
set -e
cd "$(dirname "$0")/.."
JNI=jni

fetch() {
    local name=$1 url=$2 tag=$3
    if [ -d "$JNI/$name" ]; then echo "[=] $name present"; return; fi
    echo "[+] cloning $name @ $tag"
    git clone --depth 1 --branch "$tag" "$url" "$JNI/$name"
}

fetch imgui              https://github.com/ocornut/imgui.git                       docking
fetch KittyMemory        https://github.com/MJx0/KittyMemory.git                    master
fetch And64InlineHook    https://github.com/Rprop/And64InlineHook.git               master

# apktool + apksigner detection
mkdir -p tools
[ -f tools/apktool.jar ] || curl -L -o tools/apktool.jar \
    https://github.com/iBotPeaches/Apktool/releases/download/v2.12.0/apktool_2.12.0.jar
[ -f tools/uber-apk-signer.jar ] || curl -L -o tools/uber-apk-signer.jar \
    https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar

echo "[✓] setup complete"
