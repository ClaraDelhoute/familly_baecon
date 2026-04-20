class AnomalyHistoryModel {
  final int id;
  final DateTime detectedDate;
  final String activityKey;
  final String anomalyType;
  final String severity;
  final DateTime simulatedAt;
  final DateTime firstDetectedAt;
  final DateTime lastSeenAt;
  final int seenCount;
  final String message;

  const AnomalyHistoryModel({
    required this.id,
    required this.detectedDate,
    required this.activityKey,
    required this.anomalyType,
    required this.severity,
    required this.simulatedAt,
    required this.firstDetectedAt,
    required this.lastSeenAt,
    required this.seenCount,
    required this.message,
  });

  factory AnomalyHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawSeenCount = json['seen_count'];
    final detectedDate = DateTime.parse(json['detected_date'] as String);
    final firstDetectedAt = DateTime.parse(json['first_detected_at'] as String);
    final lastSeenAt = DateTime.parse(json['last_seen_at'] as String);
    return AnomalyHistoryModel(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      detectedDate: detectedDate,
      activityKey: (json['activity_key'] as String?) ?? 'unknown',
      anomalyType: ((json['anomaly_type'] as String?) ?? 'unknown').toLowerCase(),
      severity: _normalizeSeverity(
        (json['severity'] as String?)?.toLowerCase(),
        ((json['anomaly_type'] as String?) ?? 'unknown').toLowerCase(),
      ),
      simulatedAt:
          DateTime.tryParse((json['simulated_at'] as String?) ?? '') ??
          detectedDate,
      firstDetectedAt: firstDetectedAt,
      lastSeenAt: lastSeenAt,
      seenCount: rawSeenCount is int ? rawSeenCount : int.tryParse('$rawSeenCount') ?? 0,
      message: (json['message'] as String?) ?? '',
    );
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
