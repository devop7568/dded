APP_ABI          := arm64-v8a
# arm-v7a dropped: And64InlineHook is arm64-only. 95%+ of active devices are arm64.
APP_PLATFORM     := android-24
APP_STL          := c++_static
APP_CPPFLAGS     := -std=c++17 -fexceptions -frtti
APP_OPTIM        := release
NDK_TOOLCHAIN_VERSION := clang
