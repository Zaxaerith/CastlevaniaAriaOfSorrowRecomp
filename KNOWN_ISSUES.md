# Cleanup and reproducibility status

As of 2026-10-02: generated/build cleanup completed;
**BLOCKED: framework reproducibility** remains.

The current CMake configuration links six prebuilt GBARecomp static libraries
from an external `build-vs/Release` directory. The available framework checkout
has no Git metadata, and this project records no exact upstream commit or
retrievable, checksummed framework snapshot. Its upstream URL alone is not
enough to reproduce the currently used source and libraries. No dependency
setup or cold rebuild PASS record was found in this project.

The follow-up cleanup removes the build tree, ROM-derived `src/game/`, and
the reinstallable SDL2 SDK. The sole local game ROM is retained. SDL2 2.32.8
can be restored with `scripts/setup-sdl2.ps1`; its license is retained under
`third_party_licenses/`. No framework, CLI, BIOS, or sibling-project files
were modified. Cold build, smoke, and save/load remain unverified; the blocked
dependency provenance is no longer a reason to retain regenerable artifacts.

ROM-derived `src/game/` files and SDL2 DLL/import-library files have been removed
from the Git index and deleted locally. CMakeLists.txt
and the SDL2 license are now exempt from the broad text-file ignore rule.
The existing agent prompt remains local and ignored. Existing user changes
to the desktop host were preserved.

Git history still contains ROM-derived guest translation units and SDL2 binary
artifacts. Cleanup does not rewrite history, change the existing remote, or
push. A clean release history requires a separate user decision.

To unblock cleanup, identify and pin the exact recoverable GBARecomp revision
(including dependency and BIOS generation requirements), supply a reproducible
dependency setup procedure, and verify regen plus a cold host build and short
smoke. Regenerate code and restore dependencies when building; delete generated
and build artifacts again after verification. Runtime claims
in README reflect earlier project status, not verification by this cleanup.
