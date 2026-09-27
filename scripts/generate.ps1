# Generate ROM-derived guest C++ from YOUR legally dumped ROM, then split
# into functionally named src/game modules (local-only).
#
#   .\scripts\generate.ps1 -Rom "D:\path\to\Castlevania - Aria of Sorrow (USA).gba"

param(
    [Parameter(Mandatory = $true)][string]$Rom,
    [string]$Tool = "",
    [string]$Out = "",
    [string]$Config = "",
    [string]$Shards = "4"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $Config) { $Config = Join-Path $root "config\game.toml" }
if (-not $Out) { $Out = Join-Path $root "src\generated" }

if (-not $Tool) {
    $candidates = @(
        (Join-Path $root "..\gbarecomp-main\build-vs\Release\gba_recompile.exe"),
        (Join-Path $root "..\gbarecomp-main\build\Release\gba_recompile.exe"),
        (Join-Path $root "..\gbarecomp-main\build\gba_recompile.exe")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $Tool = $c; break }
    }
}
if (-not $Tool -or -not (Test-Path $Tool)) {
    throw "gba_recompile.exe not found. Build GBARecomp target 'gba_recompile' or pass -Tool."
}

Write-Host "ROM   : $Rom"
Write-Host "Config: $Config"
Write-Host "Out   : $Out"
Write-Host "Tool  : $Tool"

New-Item -ItemType Directory -Force -Path $Out | Out-Null
& $Tool --rom $Rom --config $Config --out $Out --codegen-shards $Shards
if ($LASTEXITCODE -ne 0) { throw "gba_recompile failed" }

Write-Host "Splitting into src/game modules ..."
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
if ($py) {
    & $py.Source (Join-Path $root "scripts\split_generated.py")
} else {
    throw "Python is required to split generated shards."
}
if ($LASTEXITCODE -ne 0) { throw "split_generated.py failed" }

Write-Host "Done. src/generated/ stays local (gitignored)." -ForegroundColor Green
