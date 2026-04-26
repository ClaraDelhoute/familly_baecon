import 'package:dio/dio.dart';
import 'package:familly_baecon/features/analyse/data/models/stats_summary_model.dart';

class StatsRemoteDataSource {
  final Dio _dio;

  StatsRemoteDataSource(this._dio);

  Future<StatsSummaryModel> fetchSummary({
    required String period,
    required String date,
    required String timezone,
    String? personId,
  }) async {
    final response = await _dio.get(
      '/api/stats/summary',
      queryParameters: {
        'period': period,
        'date': date,
        'tz': timezone,
        if (personId != null && personId.isNotEmpty) 'personId': personId,
      },
    );
    final payload = response.data;
    if (payload is! Map) {
      throw FormatException(
        '/api/stats/summary invalid payload type=${payload.runtimeType}',
      );
    }
    return StatsSummaryModel.fromJson(Map<String, dynamic>.from(payload));
  }
}
