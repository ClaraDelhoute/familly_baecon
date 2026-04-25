import 'dart:async';

import 'package:dio/dio.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';
import 'package:familly_baecon/features/journal/data/models/daily_activity_model.dart';
import 'package:familly_baecon/features/journal/data/models/notification_model.dart';
import 'package:familly_baecon/features/journal/data/models/routine_activity_model.dart';
import 'package:familly_baecon/features/journal/data/models/sensor_event_model.dart';

class JournalRemoteDataSource {
  final Dio _dio;

  JournalRemoteDataSource(this._dio);

  Future<List<DailyActivityModel>> fetchActivities({int limit = 200, int? sinceHours}) async {
    final params = <String, dynamic>{'limit': limit};
    if (sinceHours != null) {
      params['from'] = DateTime.now().subtract(Duration(hours: sinceHours)).toUtc().toIso8601String();
    }
    final response = await _dio.get('/api/activities', queryParameters: params);
    final payload = response.data;
    if (payload is! List) return const <DailyActivityModel>[];
    return payload
        .map((item) => DailyActivityModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<NotificationModel>> fetchNotifications({int limit = 100, int? sinceHours}) async {
    final params = <String, dynamic>{'limit': limit};
    if (sinceHours != null) {
      params['from'] = DateTime.now().subtract(Duration(hours: sinceHours)).toUtc().toIso8601String();
    }
    final response = await _dio.get('/api/notifications', queryParameters: params);
    final payload = response.data;
    if (payload is! List) return const <NotificationModel>[];
    return payload
        .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<SensorEventModel>> fetchSensorEvents({int? days, int limit = 100}) async {
    final response = await _dio.get(
      '/api/sensor-events',
      queryParameters: {
        'limit': limit,
        if (days != null) 'days': days,
      },
    );
    final payload = response.data;
    if (payload is! List) return const <SensorEventModel>[];
    return payload
        .map((item) => SensorEventModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<AnomalyHistoryModel>> fetchAnomalies({int limit = 50}) async {
    final response = await _dio.get(
      '/api/anomalies',
      queryParameters: {'limit': limit},
    );
    final payload = response.data;
    if (payload is! List) return const <AnomalyHistoryModel>[];
    return payload
        .map((item) => AnomalyHistoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<RoutineActivityModel>> fetchRoutine() async {
    final response = await _dio.get('/api/routine').catchError((error) {
      if (error is DioException && error.response?.statusCode == 404) {
        return Response(
          requestOptions: error.requestOptions,
          data: const <dynamic>[],
          statusCode: 200,
        );
      }
      throw error;
    });
    final payload = response.data;
    if (payload is! List) return const <RoutineActivityModel>[];
    return payload
        .map((item) => RoutineActivityModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
