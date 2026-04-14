import 'package:shared_preferences/shared_preferences.dart';
import 'package:familly_baecon/core/models/accessibility_settings.dart';

class AccessibilityService {
  static const String _textScaleKey = 'accessibility_text_scale_factor';
  static const String _iconScaleKey = 'accessibility_icon_scale_factor';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _textScaleMigrationDoneKey =
      'accessibility_text_scale_migrated_v2';
  static const String _iconScaleMigrationDoneKey =
      'accessibility_icon_scale_migrated_v2';

  Future<AccessibilitySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final hasStoredTextScale = prefs.containsKey(_textScaleKey);
    var textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    final migrationDone = prefs.getBool(_textScaleMigrationDoneKey) ?? false;
    if (!migrationDone && hasStoredTextScale) {
      textScale = (textScale / 1.2).clamp(0.8, 1.6);
      await prefs.setDouble(_textScaleKey, textScale);
    }
    if (!migrationDone) {
      await prefs.setBool(_textScaleMigrationDoneKey, true);
    }
    final hasStoredIconScale = prefs.containsKey(_iconScaleKey);
    var iconScale = prefs.getDouble(_iconScaleKey) ?? 1.0;
    final iconMigrationDone =
        prefs.getBool(_iconScaleMigrationDoneKey) ?? false;
    if (!iconMigrationDone && hasStoredIconScale) {
      iconScale = (iconScale / 1.2).clamp(0.8, 1.8);
      await prefs.setDouble(_iconScaleKey, iconScale);
    }
    if (!iconMigrationDone) {
      await prefs.setBool(_iconScaleMigrationDoneKey, true);
    }
    final highContrast = prefs.getBool(_highContrastKey) ?? false;

    return AccessibilitySettings(
      textScaleFactor: textScale.clamp(0.8, 1.6),
      iconScaleFactor: iconScale.clamp(0.8, 1.8),
      highContrast: highContrast,
    );
  }

  Future<void> save(AccessibilitySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, settings.textScaleFactor);
    await prefs.setDouble(_iconScaleKey, settings.iconScaleFactor);
    await prefs.setBool(_highContrastKey, settings.highContrast);
  }
}
