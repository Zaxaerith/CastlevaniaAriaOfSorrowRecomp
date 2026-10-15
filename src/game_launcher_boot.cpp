// Castlevania: Aria of Sorrow (USA, A2CE) — launcher seam & input validation.
#include "launcher_seam.h"
#include "sha1.h"

#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

int game_launcher_preboot(std::vector<std::string>& args, const gbarecomp::RunOptions& options) {
    return gbarecomp_launcher_preboot(args, options);
}

// Strict verification for retail GBA BIOS and USA A2CE ROM
int game_validate_inputs(std::vector<std::string>& args, const gbarecomp::RunOptions& options) {
    std::string path, rom_path;
    for (std::size_t i = 1; i < args.size(); ++i) {
        if (args[i] == "--help" || args[i] == "-h") return 0;
        if (args[i] == "--bios" && i + 1 < args.size()) path = args[++i];
        else if (args[i] == "--rom" && i + 1 < args.size()) rom_path = args[++i];
    }

    const auto exe_dir = std::filesystem::path(gbarecomp_seam::exe_dir(args));

    // BIOS discovery & validation
    if (path.empty()) {
        path = gbarecomp_seam::read_single_line((exe_dir / "bios.cfg").string());
    }
    if (path.empty()) {
        if (std::filesystem::exists(exe_dir / "gba_bios.bin")) {
            path = (exe_dir / "gba_bios.bin").string();
        } else if (std::filesystem::exists(exe_dir / "bios" / "gba_bios.bin")) {
            path = (exe_dir / "bios" / "gba_bios.bin").string();
        } else if (std::filesystem::exists("gba_bios.bin")) {
            path = "gba_bios.bin";
        } else if (std::filesystem::exists("bios/gba_bios.bin")) {
            path = "bios/gba_bios.bin";
        }
    }
    if (path.empty()) {
        std::fprintf(stderr, "[aos] Retail GBA BIOS required: select it in the launcher or pass --bios.\n");
        return 1;
    }

    gba::GbaBios bios;
    std::string error;
    if (!bios.load_from_file(path, gba::GbaBios::kExpectedSha1, &error)) {
        std::fprintf(stderr, "[aos] BIOS identity rejected: %s\n", error.c_str());
        return 1;
    }

    // ROM discovery & validation
    if (rom_path.empty()) {
        rom_path = gbarecomp_seam::read_single_line((exe_dir / "rom.cfg").string());
    }
    if (rom_path.empty()) {
        if (std::filesystem::exists(exe_dir / "Castlevania - Aria of Sorrow(US)(Konami)(64Mb).gba")) {
            rom_path = (exe_dir / "Castlevania - Aria of Sorrow(US)(Konami)(64Mb).gba").string();
        } else if (std::filesystem::exists(exe_dir / "Castlevania - Aria of Sorrow (USA).gba")) {
            rom_path = (exe_dir / "Castlevania - Aria of Sorrow (USA).gba").string();
        } else if (std::filesystem::exists("Castlevania - Aria of Sorrow(US)(Konami)(64Mb).gba")) {
            rom_path = "Castlevania - Aria of Sorrow(US)(Konami)(64Mb).gba";
        } else if (std::filesystem::exists("Castlevania - Aria of Sorrow (USA).gba")) {
            rom_path = "Castlevania - Aria of Sorrow (USA).gba";
        }
    }
    if (rom_path.empty()) {
        std::fprintf(stderr, "[aos] ROM required: select it in the launcher or pass --rom.\n");
        return 1;
    }

    std::ifstream rom(rom_path, std::ios::binary | std::ios::ate);
    constexpr std::size_t kAosRomSize = 8388608; // 8 MiB
    if (!rom || static_cast<std::size_t>(rom.tellg()) != kAosRomSize) {
        std::fprintf(stderr, "[aos] Expected the 8 MiB USA A2CE ROM; select it in the launcher or pass --rom.\n");
        return 1;
    }

    std::vector<std::uint8_t> bytes(kAosRomSize);
    rom.seekg(0);
    rom.read(reinterpret_cast<char*>(bytes.data()), bytes.size());
    if (!rom || bytes.size() < 0xAC + 4) {
        std::fprintf(stderr, "[aos] Failed reading ROM header.\n");
        return 1;
    }

    // Verify game code 'A2CE' at offset 0xAC
    if (std::memcmp(&bytes[0xAC], "A2CE", 4) != 0) {
        std::fprintf(stderr, "[aos] Game code mismatch at 0xAC; expected 'A2CE'.\n");
        return 1;
    }

    // Verify SHA-1 hash against options.builtin_rom_sha1
    const std::string computed_sha1 = gba::sha1(bytes.data(), bytes.size()).hex();
    auto to_lower = [](std::string s) {
        for (char& c : s) if (c >= 'A' && c <= 'Z') c = static_cast<char>(c + 32);
        return s;
    };
    if (to_lower(computed_sha1) != to_lower(options.builtin_rom_sha1)) {
        std::fprintf(stderr, "[aos] ROM SHA-1 mismatch; expected %s, got %s.\n",
                     options.builtin_rom_sha1, computed_sha1.c_str());
        return 1;
    }

    // Pass validated inputs to runtime
    args.emplace_back("--rom");
    args.emplace_back(rom_path);
    args.emplace_back("--bios");
    args.emplace_back(path);
    args.emplace_back("--rom-sha1");
    args.emplace_back(options.builtin_rom_sha1);

    // Note: Do NOT add --bios-hle! Aria of Sorrow strictly preserves LLE BIOS.
    return 0;
}
