import 'activity_model.dart';

/// Modèle de résumé d'une journée (data layer).
/// Version classique immutable (sera remplacée par Freezed après build_runner).
class HomeSummaryModel {
  final DateTime date;
  final int activeDurationSeconds;
  final int? steps;
  final int alertsCount;
  final List<ActivityModel> activities;

  const HomeSummaryModel({
    required this.date,
    required this.activeDurationSeconds,
    this.steps,
    required this.alertsCount,
    required this.activities,
  });

  /// Convertit depuis JSON (simule json_serializable).
  factory HomeSummaryModel.fromJson(Map<String, dynamic> json) {
    final activitiesList = (json['activities'] as List<dynamic>? ?? [])
        .map((e) => ActivityModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return HomeSummaryModel(
      date: DateTime.parse(json['date'] as String),
      activeDurationSeconds: json['active_duration_seconds'] as int? ?? json['activeDurationSeconds'] as int,
      steps: json['steps'] as int?,
      alertsCount: json['alerts_count'] as int? ?? json['alertsCount'] as int,
      activities: activitiesList,
    );
  }

  /// Convertit vers JSON (simule json_serializable).
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'active_duration_seconds': activeDurationSeconds,
    'steps': steps,
    'alerts_count': alertsCount,
    'activities': activities.map((a) => a.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeSummaryModel &&
          runtimeType == other.runtimeType &&
          date == other.date;

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() =>
      'HomeSummaryModel(date: $date, activeDurationSeconds: $activeDurationSeconds, alertsCount: $alertsCount)';
}

