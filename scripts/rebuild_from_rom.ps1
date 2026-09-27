# One-click: regenerate guest code from YOUR ROM and tell you how to build.
#   .\scripts\rebuild_from_rom.ps1 -Rom "path\to\your.gba"
param(
    [Parameter(Mandatory = $true)][string]$Rom,
    [string]$GbaRecompRoot = "",
    [string]$SdlRoot = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

& (Join-Path $root "scripts\generate.ps1") -Rom $Rom
if ($LASTEXITCODE -ne 0) { throw "generate.ps1 failed" }

Write-Host ""
Write-Host "Guest code installed under src/game (local only)." -ForegroundColor Green
Write-Host "Build the player next:"
Write-Host "  .\build.ps1 -GbaRecompRoot `"<path-to-gbarecomp>`" -SdlRoot `"<path-to-SDL2>`""
