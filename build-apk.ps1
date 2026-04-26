param(
    [string]$ApiHost = "172.161.26.105",
    [string]$MqttHost = "",
    [int]$ApiPort = 8080,
    [int]$MqttPort = 1883,
    [string]$ApkName = "FamilyBeacon-demo.apk"
)

if (-not $MqttHost) {
    $MqttHost = $ApiHost
}

$ApiBaseUrl = "http://${ApiHost}:${ApiPort}"
$ApkSrc     = "build\app\outputs\flutter-apk\app-release.apk"
$DriveUrl   = "https://drive.google.com/drive/folders/1OG6PfJrU5uzn5HmSd8Emn56Ms5PWFJkg"

Write-Host "Configuration APK :" -ForegroundColor Cyan
Write-Host "  API  : $ApiBaseUrl"
Write-Host "  MQTT : ${MqttHost}:${MqttPort}"
Write-Host ""

# 1. Build
Write-Host "[1/2] Build APK..." -ForegroundColor Cyan
flutter build apk --release `
    --dart-define=FAMILY_BEACON_API_BASE_URL=$ApiBaseUrl `
    --dart-define=FAMILY_BEACON_MQTT_HOST=$MqttHost `
    --dart-define=FAMILY_BEACON_MQTT_PORT=$MqttPort `
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
    Copy-Item $ApkSrc -Destination "$dest\$ApkName" -Force
    Write-Host "APK copie dans : $dest" -ForegroundColor Green
} else {
    Write-Host "Dossier Google Drive non trouve localement." -ForegroundColor Yellow
    Write-Host "Copie manuelle : $((Resolve-Path $ApkSrc).Path)" -ForegroundColor Yellow
    Start-Process $DriveUrl
}

Write-Host "`nLien Drive : $DriveUrl" -ForegroundColor Green
