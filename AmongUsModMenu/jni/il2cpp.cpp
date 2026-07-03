#include "il2cpp.h"
#include <dlfcn.h>
#include <unistd.h>
#include <android/log.h>

#define LOG(...) __android_log_print(ANDROID_LOG_INFO, "AUModMenu", __VA_ARGS__)

namespace IL2CPP {
    domain_get_t                 domain_get                 = nullptr;
    domain_get_assemblies_t      domain_get_assemblies      = nullptr;
    assembly_get_image_t         assembly_get_image         = nullptr;
    class_from_name_t            class_from_name            = nullptr;
    class_get_method_from_name_t class_get_method_from_name = nullptr;
    method_get_pointer_t         method_get_pointer         = nullptr;
    thread_attach_t              thread_attach              = nullptr;
    string_new_t                 string_new                 = nullptr;
    void* domain = nullptr;

    bool Init() {
        void* g = dlopen("libil2cpp.so", RTLD_LAZY);
        for (int i = 0; !g && i < 60; ++i) { sleep(1); g = dlopen("libil2cpp.so", RTLD_LAZY); }
        if (!g) { LOG("libil2cpp.so not found"); return false; }

        #define R(fn) fn = (fn##_t)dlsym(g, "il2cpp_" #fn)
        R(domain_get);
        R(domain_get_assemblies);
        R(assembly_get_image);
        R(class_from_name);
        R(class_get_method_from_name);
        R(method_get_pointer);
        R(thread_attach);
        R(string_new);
        #undef R

        if (!domain_get) return false;

        // give runtime time to finish il2cpp_init
        for (int i = 0; i < 30; ++i) {
            domain = domain_get();
            if (domain) break;
            sleep(1);
        }
        if (!domain) return false;

        thread_attach(domain);
        LOG("il2cpp bound, domain=%p", domain);
        return true;
    }

    void* FindMethod(const char* ns, const char* klass, const char* method, int argc) {
        if (!domain) return nullptr;
        std::size_t n = 0;
        void** assemblies = domain_get_assemblies(domain, &n);
        for (std::size_t i = 0; i < n; ++i) {
            void* img = assembly_get_image(assemblies[i]);
            if (!img) continue;
            void* c = class_from_name(img, ns, klass);
            if (!c) continue;
            void* m = class_get_method_from_name(c, method, argc);
            if (m) return m;
        }
        LOG("method not found: %s.%s::%s/%d", ns, klass, method, argc);
        return nullptr;
    }

    void* MethodPtr(void* m) {
        if (!m) return nullptr;
        return method_get_pointer ? method_get_pointer(m) : *(void**)m;
    }
}
