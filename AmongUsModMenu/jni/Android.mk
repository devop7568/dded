LOCAL_PATH := $(call my-dir)

# ---- Dear ImGui (docking) ----
include $(CLEAR_VARS)
LOCAL_MODULE := imgui
LOCAL_SRC_FILES := \
    imgui/imgui.cpp \
    imgui/imgui_draw.cpp \
    imgui/imgui_tables.cpp \
    imgui/imgui_widgets.cpp \
    imgui/backends/imgui_impl_android.cpp \
    imgui/backends/imgui_impl_opengl3.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)/imgui $(LOCAL_PATH)/imgui/backends
LOCAL_CPPFLAGS := -std=c++17 -fexceptions -frtti -DIMGUI_IMPL_OPENGL_ES3
include $(BUILD_STATIC_LIBRARY)

# ---- KittyMemory ----
include $(CLEAR_VARS)
LOCAL_MODULE := kittymemory
LOCAL_SRC_FILES := \
    KittyMemory/MemoryUtils.cpp \
    KittyMemory/MemoryPatch.cpp \
    KittyMemory/KittyUtils.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)/KittyMemory
include $(BUILD_STATIC_LIBRARY)

# ---- And64InlineHook ----
include $(CLEAR_VARS)
LOCAL_MODULE := a64hook
LOCAL_SRC_FILES := And64InlineHook/And64InlineHook.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)/And64InlineHook
include $(BUILD_STATIC_LIBRARY)

# ---- The mod menu ----
include $(CLEAR_VARS)
LOCAL_MODULE := modmenu
LOCAL_SRC_FILES := \
    main.cpp \
    il2cpp.cpp \
    hooks.cpp \
    menu.cpp \
    esp.cpp
LOCAL_C_INCLUDES := \
    $(LOCAL_PATH) \
    $(LOCAL_PATH)/imgui \
    $(LOCAL_PATH)/imgui/backends \
    $(LOCAL_PATH)/KittyMemory \
    $(LOCAL_PATH)/And64InlineHook
LOCAL_CPPFLAGS := -std=c++17 -fexceptions -frtti -fvisibility=hidden -Wno-write-strings -Wno-unused-parameter
LOCAL_STATIC_LIBRARIES := imgui kittymemory a64hook
LOCAL_LDLIBS := -llog -landroid -lEGL -lGLESv3
include $(BUILD_SHARED_LIBRARY)
