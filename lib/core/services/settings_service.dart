import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/absence_period.dart';

final settingsServiceProvider = Provider<SettingsService>((_) => SettingsService());

class SettingsService {
  static const _profileImageKey = 'profile_image_path';
  static const _absenceKey = 'user_absence_period';
  static const _watchedPersonNameKey = 'watched_person_name';

  Future<void> saveWatchedPersonName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_watchedPersonNameKey, name);
  }

  Future<String> loadWatchedPersonName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_watchedPersonNameKey) ?? 'René';
  }

  Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, path);
  }

  Future<String?> loadProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }

  Future<void> saveAbsencePeriod(AbsencePeriod period) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_absenceKey, jsonEncode(period.toJson()));
  }

  Future<AbsencePeriod> loadAbsencePeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_absenceKey);
    if (raw == null) return AbsencePeriod();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AbsencePeriod.fromJson(map);
    } catch (_) {
      return AbsencePeriod();
    }
  }

  Future<bool> isInAbsence([DateTime? at]) async {
    final period = await loadAbsencePeriod();
    return period.isActive(at);
  }
}

