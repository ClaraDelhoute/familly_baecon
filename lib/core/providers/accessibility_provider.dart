import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/models/accessibility_settings.dart';
import 'package:familly_baecon/core/services/accessibility_service.dart';

final accessibilityServiceProvider = Provider<AccessibilityService>((ref) {
  return AccessibilityService();
});

class AccessibilitySettingsNotifier
    extends StateNotifier<AccessibilitySettings> {
  AccessibilitySettingsNotifier(this._service)
    : super(
        const AccessibilitySettings(
          textScaleFactor: 1.0,
          iconScaleFactor: 1.0,
          highContrast: false,
        ),
      ) {
    _load();
  }

  final AccessibilityService _service;

  Future<void> _load() async {
    final loaded = await _service.load();
    state = loaded;
  }

  Future<void> setTextScaleFactor(double value) async {
    final clamped = value.clamp(0.8, 1.6);
    state = state.copyWith(textScaleFactor: clamped);
    await _service.save(state);
  }

  Future<void> setIconScaleFactor(double value) async {
    final clamped = value.clamp(0.8, 1.8);
    state = state.copyWith(iconScaleFactor: clamped);
    await _service.save(state);
  }

  Future<void> setHighContrast(bool value) async {
    state = state.copyWith(highContrast: value);
    await _service.save(state);
  }
}

final accessibilitySettingsProvider =
    StateNotifierProvider<AccessibilitySettingsNotifier, AccessibilitySettings>(
      (ref) {
        final service = ref.watch(accessibilityServiceProvider);
        return AccessibilitySettingsNotifier(service);
      },
    );
