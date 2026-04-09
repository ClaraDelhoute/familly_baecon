class AlertItem {
  final String id;
  final String title;
  final String description;
  final String severity;
  final String anomalyType;
  final DateTime timestamp;

  const AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.anomalyType,
    required this.timestamp,
  });

  bool get isHighSeverity => severity.toLowerCase() == 'high';
}
