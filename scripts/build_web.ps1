$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$flutter = "C:\Users\Surface\flutter\bin\flutter.bat"
Push-Location $root
try {
  & $flutter build web --release --no-wasm-dry-run
  $src = Join-Path $root "assets\models"
  $dst = Join-Path $root "build\web\assets\assets\models"
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
  Copy-Item -Path (Join-Path $src "*.glb") -Destination $dst -Force
  Write-Host "Web build ready in build/web (GLB models copied for local serve)"
} finally {
  Pop-Location
}
