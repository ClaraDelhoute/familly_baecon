import 'package:familly_baecon/features/home/data/models/activity_model.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';

/// Utilitaire pour convertir ActivityModel (data) en Activity (domain).
class ActivityMapper {
  /// Convertit un ActivityModel (data layer, Freezed) en entité Activity (domain).
  static Activity toDomain(ActivityModel model) {
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

  /// Convertit une liste d'ActivityModel en entités Activity.
  static List<Activity> toDomainList(List<ActivityModel> models) {
    return models.map(toDomain).toList();
  }
}

