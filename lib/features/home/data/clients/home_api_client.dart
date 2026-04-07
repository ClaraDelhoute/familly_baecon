import 'package:dio/dio.dart';

class HomeApiClient {
  final Dio _dio;

  HomeApiClient(this._dio);

  Future<Response> fetchActivities({required String deviceId, required DateTime from, required DateTime to}) {
    final fromIso = from.toUtc().toIso8601String();
    final toIso = to.toUtc().toIso8601String();
    return _dio.get('/v1/devices/$deviceId/activities', queryParameters: {
      'from': fromIso,
      'to': toIso,
    });
  }

  Future<Response> fetchHomeSummary({required String userId, required DateTime date}) {
    final dateStr = date.toIso8601String();
    return _dio.get('/v1/users/$userId/summary', queryParameters: {
      'date': dateStr,
    });
  }
}

