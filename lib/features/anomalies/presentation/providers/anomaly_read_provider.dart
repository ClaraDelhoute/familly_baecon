import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnomalyReadNotifier extends StateNotifier<Set<int>> {
  static const _key = 'read_anomaly_ids';

  AnomalyReadNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0).toSet();
  }

  Future<void> markRead(int id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((e) => '$e').toList());
  }

  bool isRead(int id) => state.contains(id);

  Future<void> markAllRead(List<int> ids) async {
    final updated = {...state, ...ids};
    if (updated.length == state.length) return;
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((e) => '$e').toList());
  }
}

final anomalyReadProvider =
    StateNotifierProvider<AnomalyReadNotifier, Set<int>>(
  (_) => AnomalyReadNotifier(),
);
