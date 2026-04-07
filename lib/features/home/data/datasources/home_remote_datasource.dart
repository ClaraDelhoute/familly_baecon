import 'package:familly_baecon/features/home/data/models/activity_model.dart';
import 'package:familly_baecon/features/home/data/models/home_summary_model.dart';
import 'package:familly_baecon/features/home/data/clients/home_api_client.dart';

class HomeRemoteDataSource {
  final HomeApiClient client;

  HomeRemoteDataSource(this.client);

  Future<List<ActivityModel>> fetchActivities({required String deviceId, required DateTime from, required DateTime to}) async {
    final resp = await client.fetchActivities(deviceId: deviceId, from: from, to: to);
    final data = resp.data;
    if (data == null) return [];
    final activitiesJson = data['activities'] as List<dynamic>? ?? [];
    return activitiesJson.map((e) => ActivityModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<HomeSummaryModel> fetchHomeSummary({required String userId, required DateTime date}) async {
    final resp = await client.fetchHomeSummary(userId: userId, date: date);
    final data = resp.data as Map<String, dynamic>;
    return HomeSummaryModel.fromJson(data);
  }
}
