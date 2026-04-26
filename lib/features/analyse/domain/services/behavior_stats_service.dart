import 'package:familly_baecon/core/domain/activity_type.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';

class DailyBehaviorStats {
  final DateTime day;
  final int sleepMinutes;
  final int mealsCount;
  final int otherActivitiesCount;
  final int totalActivities;
  // Minute de la première activité dans la journée (0–1439), null si aucune
  final int? firstActivityMinute;

  const DailyBehaviorStats({
    required this.day,
    required this.sleepMinutes,
    required this.mealsCount,
    required this.otherActivitiesCount,
    required this.totalActivities,
    this.firstActivityMinute,
  });
}

class DeclineMetric {
  final String label;
  final double recentAverage;
  final double previousAverage;
  final String unit;
  final double declineThreshold;

  const DeclineMetric({
    required this.label,
    required this.recentAverage,
    required this.previousAverage,
    required this.unit,
    required this.declineThreshold,
  });

  double get ratio {
    if (previousAverage <= 0) return 1;
    return recentAverage / previousAverage;
  }

  bool get isDecline => ratio < declineThreshold;

  double get deltaPercent {
    if (previousAverage <= 0) return 0;
    return ((recentAverage - previousAverage) / previousAverage) * 100;
  }
}

class BehaviorStatsService {
  static List<DailyBehaviorStats> buildDailyStats(
    List<Activity> activities, {
    int maxDays = 28,
  }) {
    final grouped = <DateTime, List<Activity>>{};
    for (final activity in activities) {
      final day = DateTime(activity.startAt.year, activity.startAt.month, activity.startAt.day);
      grouped.putIfAbsent(day, () => <Activity>[]).add(activity);
    }

    final days = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    final selectedDays = days.length > maxDays ? days.sublist(days.length - maxDays) : days;

    return selectedDays
        .map((day) => _fromDayActivities(day, grouped[day] ?? const <Activity>[]))
        .toList();
  }

  static DailyBehaviorStats summarizeLatestDay(List<Activity> activities) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayActivities = activities.where((a) {
      final day = DateTime(a.startAt.year, a.startAt.month, a.startAt.day);
      return day == today;
    }).toList();
    // Si aucune activité aujourd'hui, on renvoie des zéros plutôt que le dernier jour connu
    return _fromDayActivities(today, todayActivities);
  }

  static List<DeclineMetric> buildDeclineMetrics(List<DailyBehaviorStats> stats) {
    if (stats.isEmpty) {
      return const [];
    }

    final split = stats.length >= 14 ? 7 : (stats.length / 2).floor().clamp(1, stats.length);
    final recent = stats.sublist(stats.length - split);
    final previous = stats.length > split ? stats.sublist(0, stats.length - split) : <DailyBehaviorStats>[];

    double avgSleep(List<DailyBehaviorStats> days) =>
        days.isEmpty ? 0 : days.map((d) => d.sleepMinutes).reduce((a, b) => a + b) / days.length / 60;
    double avgMeals(List<DailyBehaviorStats> days) =>
        days.isEmpty ? 0 : days.map((d) => d.mealsCount).reduce((a, b) => a + b) / days.length;
    double avgOther(List<DailyBehaviorStats> days) =>
        days.isEmpty ? 0 : days.map((d) => d.otherActivitiesCount).reduce((a, b) => a + b) / days.length;

    return [
      DeclineMetric(
        label: 'Sommeil',
        recentAverage: avgSleep(recent),
        previousAverage: avgSleep(previous),
        unit: 'h',
        declineThreshold: 0.9,
      ),
      DeclineMetric(
        label: 'Repas',
        recentAverage: avgMeals(recent),
        previousAverage: avgMeals(previous),
        unit: 'repas',
        declineThreshold: 0.85,
      ),
      DeclineMetric(
        label: 'Autres activités',
        recentAverage: avgOther(recent),
        previousAverage: avgOther(previous),
        unit: 'act.',
        declineThreshold: 0.85,
      ),
    ];
  }

  static DailyBehaviorStats _fromDayActivities(DateTime day, List<Activity> activities) {
    var sleepMinutes = 0;
    var mealsCount = 0;
    var otherCount = 0;

    for (final activity in activities) {
      if (_isSleep(activity)) {
        sleepMinutes += activity.durationMin ??
            (activity.endAt != null ? activity.endAt!.difference(activity.startAt).inMinutes : 0);
      } else if (_isMeal(activity)) {
        mealsCount += 1;
      } else {
        otherCount += 1;
      }
    }

    final firstMinute = activities.isEmpty
        ? null
        : activities
            .map((a) => a.startAt.hour * 60 + a.startAt.minute)
            .reduce((a, b) => a < b ? a : b);

    return DailyBehaviorStats(
      day: day,
      sleepMinutes: sleepMinutes,
      mealsCount: mealsCount,
      otherActivitiesCount: otherCount,
      totalActivities: activities.length,
      firstActivityMinute: firstMinute,
    );
  }

  static bool _isSleep(Activity activity) =>
      ActivityType.fromKey(activity.type).isSleep;

  static bool _isMeal(Activity activity) =>
      ActivityType.fromKey(activity.type).isMeal;
}
