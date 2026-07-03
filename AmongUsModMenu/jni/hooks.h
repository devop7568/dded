#pragma once
#include <cstdint>
#include <vector>

// Reflection of the game's minimal C# types we touch.
// Field offsets are dumped by scripts/dump_offsets.sh into offsets.h.
struct Vector2 { float x, y; };
struct Vector3 { float x, y, z; };
struct Color   { float r, g, b, a; };

struct String_o;
struct PlayerControl;
struct PlayerPhysics;
struct GameData_PlayerInfo;
struct SystemTypes;

namespace Hooks {
    void Install();
    void Uninstall();

    // Live snapshot of all players for the ESP thread.
    struct PlayerSnap {
        PlayerControl* pc;
        Vector2        pos;
        int            playerId;
        int            role;         // 0 crew, 1 imp, 2 viper, 3 shifter, 4 phantom
        bool           dead;
        bool           local;
    };
    const std::vector<PlayerSnap>& Snapshot();
}
