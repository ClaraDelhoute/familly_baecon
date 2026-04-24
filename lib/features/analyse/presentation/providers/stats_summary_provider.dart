import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/config/app_config.dart';
import 'package:familly_baecon/core/network/dio_provider.dart';
import 'package:familly_baecon/features/analyse/data/datasources/stats_remote_datasource.dart';
import 'package:familly_baecon/features/analyse/data/models/stats_summary_model.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';

final _statsDioProvider = Provider((ref) => DioProvider.create());

final _statsRemoteDataSourceProvider = Provider((ref) {
  return StatsRemoteDataSource(ref.watch(_statsDioProvider));
});

final statsSummaryProvider = FutureProvider.autoDispose
    .family<StatsSummaryModel, StatsSummaryQuery>((ref, query) async {
  final datasource = ref.watch(_statsRemoteDataSourceProvider);

  try {
    final summary = await datasource.fetchSummary(
      period: query.period,
      date: query.formattedDate,
      timezone: query.timezone,
      personId: query.personId,
    );
    ref.read(backendApiConnectedProvider.notifier).state = true;
    ref.read(backendLastSyncAtProvider.notifier).state = DateTime.now();
    return summary;
  } catch (error) {
    if (error is DioException) {
      ref.read(backendApiConnectedProvider.notifier).state = false;
    }
    rethrow;
  }
});

class StatsSummaryQuery {
  final String period;
  final DateTime date;
  final String timezone;
  final String? personId;

  const StatsSummaryQuery({
    required this.period,
    required this.date,
    this.timezone = AppConfig.statsTimezone,
    this.personId,
  });

  String get formattedDate {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsSummaryQuery &&
          period == other.period &&
          formattedDate == other.formattedDate &&
          timezone == other.timezone &&
          personId == other.personId;

  @override
  int get hashCode => Object.hash(period, formattedDate, timezone, personId);
}
