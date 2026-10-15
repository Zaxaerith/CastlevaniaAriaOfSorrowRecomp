$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$zip = Join-Path $root "release-stage\CastlevaniaAriaOfSorrowRecomp-windows-x64-v0.1.0-preview.zip"
$testDir = Join-Path $env:TEMP "aos_release_isolated_test"

Write-Host "=== Testing Release Package ==="
Write-Host "Archive: $zip"
if (-not (Test-Path $zip)) { throw "Release archive not found: $zip" }

if (Test-Path $testDir) { Remove-Item -Recurse -Force $testDir }
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

Write-Host "Extracting to: $testDir"
Expand-Archive -LiteralPath $zip -DestinationPath $testDir

$manifestPath = Join-Path $testDir "manifest.json"
if (-not (Test-Path $manifestPath)) { throw "manifest.json not found in release package" }

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
Write-Host "Manifest file count: $($manifest.Count)"

$failed = 0
foreach ($entry in $manifest) {
    $filePath = Join-Path $testDir $entry.file
    if (-not (Test-Path $filePath)) {
        Write-Host "MISSING: $($entry.file)"
        $failed++
        continue
    }
    $actualHash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $entry.sha256) {
        Write-Host "HASH MISMATCH: $($entry.file)"
        $failed++
    }
}
if ($failed -gt 0) { throw "Manifest verification failed with $failed errors" }
Write-Host "All manifest files and SHA-256 hashes verified OK."

# Test execution with clean PATH (no developer toolchain in PATH)
$exe = Join-Path $testDir "CastlevaniaAriaOfSorrowRecomp.exe"
$rom = (Get-ChildItem -LiteralPath $root -Filter *.gba | Select-Object -First 1).FullName
$bios = "D:\Project\GameRecomp\WarioLand4Recomp\bios\gba_bios.bin"

$oldPath = $env:PATH
$env:PATH = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem"

try {
    Write-Host "Running release binary with isolated PATH (no toolchain)..."
    $p = Start-Process -FilePath $exe -ArgumentList @("--rom", "`"$rom`"", "--bios", "`"$bios`"", "--frames", "60", "--no-window") -WorkingDirectory $testDir -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
        throw "Release binary exited with code $($p.ExitCode)"
    }
    Write-Host "Release binary ran successfully! ExitCode: $($p.ExitCode)"
} finally {
    $env:PATH = $oldPath
}

Write-Host "=== RELEASE VERIFICATION PASSED ==="
