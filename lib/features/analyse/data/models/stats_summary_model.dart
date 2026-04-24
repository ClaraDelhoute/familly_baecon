class StatsSummaryModel {
  final String period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime asOf;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final int mealsCount;
  final int sleepMinutes;
  final int avgSleepMinutes;
  final int? avgBedtimeMinute;
  final int? avgWakeMinute;
  final int? avgOutingMinutes;
  final int anomaliesCount;
  final List<DailyStatsModel> daily;

  const StatsSummaryModel({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.asOf,
    required this.generatedAt,
    required this.expiresAt,
    required this.mealsCount,
    required this.sleepMinutes,
    required this.avgSleepMinutes,
    required this.avgBedtimeMinute,
    required this.avgWakeMinute,
    required this.avgOutingMinutes,
    required this.anomaliesCount,
    required this.daily,
  });

  factory StatsSummaryModel.fromJson(Map<String, dynamic> json) {
    return StatsSummaryModel(
      period: (json['period'] as String?) ?? 'week',
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      asOf: DateTime.parse(json['as_of'] as String),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      mealsCount: _readInt(json, 'meals_count'),
      sleepMinutes: _readInt(json, 'sleep_minutes'),
      avgSleepMinutes: _readInt(json, 'avg_sleep_minutes'),
      avgBedtimeMinute: _readOptionalInt(json, 'avg_bedtime_minute'),
      avgWakeMinute: _readOptionalInt(json, 'avg_wake_minute'),
      avgOutingMinutes: _readOptionalInt(json, 'avg_outing_minutes'),
      anomaliesCount: _readInt(json, 'anomalies_count'),
      daily: ((json['daily'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => DailyStatsModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class DailyStatsModel {
  final DateTime date;
  final int mealsCount;
  final int sleepMinutes;
  final int? bedtimeMinute;
  final int? wakeMinute;
  final int? outingMinutes;
  final int anomaliesCount;
  final int totalActivities;

  const DailyStatsModel({
    required this.date,
    required this.mealsCount,
    required this.sleepMinutes,
    required this.bedtimeMinute,
    required this.wakeMinute,
    required this.outingMinutes,
    required this.anomaliesCount,
    required this.totalActivities,
  });

  factory DailyStatsModel.fromJson(Map<String, dynamic> json) {
    return DailyStatsModel(
      date: DateTime.parse(json['date'] as String),
      mealsCount: _readInt(json, 'meals_count'),
      sleepMinutes: _readInt(json, 'sleep_minutes'),
      bedtimeMinute: _readOptionalInt(json, 'bedtime_minute'),
      wakeMinute: _readOptionalInt(json, 'wake_minute'),
      outingMinutes: _readOptionalInt(json, 'outing_minutes'),
      anomaliesCount: _readInt(json, 'anomalies_count'),
      totalActivities: _readInt(json, 'total_activities'),
    );
  }
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

int? _readOptionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value');
}
