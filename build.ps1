param(
    [string]$BuildType = "Release",
    [string]$GbaRecompRoot = "",
    [string]$SdlRoot = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

Write-Host "=== Castlevania: Aria of Sorrow (GBARecomp) Builder ===" -ForegroundColor Cyan

if (-not $GbaRecompRoot) {
    if ($env:GBARECOMP_ROOT) { $GbaRecompRoot = $env:GBARECOMP_ROOT }
    else { $GbaRecompRoot = Join-Path (Split-Path -Parent $ProjectRoot) "gbarecomp-main" }
}
if (-not $SdlRoot) {
    if ($env:SDL2_ROOT) { $SdlRoot = $env:SDL2_ROOT }
    else { $SdlRoot = Join-Path $ProjectRoot "vendor/SDL2" }
}

$cmake = Get-Command cmake.exe -ErrorAction SilentlyContinue
if (-not $cmake) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $cmakePath = & $vswhere -latest -products * -find "Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe" | Select-Object -First 1
        if ($cmakePath) { $cmake = Get-Item $cmakePath }
    }
}
if (-not $cmake) { throw "CMake not found" }

New-Item -ItemType Directory -Force -Path "build" | Out-Null
Push-Location "build"
try {
    & $cmake.Source .. -A x64 "-DGBARECOMP_ROOT=$GbaRecompRoot" "-DSDL2_ROOT=$SdlRoot"
    if ($LASTEXITCODE -ne 0) { throw "CMake configure failed" }
    & $cmake.Source --build . --config $BuildType --parallel
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }
    Write-Host "Build successful: build/$BuildType/CastlevaniaAriaOfSorrowRecomp.exe" -ForegroundColor Green
}
finally {
    Pop-Location
}
