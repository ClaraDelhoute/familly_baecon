param(
    [string]$Device = "emulator-5554"
)

flutter run -d $Device `
  --dart-define=FAMILY_BEACON_API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=FAMILY_BEACON_MQTT_HOST=10.0.2.2 `
  --dart-define=FAMILY_BEACON_MQTT_PORT=1883 `
  --dart-define=FAMILY_BEACON_MQTT_TOPIC_ALERTS=alerts
