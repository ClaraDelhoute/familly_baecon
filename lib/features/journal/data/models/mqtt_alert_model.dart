import 'package:familly_baecon/features/alertes/data/entities/alert_item.dart';

class MqttAlertModel {
  final DateTime timestamp;
  final String type;
  final String anomalyType;
  final String severity;
  final String room;
  final String message;

  const MqttAlertModel({
    required this.timestamp,
    required this.type,
    required this.anomalyType,
    required this.severity,
    required this.room,
    required this.message,
  });

  factory MqttAlertModel.fromJson(Map<String, dynamic> json) {
    final anomalyType = ((json['anomaly_type'] ?? json['type']) as String? ?? 'unknown').toLowerCase();
    final rawSeverity = (json['severity'] as String?)?.toLowerCase();
    return MqttAlertModel(
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: (json['type'] as String?) ?? anomalyType,
      anomalyType: anomalyType,
      severity: _normalizeSeverity(rawSeverity, anomalyType),
      room: (json['room'] as String?) ?? 'unknown',
      message: (json['message'] as String?) ?? '',
    );
  }

  AlertItem toAlertItem() {
    return AlertItem(
      id: 'mqtt_${timestamp.toIso8601String()}_${anomalyType}_$room',
      title: _titleFromRoom(room),
      description: message,
      severity: severity,
      anomalyType: anomalyType,
      timestamp: timestamp,
    );
  }

  String _titleFromRoom(String value) {
    if (value == 'petit_dejeuner') return 'Alerte petit-déjeuner';
    if (value == 'dejeuner') return 'Alerte déjeuner';
    if (value == 'souper') return 'Alerte souper';
    if (value == 'toilette') return 'Alerte toilettes';
    return 'Alerte activité';
  }

  static String _normalizeSeverity(String? incoming, String anomalyType) {
    if (incoming == 'high' || incoming == 'medium') {
      return incoming!;
    }
    return switch (anomalyType) {
      'missing' || 'duration_long' || 'freq_high' => 'high',
      'timing' || 'duration_short' || 'freq_low' => 'medium',
      _ => 'medium',
    };
  }
}
