import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.light) {
    _load();
  }

  static const String _key = 'app_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    final mode = stored == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
    AppTheme.applyMode(mode);
    state = mode;
  }

  Future<void> setMode(AppThemeMode mode) async {
    AppTheme.applyMode(mode);
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == AppThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggle() async {
    await setMode(
      state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark,
    );
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
      (ref) => ThemeModeNotifier(),
    );
