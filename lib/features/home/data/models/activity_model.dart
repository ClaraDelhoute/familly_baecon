/// Modèle de données pour une activité (data layer).
/// Version classique immutable (pas de Freezed).
class ActivityModel {
  final String id;
  final String deviceId;
  final String? name;
  final String type;
  final String? room;
  final DateTime startAt;
  final DateTime? endAt;
  final int? durationMin;
  final String? status;
  final double? confidence;
  final String? note;
  final Map<String, dynamic>? metadata;

  const ActivityModel({
    required this.id,
    required this.deviceId,
    this.name,
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
  ActivityModel copyWith({
    String? id,
    String? deviceId,
    String? name,
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
    return ActivityModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
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

  /// Convertit depuis JSON (simule json_serializable).
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      deviceId: json['device_id'] as String? ?? json['deviceId'] as String,
      name: json['name'] as String?,
      type: json['type'] as String,
      room: json['room'] as String?,
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'] as String)
          : DateTime.parse(json['startAt'] as String),
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : (json['endAt'] != null ? DateTime.parse(json['endAt'] as String) : null),
      durationMin: json['duration_min'] as int? ?? json['durationMin'] as int?,
      status: json['status'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      note: json['note'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convertit en JSON (simule json_serializable).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'name': name,
      'type': type,
      'room': room,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'duration_min': durationMin,
      'status': status,
      'confidence': confidence,
      'note': note,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'ActivityModel(id: $id, deviceId: $deviceId, type: $type, room: $room, startAt: $startAt, endAt: $endAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityModel &&
        other.id == id &&
        other.deviceId == deviceId &&
        other.type == type &&
        other.room == room &&
        other.startAt == startAt &&
        other.endAt == endAt;
  }

  @override
  int get hashCode => id.hashCode ^ deviceId.hashCode ^ type.hashCode;
}

