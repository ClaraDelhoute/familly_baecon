import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TestMode { real, ok, warning, critical }

final testModeProvider = StateProvider<TestMode>((ref) => TestMode.real);

class _LastPopupAlertNotifier extends StateNotifier<String?> {
  static const _key = 'last_popup_alert_id';

  _LastPopupAlertNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  @override
  set state(String? value) {
    super.state = value;
    if (value != null) {
      SharedPreferences.getInstance()
          .then((p) => p.setString(_key, value));
    }
  }
}

final lastPopupAlertIdProvider =
    StateNotifierProvider<_LastPopupAlertNotifier, String?>(
  (_) => _LastPopupAlertNotifier(),
);
