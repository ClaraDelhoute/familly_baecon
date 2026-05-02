import 'package:familly_baecon/core/domain/activity_type.dart';
import 'package:familly_baecon/core/domain/anomaly_type.dart';
import 'package:familly_baecon/features/alertes/data/entities/alert_item.dart';

class MqttAlertModel {
  final DateTime timestamp;
  final String type;
  final String anomalyType;
  final String severity;
  final String room;
  final String message;
  final String? sensorType;
  final int? activityId;
  final int? routineId;
  final int? anomalyHistoryId;

  const MqttAlertModel({
    required this.timestamp,
    required this.type,
    required this.anomalyType,
    required this.severity,
    required this.room,
    required this.message,
    this.sensorType,
    this.activityId,
    this.routineId,
    this.anomalyHistoryId,
  });

  factory MqttAlertModel.fromJson(Map<String, dynamic> json) {
    final anomalyType = ((json['anomaly_type'] ?? json['type']) as String? ?? 'unknown').toLowerCase();
    final rawSeverity = (json['severity'] as String?)?.toLowerCase();
    final rawActivityId = json['activity_id'];
    final rawRoutineId = json['routine_id'];
    final rawHistoryId = json['anomaly_history_id'];
    return MqttAlertModel(
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: (json['type'] as String?) ?? anomalyType,
      anomalyType: anomalyType,
      severity: _normalizeSeverity(rawSeverity, anomalyType),
      room: (json['room'] as String?) ?? 'unknown',
      message: (json['message'] as String?) ?? '',
      sensorType: (json['sensor_type'] as String?)?.trim(),
      activityId: rawActivityId is int ? rawActivityId : int.tryParse('$rawActivityId'),
      routineId: rawRoutineId is int ? rawRoutineId : int.tryParse('$rawRoutineId'),
      anomalyHistoryId: rawHistoryId is int ? rawHistoryId : int.tryParse('$rawHistoryId'),
    );
  }

  AlertItem toAlertItem() {
    final effectiveSensorType = sensorType ?? room;
    return AlertItem(
      id: anomalyHistoryId != null
          ? 'mqtt_alert_$anomalyHistoryId'
          : 'mqtt_${timestamp.toIso8601String()}_${anomalyType}_$room',
      title: _titleFromSensor(effectiveSensorType),
      description: message,
      severity: severity,
      anomalyType: anomalyType,
      timestamp: timestamp,
      simulatedAt: timestamp,
      sensorType: effectiveSensorType,
      activityId: activityId,
      routineId: routineId,
    );
  }

  String _titleFromSensor(String value) {
    final label = ActivityType.fromKey(value).label;
    return label == 'Activité' ? 'Alerte activité' : 'Alerte ${label.toLowerCase()}';
  }

  static String _normalizeSeverity(String? incoming, String anomalyType) {
    if (incoming == 'high' || incoming == 'medium') return incoming!;
    return AnomalyType.fromKey(anomalyType).severity;
  }
}
