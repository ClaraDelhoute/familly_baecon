class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'FAMILY_BEACON_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  static const String mqttHost = String.fromEnvironment(
    'FAMILY_BEACON_MQTT_HOST',
    defaultValue: '127.0.0.1',
  );

  static const int mqttPort = int.fromEnvironment(
    'FAMILY_BEACON_MQTT_PORT',
    defaultValue: 1883,
  );

  static const String mqttTopicAlerts = String.fromEnvironment(
    'FAMILY_BEACON_MQTT_TOPIC_ALERTS',
    defaultValue: 'alerts',
  );

  static const String mqttUsername = String.fromEnvironment(
    'FAMILY_BEACON_MQTT_USERNAME',
    defaultValue: '',
  );

  static const String mqttPassword = String.fromEnvironment(
    'FAMILY_BEACON_MQTT_PASSWORD',
    defaultValue: '',
  );

  static const String statsTimezone = String.fromEnvironment(
    'FAMILY_BEACON_STATS_TIMEZONE',
    defaultValue: 'Europe/Paris',
  );

  static const String fcmTokenRegisterPath = String.fromEnvironment(
    'FAMILY_BEACON_FCM_TOKEN_REGISTER_PATH',
    defaultValue: '/api/devices/register-token',
  );
}
