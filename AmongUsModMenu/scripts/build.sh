#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

: "${NDK:=${NDK_HOME:-${ANDROID_NDK_HOME:-}}}"
if [ -z "$NDK" ]; then
    NDK=$(command -v ndk-build | xargs -I{} dirname {})
fi
[ -z "$NDK" ] && { echo "set NDK_HOME to your Android NDK path"; exit 1; }

"$NDK"/ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=jni/Android.mk NDK_APPLICATION_MK=jni/Application.mk -j"$(nproc 2>/dev/null || echo 4)"

echo
echo "[✓] built:"
ls -la libs/*/libmodmenu.so
