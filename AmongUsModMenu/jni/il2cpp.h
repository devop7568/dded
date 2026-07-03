#pragma once
#include <cstdint>
#include <cstddef>

// Minimal il2cpp export bindings — resolved from libil2cpp.so at load time.
namespace IL2CPP {
    using domain_get_t                  = void* (*)();
    using domain_get_assemblies_t       = void** (*)(void*, std::size_t*);
    using assembly_get_image_t          = void* (*)(void*);
    using class_from_name_t             = void* (*)(void*, const char*, const char*);
    using class_get_method_from_name_t  = void* (*)(void*, const char*, int);
    using method_get_pointer_t          = void* (*)(void*);
    using thread_attach_t               = void* (*)(void*);
    using string_new_t                  = void* (*)(const char*);

    extern domain_get_t                  domain_get;
    extern domain_get_assemblies_t       domain_get_assemblies;
    extern assembly_get_image_t          assembly_get_image;
    extern class_from_name_t             class_from_name;
    extern class_get_method_from_name_t  class_get_method_from_name;
    extern method_get_pointer_t          method_get_pointer;
    extern thread_attach_t               thread_attach;
    extern string_new_t                  string_new;

    extern void* domain;

    bool  Init();
    void* FindMethod(const char* ns, const char* klass, const char* method, int argc);
    void* MethodPtr(void* method);
}
