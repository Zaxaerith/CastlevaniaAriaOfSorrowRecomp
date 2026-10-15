# Launch the player from the project root (GUI, no console).
#   .\run.ps1
#   .\run.ps1 -Rom "path\to\your.gba" -Bios "path\to\gba_bios.bin"
param(
    [string]$Rom = "",
    [string]$Bios = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$exe = Join-Path $root "build\Release\CastlevaniaAriaOfSorrowRecomp.exe"
if (-not (Test-Path $exe)) {
    throw "Build first: .\build.ps1"
}

$args = @("--window")
if ($Rom)  { $args += @("--rom", $Rom) }
if ($Bios) { $args += @("--bios", $Bios) }

Start-Process -FilePath $exe -ArgumentList $args -WorkingDirectory $root
