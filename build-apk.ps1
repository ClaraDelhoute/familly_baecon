$ApiHost  = "172.161.26.105"
$ApkSrc   = "build\app\outputs\flutter-apk\app-release.apk"
$DriveUrl = "https://drive.google.com/drive/folders/1OG6PfJrU5uzn5HmSd8Emn56Ms5PWFJkg"

# 1. Build
Write-Host "[1/2] Build APK..." -ForegroundColor Cyan
flutter build apk --release `
    --dart-define=FAMILY_BEACON_API_BASE_URL=http://${ApiHost}:8080 `
    --dart-define=FAMILY_BEACON_MQTT_HOST=$ApiHost `
    --dart-define=FAMILY_BEACON_MQTT_PORT=1883 `
    --dart-define=FAMILY_BEACON_MQTT_TOPIC_ALERTS=alerts

if ($LASTEXITCODE -ne 0) { Write-Error "Build echoue"; exit 1 }

# 2. Copie dans Google Drive (sync local)
Write-Host "[2/2] Copie dans Google Drive..." -ForegroundColor Cyan
$drivePaths = @(
    "$env:USERPROFILE\Google Drive\FamilyBeacon",
    "$env:USERPROFILE\GoogleDrive\FamilyBeacon",
    "G:\Mon Drive\FamilyBeacon",
    "G:\My Drive\FamilyBeacon"
)
$dest = $drivePaths | Where-Object { Test-Path (Split-Path $_ -Parent) } | Select-Object -First 1

if ($dest) {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item $ApkSrc -Destination "$dest\FamilyBeacon-demo.apk" -Force
    Write-Host "APK copie dans : $dest" -ForegroundColor Green
} else {
    Write-Host "Dossier Google Drive non trouve localement." -ForegroundColor Yellow
    Write-Host "Copie manuelle : $((Resolve-Path $ApkSrc).Path)" -ForegroundColor Yellow
    Start-Process $DriveUrl
}

Write-Host "`nLien Drive : $DriveUrl" -ForegroundColor Green
