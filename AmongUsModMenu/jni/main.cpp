// Entry: unity's PlayerActivity dlopens every lib*.so under lib/<abi>/.
// We ride that free ride — no smali edit needed.

#include <jni.h>
#include <dlfcn.h>
#include <thread>
#include <atomic>
#include <chrono>
#include <android/log.h>
#include <EGL/egl.h>
#include <GLES3/gl3.h>

#include "il2cpp.h"
#include "hooks.h"
#include "menu.h"

#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_android.h"
#include "imgui/backends/imgui_impl_opengl3.h"

#define LOG(...) __android_log_print(ANDROID_LOG_INFO, "AUModMenu", __VA_ARGS__)

// ---- eglSwapBuffers hook (very small, no kiero on android) -----------
namespace {
    using eglSwapBuffers_t = EGLBoolean(*)(EGLDisplay, EGLSurface);
    eglSwapBuffers_t o_eglSwapBuffers = nullptr;
    std::atomic<bool> g_glReady{false};

    EGLBoolean hk_eglSwapBuffers(EGLDisplay d, EGLSurface s) {
        if (!g_glReady.load()) {
            // First swap → init ImGui GL/Android backend on this thread
            ImGui_ImplAndroid_Init(/*window*/ nullptr);
            ImGui_ImplOpenGL3_Init("#version 300 es");
            g_glReady = true;
            LOG("ImGui GLES3 backend init OK");
        }
        Menu::Draw();
        return o_eglSwapBuffers(d, s);
    }
}

#include "And64InlineHook.h"

static void MainThread() {
    if (!IL2CPP::Init()) { LOG("il2cpp init failed"); return; }

    Menu::Init();
    Hooks::Install();

    void* egl = dlopen("libEGL.so", RTLD_LAZY);
    if (egl) {
        void* fn = dlsym(egl, "eglSwapBuffers");
        if (fn) A64HookFunction(fn, (void*)hk_eglSwapBuffers, (void**)&o_eglSwapBuffers);
        LOG("eglSwapBuffers hooked: %d", fn != nullptr);
    }
}

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void*) {
    LOG("modmenu loaded");
    std::thread(MainThread).detach();
    return JNI_VERSION_1_6;
}
