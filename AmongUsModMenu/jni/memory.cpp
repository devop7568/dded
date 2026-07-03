#include "memory.h"
#include <cstdio>
#include <cstring>

namespace Mem {

uintptr_t GetLibraryBase(const char* name) {
    FILE* f = fopen("/proc/self/maps", "r");
    if (!f) return 0;
    char line[512];
    uintptr_t base = 0;
    while (fgets(line, sizeof line, f)) {
        if (strstr(line, name)) {
            base = (uintptr_t)strtoull(line, nullptr, 16);
            break;
        }
    }
    fclose(f);
    return base;
}

} // Mem
