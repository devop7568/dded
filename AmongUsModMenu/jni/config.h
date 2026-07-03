#pragma once
#include <atomic>

// Feature toggles and tunables. The ImGui menu binds directly to these.
namespace Cfg {
    // ---- Impostor RNG override ----
    inline std::atomic<bool>  impostorForce{true};
    inline std::atomic<int>   impostorChance{80};  // 0-100

    // 0 = none, 1 = Viper, 2 = Shapeshifter, 3 = Phantom
    // If set and impostorForce fires, PlayerControl role is overridden after RoleManager assigns.
    inline std::atomic<int>   impostorRole{2};     // default: Shapeshifter

    // ---- Vision ----
    inline std::atomic<bool>  wallhack{true};
    inline std::atomic<bool>  visionMul{true};
    inline std::atomic<float> visionScale{2.0f};   // 1.0 = vanilla, 100 = full map

    // ---- ESP ----
    inline std::atomic<bool>  roleESP{true};
    inline std::atomic<bool>  boxESP{false};
    inline std::atomic<bool>  distanceESP{false};

    // ---- Anti-punishment ----
    inline std::atomic<bool>  antiTimeout{true};   // suppress self-leave report
    inline std::atomic<bool>  antiBan{true};       // block Innersloth reputation flag

    // ---- Chat ----
    // Free chat: bypass gates so you can chat while dead, outside meetings, muted, moving.
    // We don't touch the send path itself — only the "can I type right now" checks.
    inline std::atomic<bool>  freeChat{true};
}
