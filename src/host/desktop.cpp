// Castlevania: Aria of Sorrow — desktop host entry (GBARecomp).
// Starts a normal interactive session: no auto-input, no demo playback,
// no diagnostic file output.

#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

#include "runtime.h"

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>
#endif

namespace {

void silence_runtime_diagnostics() {
    // Route framework self-heal / coverage dumps to a temp path, then the
    // process exit hook removes them so the working tree stays clean.
#ifdef _WIN32
    char tmp[MAX_PATH];
    DWORD n = GetTempPathA(MAX_PATH, tmp);
    if (n == 0 || n >= MAX_PATH) return;
    std::string dir(tmp);
    SetEnvironmentVariableA("GBARECOMP_MISS_FRAG",
                            (dir + "aos_miss_proposals.toml.frag").c_str());
    SetEnvironmentVariableA("GBARECOMP_COVERAGE_JSON",
                            (dir + "aos_coverage.json").c_str());
    SetEnvironmentVariableA("GBARECOMP_FP_SAVE", "");
    SetEnvironmentVariableA("GBARECOMP_IRQ_LOG", "");
    SetEnvironmentVariableA("GBARECOMP_SWI_LOG", "");
    SetEnvironmentVariableA("GBARECOMP_WRAM_TRACE", "");
#else
    setenv("GBARECOMP_MISS_FRAG", "/tmp/aos_miss_proposals.toml.frag", 1);
    setenv("GBARECOMP_COVERAGE_JSON", "/tmp/aos_coverage.json", 1);
#endif
}

void remove_if_exists(const char* path) {
    if (path && path[0]) {
        std::remove(path);
    }
}

void cleanup_runtime_diagnostics() {
    const char* frag = std::getenv("GBARECOMP_MISS_FRAG");
    const char* cov = std::getenv("GBARECOMP_COVERAGE_JSON");
    remove_if_exists(frag);
    remove_if_exists(cov);
    // Legacy / default locations next to the executable or CWD.
    remove_if_exists("recomp_master_misses_A2CE.toml.frag");
    remove_if_exists("recomp_coverage.json");
    remove_if_exists("recomp_seed_proposals.toml");
}

}  // namespace

int main(int argc, char** argv) {
    silence_runtime_diagnostics();
    std::atexit(cleanup_runtime_diagnostics);

    gbarecomp::RunOptions opts;
    opts.builtin_game_name = "Castlevania: Aria of Sorrow";
    opts.builtin_rom_sha1 = "ABD71FE01EBB201BCC133074DB1DD8C5253776C7";
    opts.builtin_rom_crc32 = 0x35536183u;
    opts.show_fps_by_default = false;
    opts.max_view_width = 240;
    opts.freely_resizable_window = true;

    return gbarecomp::run_game(argc, argv, opts);
}

#ifdef _WIN32
// GUI subsystem entry: no console window behind the game window.
int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    int argc = 0;
    LPWSTR* argv_w = CommandLineToArgvW(GetCommandLineW(), &argc);
    std::vector<std::string> args;
    std::vector<char*> argv;
    args.reserve(static_cast<size_t>(argc));
    argv.reserve(static_cast<size_t>(argc) + 1);
    for (int i = 0; i < argc; ++i) {
        char buf[MAX_PATH * 2];
        WideCharToMultiByte(CP_UTF8, 0, argv_w[i], -1, buf, sizeof(buf), nullptr, nullptr);
        args.emplace_back(buf);
    }
    if (argv_w) LocalFree(argv_w);
    for (auto& s : args) argv.push_back(s.data());
    argv.push_back(nullptr);
    return main(argc, argv.data());
}
#endif
