#include "menu.h"
#include "hooks.h"
#include "config.h"
#include "offsets.h"
#include "il2cpp.h"

#include "imgui/imgui.h"
#include <mutex>

namespace {
    const char* RoleName(int role) {
        switch (role) {
            case Off::Impostor:     return "Impostor";
            case Off::Shapeshifter: return "Shapeshifter";
            case Off::Viper:        return "Viper";
            case Off::Phantom:      return "Phantom";
            case Off::Scientist:    return "Scientist";
            case Off::Engineer:     return "Engineer";
            case Off::GuardianAngel:return "Guardian Angel";
            case Off::Noisemaker:   return "Noisemaker";
            case Off::Tracker:      return "Tracker";
            case Off::Crewmate:     return "Crewmate";
            case Off::CrewmateGhost:return "Crew (ghost)";
            case Off::ImpostorGhost:return "Imp (ghost)";
            default:                return "?";
        }
    }

    inline ImU32 ColorFor(int role) {
        switch (role) {
            case Off::Impostor:
            case Off::Shapeshifter:
            case Off::Viper:
            case Off::Phantom:
            case Off::ImpostorGhost:
                return IM_COL32(255, 60, 60, 240);
            case Off::CrewmateGhost:
                return IM_COL32(180, 180, 180, 200);
            default:
                return IM_COL32(120, 220, 255, 240);
        }
    }

    // World → screen conversion. We piggyback on the game's Camera.main by
    // reading its cached world→viewport matrix out of the HudManager's cam.
    // For a first cut we approximate: player local pos → offset from local
    // player pixel coords, scaled by an ImGui-visible zoom guess.
    ImVec2 WorldToScreen(Vector2 world, Vector2 origin) {
        // The vanilla camera is ortho, size ~5 units → screen height.
        ImGuiIO& io = ImGui::GetIO();
        float unit = io.DisplaySize.y / 10.0f;
        return ImVec2(io.DisplaySize.x*0.5f + (world.x - origin.x) * unit,
                      io.DisplaySize.y*0.5f - (world.y - origin.y) * unit);
    }
}

namespace ESP {

void Draw() {
    if (!Cfg::roleESP.load() && !Cfg::boxESP.load() && !Cfg::distanceESP.load()) return;

    auto snap = Hooks::Snapshot();   // copy under lock avoided; snapshot mutation is append-only
    if (snap.empty()) return;

    Vector2 origin = {0,0};
    for (auto& p : snap) if (p.local) { origin = p.pos; break; }

    ImDrawList* dl = ImGui::GetForegroundDrawList();

    for (auto& p : snap) {
        if (p.dead || p.local) continue;
        ImVec2 s = WorldToScreen(p.pos, origin);

        if (Cfg::boxESP.load()) {
            dl->AddRect(ImVec2(s.x-24, s.y-40), ImVec2(s.x+24, s.y+8), ColorFor(p.role), 2.0f, 0, 1.5f);
        }
        if (Cfg::roleESP.load()) {
            const char* n = RoleName(p.role);
            ImVec2 ts = ImGui::CalcTextSize(n);
            dl->AddRectFilled(ImVec2(s.x - ts.x*0.5f - 4, s.y - 58),
                              ImVec2(s.x + ts.x*0.5f + 4, s.y - 42),
                              IM_COL32(0,0,0,160), 3.0f);
            dl->AddText(ImVec2(s.x - ts.x*0.5f, s.y - 56), ColorFor(p.role), n);
        }
        if (Cfg::distanceESP.load()) {
            float dx = p.pos.x - origin.x, dy = p.pos.y - origin.y;
            char buf[16]; snprintf(buf, sizeof buf, "%.1fm", __builtin_sqrtf(dx*dx + dy*dy));
            dl->AddText(ImVec2(s.x + 10, s.y - 6), IM_COL32(255,255,255,220), buf);
        }
    }
}

} // ESP
