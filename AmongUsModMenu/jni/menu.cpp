#include "menu.h"
#include "config.h"

#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_android.h"
#include "imgui/backends/imgui_impl_opengl3.h"

#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <android/native_window.h>
#include <android/log.h>
#include <thread>
#include <atomic>

#define LOG(...) __android_log_print(ANDROID_LOG_INFO, "AUModMenu", __VA_ARGS__)

namespace {
    std::atomic<bool> g_open{false};

    void DrawWindow() {
        ImGui::SetNextWindowSize(ImVec2(340, 460), ImGuiCond_FirstUseEver);
        ImGui::SetNextWindowPos (ImVec2(40, 100), ImGuiCond_FirstUseEver);
        if (!ImGui::Begin("Among Us  ·  Nyx Menu", nullptr,
                          ImGuiWindowFlags_NoCollapse)) { ImGui::End(); return; }

        // ---- Impostor ----
        if (ImGui::CollapsingHeader("Impostor", ImGuiTreeNodeFlags_DefaultOpen)) {
            bool force = Cfg::impostorForce.load();
            if (ImGui::Checkbox("Force impostor by %", &force)) Cfg::impostorForce = force;

            int pct = Cfg::impostorChance.load();
            if (ImGui::SliderInt("Chance", &pct, 0, 100, "%d%%")) Cfg::impostorChance = pct;

            static const char* names[] = { "Vanilla Impostor", "Viper", "Shapeshifter", "Phantom" };
            int role = Cfg::impostorRole.load();
            if (ImGui::Combo("Sub-role", &role, names, IM_ARRAYSIZE(names))) Cfg::impostorRole = role;
        }

        // ---- Vision ----
        if (ImGui::CollapsingHeader("Vision", ImGuiTreeNodeFlags_DefaultOpen)) {
            bool wh = Cfg::wallhack.load();
            if (ImGui::Checkbox("Wallhack (see through walls)", &wh)) Cfg::wallhack = wh;

            bool vm = Cfg::visionMul.load();
            if (ImGui::Checkbox("Vision multiplier", &vm)) Cfg::visionMul = vm;

            float s = Cfg::visionScale.load();
            if (ImGui::SliderFloat("Multiplier", &s, 1.0f, 8.0f, "%.1fx")) Cfg::visionScale = s;
        }

        // ---- ESP ----
        if (ImGui::CollapsingHeader("ESP", ImGuiTreeNodeFlags_DefaultOpen)) {
            bool re = Cfg::roleESP.load();
            if (ImGui::Checkbox("Role names above players", &re)) Cfg::roleESP = re;
            bool be = Cfg::boxESP.load();
            if (ImGui::Checkbox("Boxes",     &be)) Cfg::boxESP = be;
            bool de = Cfg::distanceESP.load();
            if (ImGui::Checkbox("Distance",  &de)) Cfg::distanceESP = de;
        }

        // ---- Anti-punishment ----
        if (ImGui::CollapsingHeader("Anti-punishment", ImGuiTreeNodeFlags_DefaultOpen)) {
            bool at = Cfg::antiTimeout.load();
            if (ImGui::Checkbox("Anti-timeout (skip leave penalty)", &at)) Cfg::antiTimeout = at;
            bool ab = Cfg::antiBan.load();
            if (ImGui::Checkbox("Anti-ban (drop reputation flag)",   &ab)) Cfg::antiBan = ab;
        }

        // ---- Chat ----
        if (ImGui::CollapsingHeader("Chat", ImGuiTreeNodeFlags_DefaultOpen)) {
            bool fc = Cfg::freeChat.load();
            if (ImGui::Checkbox("Free chat (dead / meeting / muted / moving)", &fc)) Cfg::freeChat = fc;
        }

        ImGui::Separator();
        ImGui::TextDisabled("Tap N to hide.");
        ImGui::End();
    }

    // Floating button
    void DrawButton() {
        ImGuiIO& io = ImGui::GetIO();
        ImGui::SetNextWindowPos(ImVec2(io.DisplaySize.x - 90, io.DisplaySize.y - 120));
        ImGui::SetNextWindowBgAlpha(0.35f);
        ImGui::Begin("##btn", nullptr,
            ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove     | ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);
        if (ImGui::Button(g_open ? "×" : "N", ImVec2(52, 52))) g_open = !g_open;
        ImGui::End();
    }
}

namespace Menu {

void Init() {
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr;
    ImGui::StyleColorsDark();

    // Backend init happens in the swap hook thread inside main.cpp,
    // this Init only builds the ImGui context.
    LOG("menu ctx ready");
}

void Toggle() { g_open = !g_open; }

void Draw() {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplAndroid_NewFrame();
    ImGui::NewFrame();

    DrawButton();
    if (g_open) DrawWindow();
    ESP::Draw();

    ImGui::Render();
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

} // Menu
