param(
    [string]$Version = '0.1.0-preview',
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if ($Version -notmatch '^\d+\.\d+\.\d+(-[a-z0-9.-]+)?$') { throw 'Invalid version' }

$pinPath = "$root/docs/FRAMEWORK_PIN.json"
if (Test-Path $pinPath) {
    $pin = Get-Content $pinPath -Raw | ConvertFrom-Json
    $uiHead = & git -C "$root/recomp-ui" rev-parse HEAD
    if ($LASTEXITCODE -eq 0 -and $pin.recomp_ui_commit -and $uiHead -ne $pin.recomp_ui_commit) {
        Write-Warning "recomp-ui HEAD ($uiHead) differs from pin ($($pin.recomp_ui_commit))"
    }
}

if (-not $SkipBuild) {
    & "$root/build.ps1" -BuildType Release -Jobs 2
}

$buildDir = "$root/build/Release"
if (-not (Test-Path "$buildDir/CastlevaniaAriaOfSorrowRecomp.exe")) {
    throw "CastlevaniaAriaOfSorrowRecomp.exe not found at $buildDir"
}

$name = "CastlevaniaAriaOfSorrowRecomp-windows-x64-v$Version"
$stage = "$root/release-stage/$name"
$zip = "$stage.zip"
if (Test-Path -LiteralPath $stage) { Remove-Item -Recurse -Force -LiteralPath $stage }
if (Test-Path -LiteralPath $zip) { Remove-Item -Force -LiteralPath $zip }
if (Test-Path -LiteralPath "$zip.sha256") { Remove-Item -Force -LiteralPath "$zip.sha256" }

New-Item -ItemType Directory -Path "$stage/licenses/mpl-source" -Force | Out-Null
New-Item -ItemType Directory -Path "$stage/config" -Force | Out-Null

# 1. Executables and DLLs
Copy-Item -LiteralPath "$buildDir/CastlevaniaAriaOfSorrowRecomp.exe" -Destination "$stage/CastlevaniaAriaOfSorrowRecomp.exe"
Copy-Item -LiteralPath "$buildDir/SDL2.dll" -Destination "$stage/SDL2.dll"

# 2. recomp-ui assets
$assets = @(
    'fonts/LatoLatin-Regular.ttf','fonts/LatoLatin-Bold.ttf','fonts/OpenMoji-black-glyf.ttf','fonts/NotoSansSymbols2-Regular.ttf',
    'img/brand_mark.tga','img/verdict_ok.tga','img/verdict_warn.tga','img/verdict_bad.tga','img/verdict_none.tga','img/flags.png','img/pad_gba.tga'
)
foreach ($asset in $assets) {
    $srcAsset = "$buildDir/assets/$asset"
    if (-not (Test-Path $srcAsset)) {
        $srcAsset = "$root/recomp-ui/assets/common/$asset"
        if (-not (Test-Path $srcAsset)) {
            $srcAsset = "$root/recomp-ui/assets/consoles/gba/$asset"
        }
    }
    if (Test-Path $srcAsset) {
        $destPath = "$stage/assets/$asset"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destPath) | Out-Null
        Copy-Item -LiteralPath $srcAsset -Destination $destPath
    } else {
        Write-Warning "Asset not found: $asset"
    }
}

# 3. Game config
if (Test-Path "$root/config/game.toml") {
    Copy-Item -LiteralPath "$root/config/game.toml" -Destination "$stage/config/game.toml"
}

# 4. Documentation & notices
Copy-Item -LiteralPath "$root/LICENSE" -Destination "$stage/LICENSE"
Copy-Item -LiteralPath "$root/THIRD_PARTY_NOTICES.md" -Destination "$stage/THIRD_PARTY_NOTICES.md"
Copy-Item -LiteralPath "$root/README.md" -Destination "$stage/README.md"
if (Test-Path "$root/README.zh-CN.md") {
    Copy-Item -LiteralPath "$root/README.zh-CN.md" -Destination "$stage/README.zh-CN.md"
}

# 5. Third-party licenses
$frameworkRoot = "$root/../gbarecomp-main"
$licenses = @{
    'GBARecomp'="$root/third_party_licenses/gbarecomp-LICENSE.txt"
    'RecompUI'="$root/recomp-ui/LICENSE"
    'ImGui'="$root/recomp-ui/src/third_party/imgui/LICENSE.txt"
    'Font-Notices'="$root/recomp-ui/assets/common/fonts/NOTICE.md"
    'Image-Notices'="$root/recomp-ui/assets/common/img/NOTICE.md"
    'SDL2'="$root/third_party_licenses/SDL2-LICENSE.txt"
}
if (Test-Path "$frameworkRoot/third_party/MPL-2.0.txt") {
    $licenses['MPL-2.0'] = "$frameworkRoot/third_party/MPL-2.0.txt"
}
if (Test-Path "$frameworkRoot/THIRD_PARTY_ATTRIBUTION.md") {
    $licenses['Framework-Attribution'] = "$frameworkRoot/THIRD_PARTY_ATTRIBUTION.md"
}

foreach ($key in $licenses.Keys) {
    if (Test-Path $licenses[$key]) {
        Copy-Item -LiteralPath $licenses[$key] -Destination "$stage/licenses/$key.txt"
    }
}

# 6. MPL source compliance
foreach ($file in @('bios_hle.cpp','bios_hle.h')) {
    $src = "$frameworkRoot/src/runtime/$file"
    if (Test-Path $src) {
        Copy-Item -LiteralPath $src -Destination "$stage/licenses/mpl-source/$file"
    }
}

# 7. Audit: strict check against prohibited files
$prohibited = Get-ChildItem -LiteralPath $stage -Recurse -File | Where-Object {
    $_.Extension -match '^\.(gba|sav|srm|bin|obj|lib|pdb|log)$' -or
    $_.Name -match '^(gba_bios\.bin|open_gba_bios\.bin|CMakeCache\.txt)$'
}
if ($prohibited) {
    throw "Prohibited file found in release staging: $($prohibited.FullName)"
}

# 8. Manifest generation
$manifest = @(Get-ChildItem -LiteralPath $stage -Recurse -File | Sort-Object FullName | ForEach-Object {
    [pscustomobject]@{
        file = $_.FullName.Substring($stage.Length+1).Replace('\','/')
        bytes = $_.Length
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
})
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$stage/manifest.json" -Encoding utf8

# 9. Create zip package
Write-Host "==> Creating release archive: $zip"
Compress-Archive -Path "$stage/*" -DestinationPath $zip -CompressionLevel Optimal
$zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$zipHash  $([System.IO.Path]::GetFileName($zip))" | Set-Content -LiteralPath "$zip.sha256" -Encoding ascii

Write-Host "PASS: Windows x64 Preview package created at $stage"
Write-Host "      Archive: $zip ($((Get-Item $zip).Length) bytes, SHA256: $zipHash)"
