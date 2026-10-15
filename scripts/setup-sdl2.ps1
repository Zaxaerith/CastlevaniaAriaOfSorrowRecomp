# Restore the fixed SDL2 VC SDK used by the MSVC build. Project-local only.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = '2.32.8'
$destination = Join-Path $root 'vendor/SDL2'
if (Test-Path -LiteralPath (Join-Path $destination 'lib/x64/SDL2.lib')) {
    Write-Host "SDL2 $version SDK already present."
    return
}
$temporary = Join-Path $root '.deps/sdl2-setup'
New-Item -ItemType Directory -Path $temporary -Force | Out-Null
$archive = Join-Path $temporary 'SDL2-devel-VC.zip'
$url = "https://github.com/libsdl-org/SDL/releases/download/release-$version/SDL2-devel-$version-VC.zip"
Invoke-WebRequest -Uri $url -OutFile $archive
Expand-Archive -LiteralPath $archive -DestinationPath $temporary -Force
$sdk = Join-Path $temporary "SDL2-$version"
if (-not (Test-Path -LiteralPath (Join-Path $sdk 'lib/x64/SDL2.lib'))) {
    throw 'SDL2 archive did not contain the expected VC SDK.'
}
New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $sdk | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse -Force
}
Write-Host "SDL2 $version restored at $destination. Remove vendor/SDL2 and .deps after building."
