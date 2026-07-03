#include "hooks.h"
#include "config.h"
#include "il2cpp.h"
#include "offsets.h"

#include <mutex>
#include <random>
#include <android/log.h>
#include "And64InlineHook.hpp"

#define LOG(...) __android_log_print(ANDROID_LOG_INFO, "AUModMenu", __VA_ARGS__)

namespace {
    std::vector<Hooks::PlayerSnap> g_snap;
    std::mutex                     g_snapMtx;
    void* g_local_pc = nullptr;

    std::mt19937& Rng() {
        static thread_local std::mt19937 r(0xA11ceB0b);
        return r;
    }

    // ---- Originals ----
    void* (*o_PC_FixedUpdate)(void*)                              = nullptr;
    void* (*o_PC_CoSetRole)(void*, int, bool)                     = nullptr;
    float (*o_ShipStatus_CalcLightRadius)(void*, void*)           = nullptr;
    bool  (*o_PC_Data_get_IsImpostor)(void*)                      = nullptr;
    void* (*o_AmongUsClient_OnPlayerLeft)(void*, void*, int)      = nullptr;
    void* (*o_HudManager_Update)(void*)                           = nullptr;
    void* (*o_RoleManager_SelectRoles)(void*)                     = nullptr;
    bool  (*o_Collider2D_get_enabled)(void*)                      = nullptr;
    void* (*o_ChatController_AddChat)(void*, void*, void*, bool)  = nullptr;   // NOT hooked

    // ---- Helpers ----
    inline float* SpeedField(void* pc) {
        void* phys = *(void**)((uintptr_t)pc + Off::PC_MyPhysics);
        return phys ? (float*)((uintptr_t)phys + Off::PP_Speed) : nullptr;
    }
    inline void* PlayerData(void* pc) {
        return *(void**)((uintptr_t)pc + Off::PC_Data);
    }
    inline int RoleOf(void* data) {
        return data ? *(int*)((uintptr_t)data + Off::PI_RoleType) : -1;
    }
    inline bool IsDead(void* data) {
        return data && *(bool*)((uintptr_t)data + Off::PI_IsDead);
    }
    inline int PlayerId(void* data) {
        return data ? *(int*)((uintptr_t)data + Off::PI_PlayerId) : -1;
    }
    inline Vector2 PosOf(void* pc) {
        // Component.transform is resolved via il2cpp's Transform.get_position
        // — we cache position via NetworkedPosition instead (offset stable).
        void* nt = *(void**)((uintptr_t)pc + Off::PC_NetTransform);
        if (!nt) return {0,0};
        return *(Vector2*)((uintptr_t)nt + 0x40);
    }

    // ---- Hook bodies ----
    void* hk_PC_FixedUpdate(void* self) {
        void* r = o_PC_FixedUpdate(self);
        if (!self) return r;

        void* data = PlayerData(self);
        bool isLocal = (self == g_local_pc);

        // Vision multiplier (only affects local light)
        if (Cfg::visionMul.load() && isLocal) {
            if (float* spd = SpeedField(self)) {
                // do NOT touch Speed unless requested; separate hook via Cfg
            }
        }

        // Update ESP snapshot for local render thread
        Hooks::PlayerSnap s{};
        s.pc       = (PlayerControl*)self;
        s.pos      = PosOf(self);
        s.playerId = PlayerId(data);
        s.role     = RoleOf(data);
        s.dead     = IsDead(data);
        s.local    = isLocal;
        {
            std::lock_guard<std::mutex> lk(g_snapMtx);
            bool found = false;
            for (auto& p : g_snap) {
                if (p.playerId == s.playerId) { p = s; found = true; break; }
            }
            if (!found) g_snap.push_back(s);
        }
        return r;
    }

    // Vision override — huge light radius
    float hk_ShipStatus_CalcLightRadius(void* self, void* playerInfo) {
        float vanilla = o_ShipStatus_CalcLightRadius(self, playerInfo);
        if (Cfg::wallhack.load())        return 50.f;
        if (Cfg::visionMul.load())       return vanilla * Cfg::visionScale.load();
        return vanilla;
    }

    // Impostor % override — fires when RoleManager selects roles at match start
    void* hk_RoleManager_SelectRoles(void* self) {
        // Vanilla selection first, so lobby state / RPCs are correct
        void* r = o_RoleManager_SelectRoles(self);
        if (!Cfg::impostorForce.load() || !g_local_pc) return r;

        std::uniform_int_distribution<int> d(1, 100);
        int roll = d(Rng());
        if (roll > Cfg::impostorChance.load()) return r;

        // Coerce local player to chosen impostor sub-role.
        void* data = PlayerData(g_local_pc);
        if (!data) return r;
        int desired = Off::UserRoleToGame(Cfg::impostorRole.load());
        *(int*)((uintptr_t)data + Off::PI_RoleType) = desired;

        // PlayerControl.RpcSetRole isn't called — this is a *local* visual/gameplay
        // override that survives on host-authoritative logic in private lobbies.
        LOG("impostor forced (%d%% rolled %d) role=%d", Cfg::impostorChance.load(), roll, desired);
        return r;
    }

    // "IsImpostor" flag read constantly — flip locally so kill button / vent access unlocks
    bool hk_PC_Data_get_IsImpostor(void* self) {
        bool real = o_PC_Data_get_IsImpostor(self);
        if (!Cfg::impostorForce.load()) return real;
        // Only lie for the local player
        if (self && g_local_pc && self == PlayerData(g_local_pc)) {
            int r = *(int*)((uintptr_t)self + Off::PI_RoleType);
            if (r == Off::Impostor || r == Off::Shapeshifter || r == Off::Viper || r == Off::Phantom)
                return true;
        }
        return real;
    }

    // Collider2D.get_enabled → false when wallhack pass-through requested
    bool hk_Collider2D_get_enabled(void* self) {
        // NOT globally patched — only when noclip toggle wired via config.
        return o_Collider2D_get_enabled(self);
    }

    // Anti-timeout: swallow the OnPlayerLeft callback ONLY when the leaver is us.
    void* hk_AmongUsClient_OnPlayerLeft(void* self, void* client, int reason) {
        if (Cfg::antiTimeout.load()) {
            // reason 3 = kicked, 4 = disconnected — for the local netId, drop it
            int localClientId = *(int*)((uintptr_t)self + 0x20);
            int leavingClientId = client ? *(int*)((uintptr_t)client + 0x18) : -1;
            if (leavingClientId == localClientId) {
                LOG("anti-timeout: dropped self-leave (reason=%d)", reason);
                return nullptr;
            }
        }
        return o_AmongUsClient_OnPlayerLeft(self, client, reason);
    }

    // HudManager.Update — cache local PC + reset dirty state each frame
    void* hk_HudManager_Update(void* self) {
        void* r = o_HudManager_Update(self);
        // Bind local PlayerControl from HudManager.PlayerCam.Target
        void* cam = *(void**)((uintptr_t)self + 0x40);
        if (cam) {
            void* target = *(void**)((uintptr_t)cam + 0x28);
            if (target) g_local_pc = target;
        }
        return r;
    }
}

namespace Hooks {

const std::vector<PlayerSnap>& Snapshot() {
    // Callers copy under g_snapMtx when they need consistency; ESP overlay reads directly.
    return g_snap;
}

void Install() {
    #define BIND(NS, KLASS, METHOD, ARGC, DETOUR, ORIG)                          \
        do {                                                                     \
            void* m  = IL2CPP::FindMethod(NS, KLASS, METHOD, ARGC);              \
            void* fn = IL2CPP::MethodPtr(m);                                     \
            if (fn) A64HookFunction(fn, (void*)DETOUR, (void**)&ORIG);           \
            LOG("hook %s::%s → %s", KLASS, METHOD, fn ? "OK" : "MISS");          \
        } while(0)

    BIND("", "PlayerControl",   "FixedUpdate",   0, hk_PC_FixedUpdate,          o_PC_FixedUpdate);
    BIND("", "ShipStatus",      "CalculateLightRadius", 1, hk_ShipStatus_CalcLightRadius, o_ShipStatus_CalcLightRadius);
    BIND("", "RoleManager",     "SelectRoles",   0, hk_RoleManager_SelectRoles, o_RoleManager_SelectRoles);
    BIND("GameData", "PlayerInfo", "get_IsImpostor", 0, hk_PC_Data_get_IsImpostor, o_PC_Data_get_IsImpostor);
    BIND("InnerNet","InnerNetClient", "OnPlayerLeft", 2, hk_AmongUsClient_OnPlayerLeft, o_AmongUsClient_OnPlayerLeft);
    BIND("", "HudManager",      "Update",        0, hk_HudManager_Update,       o_HudManager_Update);

    // ChatController.AddChat NOT hooked — chat behavior stays 100% vanilla.
    #undef BIND
}

void Uninstall() {
    // And64InlineHook doesn't expose a clean unhook — process teardown handles it.
}

} // namespace Hooks
