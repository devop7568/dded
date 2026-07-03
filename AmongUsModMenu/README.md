# Among Us Mod Menu — v2026.6.5

Features wired in:
- **Impostor % slider** (default 80) + role force (Viper / Shapeshifter / Phantom)
- **Wallhack** (transparent shadows, radius override)
- **Vision multiplier** (default 2.0x)
- **Role ESP** — role name text floating above each player
- **Anti-timeout** (self-leave never reported, ban-strike suppressed)
- Chat left untouched.

## What this repo is

A ready-to-build Android NDK project that compiles to `libmodmenu.so` (arm64-v8a + armeabi-v7a). Bundle script merges the Among Us XAPK, injects the `.so`, resigns, produces one installable APK.

## Build on Linux / Mac

```bash
# one-time
./scripts/setup.sh          # fetches ImGui, KittyMemory, And64InlineHook

# build
./scripts/build.sh          # ndk-build → libs/arm64-v8a/libmodmenu.so
./scripts/bundle.sh AmongUs_2026.6.5.xapk    # merge + inject + sign → AmongUs_modded.apk
```

## Build in Termux (no PC)

```bash
pkg install -y openjdk-17 python git unzip zip curl clang make
pkg install -y ndk-multilib   # or: pkg install android-tools
./scripts/setup.sh
./scripts/build.sh
./scripts/bundle.sh /sdcard/Download/AmongUs_2026.6.5.xapk
```

## Requirements

- Android NDK **r26+** on `PATH` (or `NDK_HOME` set)
- Java 17 for `apksigner`
- `apktool`, `zipalign`, `apksigner` (bundle script auto-fetches if missing)
- Python 3

## Version updates

Every Among Us update shifts il2cpp offsets. After each update:

```bash
./scripts/dump_offsets.sh AmongUs_new.xapk   # runs Il2CppDumper, writes offsets.h
./scripts/build.sh
./scripts/bundle.sh AmongUs_new.xapk
```

`offsets.h` is auto-regenerated with method addresses for the six hook points.

## Install

1. Uninstall the Play Store Among Us (signature mismatch).
2. `adb install -r AmongUs_modded.apk`, or transfer to phone and tap.
3. Launch — floating `⚙` button appears bottom-right. Tap to open menu.
