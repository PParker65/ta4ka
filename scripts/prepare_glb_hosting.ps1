# Copies GLB models into hosting/public for static deploy (Netlify / Cloudflare Pages).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Join-Path $root "assets\models"
$dst = Join-Path $root "hosting\public\assets\assets\models"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Path (Join-Path $src "*.glb") -Destination $dst -Force
$count = (Get-ChildItem $dst -Filter *.glb).Count
Write-Host "Copied $count GLB files to hosting/public/assets/assets/models/"
Write-Host "Deploy hosting/public to Netlify or Cloudflare Pages, then build APK with:"
Write-Host '  --dart-define=GLB_CDN_BASE=https://YOUR-SITE.netlify.app'
