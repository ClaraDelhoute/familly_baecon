import 'package:flutter/services.dart';

class AnomalyNotificationService {
  static const MethodChannel _channel =
      MethodChannel('family_baecon/anomaly_notifications');

  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod<void>('initialize');
    } on PlatformException {
      // Notifications are a convenience layer; the app still receives alerts.
    }
  }

  static Future<void> showAnomalyAlert({
    required String id,
    required String title,
    required String message,
    required String severity,
  }) async {
    try {
      await _channel.invokeMethod<void>('showAnomalyAlert', {
        'id': id,
        'title': title,
        'message': message,
        'severity': severity,
      });
    } on PlatformException {
      // Keep the realtime alert flow working if notifications are unavailable.
    }
  }
}
