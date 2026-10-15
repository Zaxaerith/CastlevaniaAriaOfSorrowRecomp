cmake_minimum_required(VERSION 3.20)
project(CastlevaniaAriaOfSorrowRecomp C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(MSVC)
    add_compile_options(/utf-8)
endif()

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

# ---------------------------------------------------------------------------
# GBARecomp framework
# ---------------------------------------------------------------------------
if(NOT GBARECOMP_ROOT)
    if(DEFINED ENV{GBARECOMP_ROOT})
        set(GBARECOMP_ROOT "$ENV{GBARECOMP_ROOT}")
    else()
        set(GBARECOMP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../gbarecomp-main")
    endif()
endif()
get_filename_component(GBARECOMP_ROOT "${GBARECOMP_ROOT}" ABSOLUTE)
set(GBARECOMP_BUILD "${GBARECOMP_ROOT}/build-vs" CACHE PATH "GBARecomp build tree")

if(NOT EXISTS "${GBARECOMP_ROOT}/src/runtime/runtime.h")
    message(FATAL_ERROR
        "GBARecomp framework not found at ${GBARECOMP_ROOT}.\n"
        "Clone https://github.com/mstan/gbarecomp and pass -DGBARECOMP_ROOT=<path>.")
endif()

set(GBARECOMP_SELFHEAL_RECOMPILE_DEFAULT OFF CACHE BOOL "Preview needs no runtime compiler" FORCE)
set(GBARECOMP_COMPILER_CACHE OFF CACHE STRING "Keep compilation output inside this project")

# ---------------------------------------------------------------------------
# recomp-ui launcher
# ---------------------------------------------------------------------------
if(NOT RECOMP_UI_ROOT)
    set(RECOMP_UI_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/recomp-ui" CACHE PATH "Pinned player launcher" FORCE)
endif()
get_filename_component(RECOMP_UI_ROOT "${RECOMP_UI_ROOT}" ABSOLUTE)

if(NOT EXISTS "${RECOMP_UI_ROOT}/recomp_ui.cmake")
    message(FATAL_ERROR "recomp-ui not found at ${RECOMP_UI_ROOT}")
endif()

include("${RECOMP_UI_ROOT}/recomp_ui.cmake")

# ---------------------------------------------------------------------------
# SDL2 (window / input / audio)
# ---------------------------------------------------------------------------
if(NOT SDL2_ROOT)
    if(DEFINED ENV{SDL2_ROOT})
        set(SDL2_ROOT "$ENV{SDL2_ROOT}")
    else()
        set(SDL2_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/vendor/SDL2")
    endif()
endif()
get_filename_component(SDL2_ROOT "${SDL2_ROOT}" ABSOLUTE)

set(SDL2_INCLUDE_DIR "${SDL2_ROOT}/include")
if(MSVC)
    set(SDL2_LIB "${SDL2_ROOT}/lib/x64/SDL2.lib")
    set(SDL2_DLL "${SDL2_ROOT}/lib/x64/SDL2.dll")
else()
    set(SDL2_LIB "${SDL2_ROOT}/lib/libSDL2.so")
endif()
if(NOT EXISTS "${SDL2_INCLUDE_DIR}/SDL.h" AND NOT EXISTS "${SDL2_INCLUDE_DIR}/SDL2/SDL.h")
    find_package(SDL2 REQUIRED)
    set(SDL2_INCLUDE_DIR ${SDL2_INCLUDE_DIRS})
    set(SDL2_LIB ${SDL2_LIBRARIES})
endif()

# ---------------------------------------------------------------------------
# Launcher UI library
# ---------------------------------------------------------------------------
add_library(game_launcher_ui STATIC src/game_launcher_boot.cpp)
target_include_directories(game_launcher_ui PRIVATE
    "${GBARECOMP_ROOT}/src/runtime"
    "${GBARECOMP_ROOT}/src/gba"
    "${SDL2_INCLUDE_DIR}"
    "${SDL2_INCLUDE_DIR}/SDL2"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/framework"
)
recomp_target_launcher_ui(game_launcher_ui CONSOLE gba)
target_link_libraries(game_launcher_ui PUBLIC "${SDL2_LIB}")

# ---------------------------------------------------------------------------
# Generated guest translation units (ROM-derived C++)
# ---------------------------------------------------------------------------
file(GLOB GAME_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/game/*.cpp")
if(NOT GAME_SOURCES)
    message(FATAL_ERROR
        "No guest code in src/game/.\n"
        "Generate it from YOUR rom:\n"
        "  .\\scripts\\generate.ps1 -Rom \"path\\to\\Castlevania - Aria of Sorrow (USA).gba\"")
endif()

add_library(aos_guest_code STATIC ${GAME_SOURCES})
target_include_directories(aos_guest_code PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/src/game"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/framework"
    "${GBARECOMP_ROOT}/src/armv4t"
    "${GBARECOMP_ROOT}/src/runtime"
)
if(MSVC)
    target_compile_options(aos_guest_code PRIVATE /utf-8 /W3 /EHsc /O1
        "/FI${CMAKE_CURRENT_SOURCE_DIR}/src/framework/runtime_tail_macros.h")
else()
    target_compile_options(aos_guest_code PRIVATE -O1 -g0
        "-include" "${CMAKE_CURRENT_SOURCE_DIR}/src/framework/runtime_tail_macros.h")
endif()

# ---------------------------------------------------------------------------
# Desktop player executable
# ---------------------------------------------------------------------------
add_executable(CastlevaniaAriaOfSorrowRecomp src/main.cpp)
set_target_properties(CastlevaniaAriaOfSorrowRecomp PROPERTIES
    OUTPUT_NAME "CastlevaniaAriaOfSorrowRecomp"
    WIN32_EXECUTABLE TRUE
)

target_include_directories(CastlevaniaAriaOfSorrowRecomp PRIVATE
    "${GBARECOMP_ROOT}/src/runtime"
    "${GBARECOMP_ROOT}/src/armv4t"
    "${GBARECOMP_ROOT}/src/gba"
    "${GBARECOMP_ROOT}/src/debug"
    "${RECOMP_UI_ROOT}/src"
    "${RECOMP_UI_ROOT}/src/common"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/framework"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/game"
    "${SDL2_INCLUDE_DIR}"
    "${SDL2_INCLUDE_DIR}/SDL2"
)

target_compile_definitions(CastlevaniaAriaOfSorrowRecomp PRIVATE
    GBARECOMP_WINDOW_TITLE="Castlevania: Aria of Sorrow"
    GBARECOMP_DEFAULT_GAME_CONFIG="config/game.toml"
    RECOMP_LAUNCHER
)

if(MSVC)
    target_compile_options(CastlevaniaAriaOfSorrowRecomp PRIVATE /utf-8 /W3 /EHsc /wd4996)
    target_link_options(CastlevaniaAriaOfSorrowRecomp PRIVATE "/STACK:16777216" "/SUBSYSTEM:WINDOWS")
endif()

set(GBARECOMP_LIBS
    "${GBARECOMP_BUILD}/Release/gbarecomp_runtime.lib"
    "${GBARECOMP_BUILD}/Release/gbarecomp_debug.lib"
    "${GBARECOMP_BUILD}/Release/gbarecomp_heal_gate.lib"
    "${GBARECOMP_BUILD}/Release/gbarecomp_recompile_core.lib"
    "${GBARECOMP_BUILD}/Release/gbarecomp_gba.lib"
    "${GBARECOMP_BUILD}/Release/gbarecomp_armv4t.lib"
)
foreach(lib ${GBARECOMP_LIBS})
    if(NOT EXISTS "${lib}")
        message(FATAL_ERROR "Missing GBARecomp library: ${lib}")
    endif()
endforeach()

target_link_libraries(CastlevaniaAriaOfSorrowRecomp PRIVATE
    game_launcher_ui
    aos_guest_code
    ${GBARECOMP_LIBS}
    "${SDL2_LIB}"
    opengl32 user32 gdi32 shell32 comdlg32 winmm ws2_32 imm32 version ole32 oleaut32 uuid advapi32 setupapi
)

recomp_stage_launcher_assets(CastlevaniaAriaOfSorrowRecomp CONSOLE gba)

if(MSVC AND EXISTS "${SDL2_DLL}")
    add_custom_command(TARGET CastlevaniaAriaOfSorrowRecomp POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${SDL2_DLL}" "$<TARGET_FILE_DIR:CastlevaniaAriaOfSorrowRecomp>/SDL2.dll"
        COMMENT "Staging SDL2.dll")
endif()

add_custom_command(TARGET CastlevaniaAriaOfSorrowRecomp POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/config"
        "$<TARGET_FILE_DIR:CastlevaniaAriaOfSorrowRecomp>/config"
    COMMENT "Staging config directory")

# ---------------------------------------------------------------------------
# Launcher contract test target
# ---------------------------------------------------------------------------
add_executable(launcher_contract EXCLUDE_FROM_ALL tests/launcher_contract.cpp)
target_compile_definitions(launcher_contract PRIVATE RECOMP_LAUNCHER)
target_include_directories(launcher_contract PRIVATE
    "${GBARECOMP_ROOT}/src/runtime"
    "${GBARECOMP_ROOT}/src/gba"
    "${RECOMP_UI_ROOT}/src"
    "${RECOMP_UI_ROOT}/src/common"
    "${SDL2_INCLUDE_DIR}"
    "${SDL2_INCLUDE_DIR}/SDL2"
)
target_link_libraries(launcher_contract PRIVATE
    game_launcher_ui
    "${GBARECOMP_BUILD}/Release/gbarecomp_gba.lib"
    "${SDL2_LIB}"
    opengl32 user32 gdi32 shell32 comdlg32 winmm ws2_32 imm32 version ole32 oleaut32 uuid advapi32 setupapi
)

if(MSVC AND EXISTS "${SDL2_DLL}")
    add_custom_command(TARGET launcher_contract POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${SDL2_DLL}" "$<TARGET_FILE_DIR:launcher_contract>/SDL2.dll"
        COMMENT "Staging SDL2.dll for launcher_contract")
endif()
