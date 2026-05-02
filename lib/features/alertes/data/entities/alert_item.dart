class AlertItem {
  final String id;
  final String title;
  final String description;
  final String severity;
  final String anomalyType;
  final DateTime timestamp;
  final DateTime? simulatedAt;
  final String? sensorType;
  final int? activityId;
  final int? routineId;

  const AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.anomalyType,
    required this.timestamp,
    this.simulatedAt,
    this.sensorType,
    this.activityId,
    this.routineId,
  });

  bool get isHighSeverity => severity.toLowerCase() == 'high';
}
