# Third-party components

## SDL2

SDL2 2.32.8 VC development files are installed locally under `vendor/SDL2/`
by `scripts/setup-sdl2.ps1`. The SDK is ignored and removed after cleanup.

- Project: https://www.libsdl.org/
- License: zlib License (see `third_party_licenses/SDL2-LICENSE.txt`)

SDL2 is used for the game window, keyboard/gamepad input, and audio output.

## GBARecomp framework

Built and linked externally via `GBARECOMP_ROOT` (not vendored here).

- Project: https://github.com/mstan/gbarecomp
- License: see the framework repository (Mozilla Public License 2.0 in tree)

## Game ROM / BIOS

Not included. You must supply your own legally obtained Castlevania: Aria of
Sorrow (USA) GBA ROM and a GBA BIOS dump. Nintendo / Konami retain all rights
to the original game.
