/// Entité de domaine représentant une activité.
/// Classe immutable classique (non-Freezed) pour éviter dépendance aux fichiers générés.
class Activity {
  final String id;
  final String deviceId;
  final String type;
  final String? room;
  final DateTime startAt;
  final DateTime? endAt;
  final int? durationMin;
  final String? status;
  final double? confidence;
  final String? note;
  final Map<String, dynamic>? metadata;

  const Activity({
    required this.id,
    required this.deviceId,
    required this.type,
    this.room,
    required this.startAt,
    this.endAt,
    this.durationMin,
    this.status,
    this.confidence,
    this.note,
    this.metadata,
  });

  /// Crée une copie avec modification de champs optionnels.
  Activity copyWith({
    String? id,
    String? deviceId,
    String? type,
    String? room,
    DateTime? startAt,
    DateTime? endAt,
    int? durationMin,
    String? status,
    double? confidence,
    String? note,
    Map<String, dynamic>? metadata,
  }) {
    return Activity(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      room: room ?? this.room,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      durationMin: durationMin ?? this.durationMin,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      note: note ?? this.note,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startAt == other.startAt;

  @override
  int get hashCode => id.hashCode ^ startAt.hashCode;

  @override
  String toString() =>
      'Activity(id: $id, type: $type, room: $room, startAt: $startAt, endAt: $endAt)';
}

