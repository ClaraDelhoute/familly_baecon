import 'package:dio/dio.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';
import 'package:familly_baecon/features/journal/data/models/daily_activity_model.dart';
import 'package:familly_baecon/features/journal/data/models/notification_model.dart';
import 'package:familly_baecon/features/journal/data/models/sensor_event_model.dart';

class JournalRemoteDataSource {
  final Dio _dio;

  JournalRemoteDataSource(this._dio);

  Future<List<DailyActivityModel>> fetchActivities() async {
    print('[REST] GET /api/activities');
    final response = await _dio.get('/api/activities');
    final payload = response.data;
    if (payload is! List) {
      print('[REST] /api/activities invalid payload type=${payload.runtimeType}');
      return const <DailyActivityModel>[];
    }
    final items = payload
        .map((item) => DailyActivityModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    print('[REST] /api/activities rows=${items.length}');
    return items;
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    print('[REST] GET /api/notifications');
    final response = await _dio.get('/api/notifications');
    final payload = response.data;
    if (payload is! List) {
      print('[REST] /api/notifications invalid payload type=${payload.runtimeType}');
      return const <NotificationModel>[];
    }
    final items = payload
        .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    print('[REST] /api/notifications rows=${items.length}');
    return items;
  }

  Future<List<SensorEventModel>> fetchSensorEvents({int limit = 50}) async {
    print('[REST] GET /api/sensor-events?limit=$limit');
    final response = await _dio.get('/api/sensor-events', queryParameters: {'limit': limit});
    final payload = response.data;
    if (payload is! List) {
      print('[REST] /api/sensor-events invalid payload type=${payload.runtimeType}');
      return const <SensorEventModel>[];
    }
    final items = payload
        .map((item) => SensorEventModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    print('[REST] /api/sensor-events rows=${items.length}');
    return items;
  }

  Future<List<AnomalyHistoryModel>> fetchAnomalies({int limit = 100}) async {
    print('[REST] GET /api/anomalies');
    final response = await _dio.get('/api/anomalies', queryParameters: {'limit': limit});
    final payload = response.data;
    if (payload is! List) {
      print('[REST] /api/anomalies invalid payload type=${payload.runtimeType}');
      return const <AnomalyHistoryModel>[];
    }
    final items = payload
        .map((item) => AnomalyHistoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    print('[REST] /api/anomalies rows=${items.length}');
    return items;
  }
}
