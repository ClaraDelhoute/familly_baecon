param(
    [string]$Device = "emulator-5554",
    [string]$ApiHost = "",
    [string]$MqttHost = "",
    [int]$ApiPort = 8080,
    [int]$MqttPort = 1883
)

if (-not $ApiHost) {
    $ApiHost = Read-Host "Adresse IP ou domaine du serveur distant (ex: 192.168.1.42)"
}
if (-not $MqttHost) {
    $MqttHost = $ApiHost
}

$ApiBaseUrl = "http://${ApiHost}:${ApiPort}"

Write-Host "Lancement de l'app avec :"
Write-Host "  API      : $ApiBaseUrl"
Write-Host "  MQTT     : ${MqttHost}:${MqttPort}"
Write-Host ""

flutter run -d $Device `
  --dart-define=FAMILY_BEACON_API_BASE_URL=$ApiBaseUrl `
  --dart-define=FAMILY_BEACON_MQTT_HOST=$MqttHost `
  --dart-define=FAMILY_BEACON_MQTT_PORT=$MqttPort `
  --dart-define=FAMILY_BEACON_MQTT_TOPIC_ALERTS=alerts
