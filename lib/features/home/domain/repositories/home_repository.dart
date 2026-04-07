import '../entities/activity.dart';

abstract class HomeRepository {
  /// Retourne le résumé du jour (entité domaine).
  /// Note: HomeSummaryModel est temporairement conservé; à remplacer par entité domaine après génération Freezed.
  Future<Map<String, dynamic>> getHomeSummary({required String userId, required DateTime date});

  /// Retourne la liste des activités pour une période (entités domaines).
  Future<List<Activity>> getActivities({required String deviceId, required DateTime from, required DateTime to});

  /// Retourne un stream d'activités en temps réel (entités domaines).
  Stream<Activity> subscribeActivityStream({required String userId});

  /// Cache une liste d'activités localement.
  Future<void> cacheActivities(List<Activity> activities);
}
