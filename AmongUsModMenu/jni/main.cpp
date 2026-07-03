// Entry via smali-injected System.loadLibrary("modmenu") in launcher onCreate.

#include <jni.h>
#include <dlfcn.h>
#include <thread>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <android/log.h>
#include <EGL/egl.h>
#include <GLES3/gl3.h>

#include "il2cpp.h"
#include "hooks.h"
#include "menu.h"

#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_android.h"
#include "imgui/backends/imgui_impl_opengl3.h"

#define LOG(fmt, ...) __android_log_print(ANDROID_LOG_INFO,  "AUModMenu", "[+] " fmt, ##__VA_ARGS__)
#define ERR(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, "AUModMenu", "[!] " fmt, ##__VA_ARGS__)

static JavaVM* g_vm = nullptr;

// ---- Toast helper: proves the .so actually loaded ----
static void ShowToast(const char* msg) {
    if (!g_vm) return;
    JNIEnv* env = nullptr;
    bool detach = false;
    if (g_vm->GetEnv((void**)&env, JNI_VERSION_1_6) == JNI_EDETACHED) {
        if (g_vm->AttachCurrentThread(&env, nullptr) != 0) return;
        detach = true;
    }
    jclass looperCls = env->FindClass("android/os/Looper");
    jclass actThreadCls = env->FindClass("android/app/ActivityThread");
    if (!actThreadCls) { if (detach) g_vm->DetachCurrentThread(); return; }
    jmethodID currentAT = env->GetStaticMethodID(actThreadCls, "currentActivityThread",
                                                 "()Landroid/app/ActivityThread;");
    jobject at = env->CallStaticObjectMethod(actThreadCls, currentAT);
    jmethodID getApp = env->GetMethodID(actThreadCls, "getApplication", "()Landroid/app/Application;");
    jobject app = env->CallObjectMethod(at, getApp);

    // Ensure we're on the main looper
    jmethodID prepMain = env->GetStaticMethodID(looperCls, "prepareMainLooper", "()V");
    (void)prepMain;

    jclass toastCls = env->FindClass("android/widget/Toast");
    jmethodID makeText = env->GetStaticMethodID(toastCls, "makeText",
        "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;");
    jstring j = env->NewStringUTF(msg);
    jobject toast = env->CallStaticObjectMethod(toastCls, makeText, app, j, 1 /*LENGTH_LONG*/);
    jmethodID show = env->GetMethodID(toastCls, "show", "()V");
    env->CallVoidMethod(toast, show);

    env->DeleteLocalRef(j);
    if (detach) g_vm->DetachCurrentThread();
}

// ---- eglSwapBuffers hook -----------
namespace {
    using eglSwapBuffers_t = EGLBoolean(*)(EGLDisplay, EGLSurface);
    eglSwapBuffers_t o_eglSwapBuffers = nullptr;
    std::atomic<bool> g_glReady{false};
    std::atomic<int>  g_frames{0};

    EGLBoolean hk_eglSwapBuffers(EGLDisplay d, EGLSurface s) {
        if (!g_glReady.load()) {
            // Read the actual EGL surface size
            EGLint w = 1080, h = 2400;
            eglQuerySurface(d, s, EGL_WIDTH,  &w);
            eglQuerySurface(d, s, EGL_HEIGHT, &h);
            ImGuiIO& io = ImGui::GetIO();
            io.DisplaySize = ImVec2((float)w, (float)h);
            io.DeltaTime   = 1.f/60.f;
            LOG("EGL surface %dx%d", w, h);

            if (!ImGui_ImplOpenGL3_Init("#version 300 es")) {
                ERR("ImGui GL3 init failed");
            } else {
                LOG("ImGui GL3 init OK");
            }
            g_glReady = true;
        }
        int n = ++g_frames;
        if (n == 1)    LOG("first frame rendered");
        if (n == 300)  LOG("300 frames — menu should be visible");

        // Update size every frame (screen rotation / lobby)
        EGLint w=0,h=0;
        eglQuerySurface(d, s, EGL_WIDTH,  &w);
        eglQuerySurface(d, s, EGL_HEIGHT, &h);
        if (w && h) ImGui::GetIO().DisplaySize = ImVec2((float)w,(float)h);

        Menu::Draw();
        return o_eglSwapBuffers(d, s);
    }
}

#include "And64InlineHook.hpp"

static void MainThread() {
    LOG("MainThread started, waiting for libil2cpp.so ...");
    if (!IL2CPP::Init()) { ERR("il2cpp init failed — mod dead"); return; }
    LOG("il2cpp bound");

    Menu::Init();
    LOG("ImGui context created");

    Hooks::Install();
    LOG("gameplay hooks installed");

    void* egl = dlopen("libEGL.so", RTLD_LAZY);
    if (!egl) { ERR("libEGL.so dlopen failed"); return; }
    void* fn = dlsym(egl, "eglSwapBuffers");
    if (!fn)  { ERR("eglSwapBuffers not resolved"); return; }
    A64HookFunction(fn, (void*)hk_eglSwapBuffers, (void**)&o_eglSwapBuffers);
    LOG("eglSwapBuffers hooked at %p", fn);

    // Toast to prove we're alive
    std::this_thread::sleep_for(std::chrono::seconds(2));
    ShowToast("Nyx mod menu loaded — tap N button");
}

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void*) {
    g_vm = vm;
    LOG("========== libmodmenu.so JNI_OnLoad ==========");
    std::thread(MainThread).detach();
    return JNI_VERSION_1_6;
}
