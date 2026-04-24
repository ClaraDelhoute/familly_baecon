import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:familly_baecon/features/analyse/data/models/stats_summary_model.dart';

class CachedStatsSummary {
  final StatsSummaryModel summary;
  final DateTime cachedAt;

  const CachedStatsSummary({required this.summary, required this.cachedAt});
}

class StatsLocalDataSource {
  static const String _keyPrefix = 'cached_stats_summary::';

  String _key(String cacheKey) => '$_keyPrefix$cacheKey';

  Future<void> save(String cacheKey, StatsSummaryModel summary) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'cached_at': DateTime.now().toIso8601String(),
      'summary': summary.toJson(),
    };
    await prefs.setString(_key(cacheKey), jsonEncode(payload));
  }

  Future<CachedStatsSummary?> load(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(cacheKey));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final summary = StatsSummaryModel.fromJson(
        Map<String, dynamic>.from(map['summary'] as Map),
      );
      final cachedAt =
          DateTime.tryParse((map['cached_at'] as String?) ?? '') ??
              DateTime.now();
      return CachedStatsSummary(summary: summary, cachedAt: cachedAt);
    } catch (_) {
      await prefs.remove(_key(cacheKey));
      return null;
    }
  }
}
