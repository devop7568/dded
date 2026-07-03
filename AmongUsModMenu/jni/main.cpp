// Headless mode: no menu, all features force-on from Cfg defaults.
// Entry via smali-injected System.loadLibrary("modmenu") in launcher onCreate.

#include <jni.h>
#include <dlfcn.h>
#include <thread>
#include <chrono>
#include <android/log.h>

#include "il2cpp.h"
#include "hooks.h"

#define LOG(fmt, ...) __android_log_print(ANDROID_LOG_INFO,  "AUModMenu", "[+] " fmt, ##__VA_ARGS__)
#define ERR(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, "AUModMenu", "[!] " fmt, ##__VA_ARGS__)

static JavaVM* g_vm = nullptr;

static void ShowToast(const char* msg) {
    if (!g_vm) return;
    JNIEnv* env = nullptr;
    bool detach = false;
    if (g_vm->GetEnv((void**)&env, JNI_VERSION_1_6) == JNI_EDETACHED) {
        if (g_vm->AttachCurrentThread(&env, nullptr) != 0) return;
        detach = true;
    }
    jclass actThreadCls = env->FindClass("android/app/ActivityThread");
    if (!actThreadCls) { if (detach) g_vm->DetachCurrentThread(); return; }
    jmethodID currentAT = env->GetStaticMethodID(actThreadCls, "currentActivityThread",
                                                 "()Landroid/app/ActivityThread;");
    jobject at = env->CallStaticObjectMethod(actThreadCls, currentAT);
    jmethodID getApp = env->GetMethodID(actThreadCls, "getApplication", "()Landroid/app/Application;");
    jobject app = env->CallObjectMethod(at, getApp);

    jclass toastCls = env->FindClass("android/widget/Toast");
    jmethodID makeText = env->GetStaticMethodID(toastCls, "makeText",
        "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;");
    jstring j = env->NewStringUTF(msg);
    jobject toast = env->CallStaticObjectMethod(toastCls, makeText, app, j, 1);
    jmethodID show = env->GetMethodID(toastCls, "show", "()V");
    env->CallVoidMethod(toast, show);

    env->DeleteLocalRef(j);
    if (detach) g_vm->DetachCurrentThread();
}

static void MainThread() {
    LOG("MainThread started, waiting for libil2cpp.so ...");
    if (!IL2CPP::Init()) { ERR("il2cpp init failed"); return; }
    LOG("il2cpp bound");

    Hooks::Install();
    LOG("gameplay hooks installed");

    std::this_thread::sleep_for(std::chrono::seconds(2));
    ShowToast("Nyx: all features ON — impostor 80% / wallhack / vision 2x / role ESP / anti-timeout / free chat");
}

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void*) {
    g_vm = vm;
    LOG("========== libmodmenu.so JNI_OnLoad ==========");
    std::thread(MainThread).detach();
    return JNI_VERSION_1_6;
}
