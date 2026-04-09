class SensorEventModel {
  final int id;
  final DateTime timestamp;
  final String room;
  final String sensorType;
  final String value;

  const SensorEventModel({
    required this.id,
    required this.timestamp,
    required this.room,
    required this.sensorType,
    required this.value,
  });

  factory SensorEventModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return SensorEventModel(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      room: (json['room'] as String?) ?? 'unknown',
      sensorType: (json['sensor_type'] as String?) ?? 'unknown',
      value: (json['value'] as String?) ?? '',
    );
  }
}
