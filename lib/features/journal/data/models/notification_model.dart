class NotificationModel {
  final int id;
  final DateTime timestamp;
  final String message;

  const NotificationModel({
    required this.id,
    required this.timestamp,
    required this.message,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return NotificationModel(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: (json['message'] as String?) ?? '',
    );
  }
}
