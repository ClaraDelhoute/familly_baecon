import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/services/settings_service.dart';

final profileImagePathProvider = StateNotifierProvider<ProfileImageNotifier, String?>((ref) {
  return ProfileImageNotifier(ref.watch(settingsServiceProvider));
});

class ProfileImageNotifier extends StateNotifier<String?> {
  final SettingsService _settings;

  ProfileImageNotifier(this._settings) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final path = await _settings.loadProfileImagePath();
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      state = path;
    }
  }

  Future<void> updateImage(String? path) async {
    if (path == null || path.isEmpty) {
      await _settings.saveProfileImagePath('');
      state = null;
    } else {
      await _settings.saveProfileImagePath(path);
      state = path;
    }
  }

  Future<void> refresh() async {
    await _load();
  }
}
