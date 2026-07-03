LOCAL_PATH := $(call my-dir)

# ---- And64InlineHook ----
include $(CLEAR_VARS)
LOCAL_MODULE := a64hook
LOCAL_SRC_FILES := And64InlineHook/And64InlineHook.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)/And64InlineHook
LOCAL_CPPFLAGS := -std=c++17 -fexceptions -Wno-unused-parameter
include $(BUILD_STATIC_LIBRARY)

# ---- The mod (headless: no ImGui, no menu, all features auto-on) ----
include $(CLEAR_VARS)
LOCAL_MODULE := modmenu
LOCAL_SRC_FILES := \
    main.cpp \
    il2cpp.cpp \
    hooks.cpp \
    memory.cpp
LOCAL_C_INCLUDES := \
    $(LOCAL_PATH) \
    $(LOCAL_PATH)/And64InlineHook
LOCAL_CPPFLAGS := -std=c++17 -fexceptions -frtti -fvisibility=hidden -Wno-write-strings -Wno-unused-parameter
LOCAL_STATIC_LIBRARIES := a64hook
LOCAL_LDLIBS := -llog -landroid
include $(BUILD_SHARED_LIBRARY)
