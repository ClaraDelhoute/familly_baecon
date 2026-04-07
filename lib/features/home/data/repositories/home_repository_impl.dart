import 'package:familly_baecon/features/home/domain/repositories/home_repository.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/home/data/datasources/home_remote_datasource.dart';
import 'package:familly_baecon/features/home/data/datasources/home_local_datasource.dart';
import 'package:familly_baecon/features/home/data/models/activity_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remote;
  final HomeLocalDataSource local;

  HomeRepositoryImpl({required this.remote, required this.local});

  /// Convertit un ActivityModel (data) en Activity (domain).
  Activity _modelToEntity(ActivityModel model) {
    return Activity(
      id: model.id,
      deviceId: model.deviceId,
      type: model.type,
      room: model.room,
      startAt: model.startAt,
      endAt: model.endAt,
      durationMin: model.durationMin,
      status: model.status,
      confidence: model.confidence,
      note: model.name,
      metadata: model.metadata,
    );
  }

  @override
  Future<Map<String, dynamic>> getHomeSummary({required String userId, required DateTime date}) async {
    final summary = await remote.fetchHomeSummary(userId: userId, date: date);
    // cache activities inside summary
    await local.upsertActivitiesFromModels(summary.activities);
    // Retourner un Map pour transitoirement
    return {
      'date': summary.date,
      'activeDurationSeconds': summary.activeDurationSeconds,
      'steps': summary.steps,
      'alertsCount': summary.alertsCount,
      'activities': summary.activities.map((a) => _modelToEntity(a)).toList(),
    };
  }

  @override
  Future<List<Activity>> getActivities({required String deviceId, required DateTime from, required DateTime to}) async {
    try {
      final remoteActivities = await remote.fetchActivities(deviceId: deviceId, from: from, to: to);
      await local.upsertActivitiesFromModels(remoteActivities);
      // Convertir models data en entités domaines
      return remoteActivities.map((m) => _modelToEntity(m)).toList();
    } catch (e) {
      // fallback to local cache
      final allCached = await local.getAllActivities();
      final filtered = allCached.where((a) {
        return a.deviceId == deviceId &&
            a.startAt.isAfter(from) &&
            a.startAt.isBefore(to.add(Duration(days: 1)));
      }).toList();
      return filtered.map((m) => _modelToEntity(m)).toList();
    }
  }

  @override
  Stream<Activity> subscribeActivityStream({required String userId}) {
    // TODO: connect to MQTT service and map payloads to Activity
    throw UnimplementedError();
  }

  @override
  Future<void> cacheActivities(List<Activity> activities) async {
    // Créer des ActivityModel temporaires from Activity pour persister
    final models = activities.map((a) => ActivityModel(
      id: a.id,
      deviceId: a.deviceId,
      type: a.type,
      room: a.room,
      startAt: a.startAt,
      endAt: a.endAt,
      durationMin: a.durationMin,
      status: a.status,
      confidence: a.confidence,
      name: a.note,
      metadata: a.metadata,
    )).toList();
    await local.upsertActivitiesFromModels(models);
  }
}
