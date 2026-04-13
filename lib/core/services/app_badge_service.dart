import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBadgeService {
  static const MethodChannel _channel = MethodChannel('family_baecon/app_icon');
  static const String _statusKey = 'app_badge_status';
  static String _currentStatus = 'ok';

  static String get currentStatus => _currentStatus;

  static String _normalize(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return 'critical';
      case 'warning':
        return 'warning';
      default:
        return 'ok';
    }
  }

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentStatus = _normalize(prefs.getString(_statusKey) ?? 'ok');
      await _applyToLauncher(_currentStatus);
    } on PlatformException {
      // Keep app functional if icon switching is unavailable.
    }
  }

  static Future<void> _applyToLauncher(String status) async {
    await _channel.invokeMethod<void>('setStatus', {'status': status});
  }

  static Future<void> updateBadge(String status) async {
    final normalized = _normalize(status);
    if (_currentStatus == normalized) return;
    _currentStatus = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statusKey, _currentStatus);
      await _applyToLauncher(_currentStatus);
    } on PlatformException {
      // Keep app functional if icon switching is unavailable.
    }
  }

  static Future<void> removeBadge() async {
    await updateBadge('ok');
  }
}
