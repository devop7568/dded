#pragma once
// Field offsets & role enum for Among Us v2026.6.5 arm64-v8a.
// Regenerate after each game update:  ./scripts/dump_offsets.sh <new.xapk>
//
// The dumper writes over these values; if you patch by hand, verify against
// dump.cs (Il2CppDumper output).

namespace Off {
    // PlayerControl
    constexpr uintptr_t PC_PlayerId       = 0x38;
    constexpr uintptr_t PC_MyPhysics      = 0x50;
    constexpr uintptr_t PC_Data           = 0x58;
    constexpr uintptr_t PC_Collider2D     = 0x60;
    constexpr uintptr_t PC_NetTransform   = 0x68;

    // PlayerPhysics
    constexpr uintptr_t PP_Speed          = 0x28;
    constexpr uintptr_t PP_Velocity       = 0x2C;

    // GameData.PlayerInfo
    constexpr uintptr_t PI_PlayerId       = 0x10;
    constexpr uintptr_t PI_RoleType       = 0x30;   // AmongUs.Data.RoleTypes enum
    constexpr uintptr_t PI_IsDead         = 0x38;
    constexpr uintptr_t PI_Object         = 0x40;   // → PlayerControl

    // Camera / ShipStatus
    constexpr uintptr_t Cam_Zoom          = 0x1C;

    // Collider2D
    constexpr uintptr_t Col2D_Enabled     = 0x30;

    // Role IDs matching AmongUs.Data.RoleTypes in v2026.6.5
    enum Role : int {
        Crewmate     = 0,
        Impostor     = 1,
        Scientist    = 2,
        Engineer     = 3,
        GuardianAngel= 4,
        Shapeshifter = 5,
        CrewmateGhost= 6,
        ImpostorGhost= 7,
        Noisemaker   = 8,
        Tracker      = 9,
        Phantom      = 10,
        Viper        = 11,
    };

    // Cfg::impostorRole encoding → Off::Role
    inline int UserRoleToGame(int u) {
        switch (u) {
            case 1: return Viper;
            case 2: return Shapeshifter;
            case 3: return Phantom;
            default: return Impostor;
        }
    }
}
