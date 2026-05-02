import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TestMode { real, ok, warning, critical }

final testModeProvider = StateProvider<TestMode>((ref) => TestMode.real);

class _LastPopupAnomalyNotifier extends StateNotifier<int?> {
  static const _key = 'last_popup_anomaly_id';

  _LastPopupAnomalyNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_key);
    state = v;
  }

  @override
  set state(int? value) {
    super.state = value;
    if (value != null) {
      SharedPreferences.getInstance()
          .then((p) => p.setInt(_key, value));
    }
  }
}

final lastPopupAnomalyIdProvider =
    StateNotifierProvider<_LastPopupAnomalyNotifier, int?>(
  (_) => _LastPopupAnomalyNotifier(),
);
