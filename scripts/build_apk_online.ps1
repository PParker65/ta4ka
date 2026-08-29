$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$pubspec = Join-Path $root "pubspec.yaml"
$flutter = "C:\Users\Surface\flutter\bin\flutter.bat"
$release = Join-Path $root "release"
$cdnBase = $args[0]
if (-not $cdnBase) {
  $cdnBase = "https://autoshift-glb.netlify.app"
}

$verLine = Select-String -Path $pubspec -Pattern '^version:\s*([\d.]+)\+' | Select-Object -First 1
$ver = if ($verLine) { $verLine.Matches[0].Groups[1].Value } else { "0.0.0" }

New-Item -ItemType Directory -Force -Path $release | Out-Null

Push-Location $root
try {
  & $flutter pub get
  & $flutter build apk --release `
    --dart-define=GLB_CDN_BASE=$cdnBase `
    --split-per-abi
  $apk = Get-ChildItem "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" -ErrorAction SilentlyContinue
  if (-not $apk) {
    throw "arm64 APK not found - build failed"
  }
  $dest = Join-Path $release "autoservice_v${ver}_note10_arm64.apk"
  Copy-Item $apk.FullName $dest -Force
  $mb = [math]::Round($apk.Length / 1MB, 1)
  Write-Host "APK: $dest ($mb MB)"
  Write-Host "GLB CDN: $cdnBase"
  Write-Host "Target: arm64 Note10 / flagship, classic mono UI"
} finally {
  Pop-Location
}
