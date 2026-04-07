import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';

/// Couche locale de cache (remplace Drift pour éviter build_runner).
/// Utilise SharedPreferences pour persistance simple.
class HomeLocalDataSource {
  static const String _activitiesKey = 'cached_activities';
  late SharedPreferences _prefs;

  /// Initialise la datasource (à appeler au démarrage).
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Persiste une liste d'activités localement.
  Future<void> upsertActivitiesFromModels(List<ActivityModel> activities) async {
    try {
      final jsonList = activities.map((a) => a.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await _prefs.setString(_activitiesKey, encoded);
    } catch (e) {
      // Silencieusement échouer en cas d'erreur persistance
      print('HomeLocalDataSource: erreur persistance activités: $e');
    }
  }

  /// Récupère les activités cachées.
  Future<List<ActivityModel>> getAllActivities() async {
    try {
      final encoded = _prefs.getString(_activitiesKey);
      if (encoded == null) return [];

      final jsonList = jsonDecode(encoded) as List<dynamic>;
      return jsonList
          .map((j) => ActivityModel.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (e) {
      print('HomeLocalDataSource: erreur lecture cache: $e');
      return [];
    }
  }

  /// Vide le cache local.
  Future<void> clear() async {
    await _prefs.remove(_activitiesKey);
  }
}

