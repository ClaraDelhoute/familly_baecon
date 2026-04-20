import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/services/settings_service.dart';

final _settingsServiceProvider = Provider<SettingsService>((_) => SettingsService());

class WatchedPersonNameNotifier extends StateNotifier<String> {
  WatchedPersonNameNotifier(this._service) : super('') {
    _load();
  }

  final SettingsService _service;

  Future<void> _load() async {
    state = await _service.loadWatchedPersonName();
  }

  Future<void> setName(String name) async {
    state = name.trim();
    await _service.saveWatchedPersonName(state);
  }
}

final watchedPersonNameProvider =
    StateNotifierProvider<WatchedPersonNameNotifier, String>((ref) {
  return WatchedPersonNameNotifier(ref.watch(_settingsServiceProvider));
});
