class RoutineActivityModel {
  final String room;
  final String sensorType;
  final double? startMin;
  final double? durationMin;
  final double? bedtimeMin;
  final double frequency;
  final int? sampleCount;

  const RoutineActivityModel({
    required this.room,
    required this.sensorType,
    this.startMin,
    this.durationMin,
    this.bedtimeMin,
    required this.frequency,
    this.sampleCount,
  });

  factory RoutineActivityModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['value'] as String? ?? '');
    final parts = Map.fromEntries(
      raw.split(',').map((e) {
        final kv = e.split(':');
        return MapEntry(kv[0].trim(), kv.length > 1 ? kv[1].trim() : '');
      }),
    );
    return RoutineActivityModel(
      room: (json['room'] as String? ?? '').trim(),
      sensorType: (json['sensor_type'] as String? ?? '').trim(),
      startMin: double.tryParse(parts['s'] ?? ''),
      durationMin: double.tryParse(parts['d'] ?? ''),
      bedtimeMin: double.tryParse(parts['bedtime'] ?? ''),
      frequency: double.tryParse(parts['freq'] ?? '') ?? 0,
      sampleCount: int.tryParse(parts['count'] ?? ''),
    );
  }

  bool get isActivityProfile => sensorType == 'activity_profile';
  bool get isToiletProfile => sensorType == 'toilet_profile';

  /// Heure de début arrondie (ex: 560 min → 9h20)
  String get startLabel {
    if (startMin == null) return '';
    final h = (startMin! ~/ 60) % 24;
    final m = (startMin! % 60).round();
    return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}';
  }

  /// Heure de fin habituelle = startMin + durationMin (réveil pour sleep = 0+363=6h03)
  String get endLabel {
    if (startMin == null) return '';
    final endMin = (startMin! + (durationMin ?? 0)) % (24 * 60);
    final h = (endMin ~/ 60) % 24;
    final m = (endMin % 60).round();
    return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}';
  }

  /// Heure de coucher habituelle (sleep uniquement)
  String get bedtimeLabel {
    if (bedtimeMin == null) return '';
    final h = (bedtimeMin! ~/ 60) % 24;
    final m = (bedtimeMin! % 60).round();
    return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}';
  }

  /// Durée formatée (ex: 21 min → "21 min", 90 → "1h30")
  String get durationLabel {
    if (durationMin == null || durationMin! <= 0) return '';
    final total = durationMin!.round().abs();
    if (total < 60) return '$total min';
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }
}
