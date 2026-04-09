import 'package:familly_baecon/features/home/domain/entities/activity.dart';

class DailyActivityModel {
  final int id;
  final DateTime date;
  final String activity;
  final String? startTime;
  final String? endTime;
  final String state;

  const DailyActivityModel({
    required this.id,
    required this.date,
    required this.activity,
    required this.startTime,
    required this.endTime,
    required this.state,
  });

  factory DailyActivityModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return DailyActivityModel(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      date: DateTime.parse(json['date'] as String),
      activity: (json['activity'] as String?) ?? 'unknown',
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      state: (json['state'] as String?) ?? 'normal',
    );
  }

  Activity toDomain({required DateTime fallbackDate}) {
    final startAt = _combineDateAndTime(date, startTime) ?? fallbackDate;
    final endAt = _combineDateAndTime(date, endTime);

    return Activity(
      id: 'daily_$id',
      deviceId: 'daily_activity',
      type: activity,
      room: _activityToRoom(activity),
      startAt: startAt,
      endAt: endAt,
      durationMin: _durationMin(startAt, endAt),
      status: state,
      note: state,
    );
  }

  static DateTime? _combineDateAndTime(DateTime date, String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  static int? _durationMin(DateTime start, DateTime? end) {
    if (end == null || end.isBefore(start)) return null;
    return end.difference(start).inMinutes;
  }

  static String _activityToRoom(String activity) {
    switch (activity) {
      case 'petit_dejeuner':
      case 'dejeuner':
      case 'souper':
        return 'CUISINE';
      case 'toilette':
        return 'SALLE DE BAIN';
      default:
        return 'SALON';
    }
  }
}
