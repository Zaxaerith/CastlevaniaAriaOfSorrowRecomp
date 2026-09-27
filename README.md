# CastlevaniaAriaOfSorrowRecomp

[![Platform](https://img.shields.io/badge/platform-Windows-blue)](#prerequisites)
[![Language](https://img.shields.io/badge/language-C%2B%2B20-orange)](#what-static-recompilation-means-here)
[![License](https://img.shields.io/badge/license-PolyForm--Noncommercial--1.0.0-blue)](LICENSE)

Native static recompilation of **Castlevania: Aria of Sorrow (GBA, USA)** into a standalone Windows executable, built on the [GBARecomp](https://github.com/mstan/gbarecomp) framework.

---

## What "static recompilation" means here

The ARM7TDMI (ARM/Thumb) game code from the original cartridge is translated offline into C++ translation units in `src/game/`, then compiled to native code.

**The rest of the GBA is emulated as hardware** by the shared GBARecomp runtime:

* **PPU** (tile / bitmap modes, OBJ, blending, windows)
* **DMA, timers, interrupts, keypad**
* **APU / Direct Sound**
* **Cartridge save** (SRAM, signature `SRAM_F_V102`)
* **BIOS** (recompiled LLE path)

Recompile the CPU, emulate the silicon.

---

## Current status

- [x] Boots through BIOS intro and Konami logo to title
- [x] New game and opening story (Game Mode `0x04`)
- [x] Character movement, status / equipment menu
- [x] SRAM save (`CASTLEVANIA2-010`) written next to the ROM
- [x] Room / map tables update during exploration
- [x] High static coverage on a typical session (no interpreter bridge in the common path)

---

## Quick start (you supply the ROM)

> [!IMPORTANT]
> **Legal notice.** This repository does **not** include any Nintendo ROM data, GBA BIOS, or copyrighted game assets. **ROM-derived guest translation units are also not committed** — generate them locally from your own dump.

### Verified ROM

| Field | Value |
| :--- | :--- |
| Game | Castlevania: Aria of Sorrow (USA) |
| File name | `Castlevania - Aria of Sorrow(US)(Konami)(64Mb).gba` |
| Size | `8,388,608` bytes |
| Game code | `A2CE` |
| CRC32 | `35536183` |
| SHA1 | `ABD71FE01EBB201BCC133074DB1DD8C5253776C7` |
| Save type | SRAM 32 KiB (`SRAM_F_V102`) |

### BIOS

Provide a GBA BIOS dump as `gba_bios.bin` (16,384 bytes) when launching.

### One-click rebuild from your ROM

```powershell
# 1) Generate guest code from YOUR rom (not shipped in git):
.\scripts\generate.ps1 -Rom "path\to\your.gba"

# 2) Build the player:
.\build.ps1
```

`generate.ps1` runs `gba_recompile`, then `scripts/split_generated.py` to place
functionally named units under `src/game/` (`world_actors.cpp`, `boot_system.cpp`, …).
Raw shards in `src/generated/` stay local and are gitignored.

### Run

```powershell
.\build\Release\CastlevaniaAriaOfSorrowRecomp.exe --rom "path\to\your.gba" --bios "path\to\gba_bios.bin" --window
```

Place `SDL2.dll` next to the executable (staged automatically by `build.ps1` when using the bundled vendor path).

---

## Controls

| Action | Keyboard |
| :--- | :--- |
| Move | Arrow keys |
| Attack | `Z` |
| Jump | `X` |
| L / R | `A` / `S` |
| Start | `Enter` |
| Select | `Backspace` |

---

## Project layout

```
src/host/desktop.cpp          Desktop host entry (GUI subsystem, no auto-input)
src/game/                     Guest translation units (local, ROM-derived — not in git)
src/framework/                Shared recompiler ABI headers
config/game.toml              Function seeds / code-copy map used at generation
scripts/generate.ps1          gba_recompile + split into src/game modules
scripts/split_generated.py
scripts/rebuild_from_rom.ps1
build.ps1
```

> ROM-derived guest code is generated from **your** cartridge dump and is never
> published here. See `scripts/generate.ps1`.

---

## Prerequisites

* Windows 10/11 x64
* Visual Studio 2022+ with C++ desktop workload (MSVC, CMake)
* [GBARecomp](https://github.com/mstan/gbarecomp) built locally (`GBARECOMP_ROOT`)
* SDL2 (VC development package) for the game window
* Your own GBA ROM and BIOS dumps

---

## License

PolyForm Noncommercial License 1.0.0 — see [LICENSE](LICENSE).

You may use and share this project for noncommercial purposes. Commercial use requires a separate license from the copyright holder.

Nintendo, Castlevania, and Aria of Sorrow are trademarks of their respective owners. This project is an unofficial technical study and is not affiliated with or endorsed by Nintendo or Konami.
