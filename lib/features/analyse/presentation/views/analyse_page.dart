import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/analyse/domain/services/behavior_stats_service.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';

class AnalysePage extends ConsumerWidget {
  final Function(int)? onNavigate;
  const AnalysePage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observed =
        ref.watch(liveObservedActivitiesProvider).valueOrNull ?? const [];
    final dailyStats = BehaviorStatsService.buildDailyStats(
      observed,
      maxDays: 28,
    );
    final declineMetrics = BehaviorStatsService.buildDeclineMetrics(dailyStats);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicateurs de déclin',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...declineMetrics.map(
              (metric) => _DeclineMetricCard(metric: metric),
            ),
            const SizedBox(height: 24),
            Text(
              'Évolution quotidienne (28 jours)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _SimpleTrendChart(dailyStats: dailyStats),
            const SizedBox(height: 24),
            Text(
              'Résumé des tendances',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _TrendSummaryCard(metrics: declineMetrics),
          ],
        ),
      ),
    );
  }
}

class _DeclineMetricCard extends StatelessWidget {
  final DeclineMetric metric;

  const _DeclineMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final decline = metric.isDecline;
    final color = decline ? AppTheme.activityRed : AppTheme.activityGreen;
    final delta = metric.deltaPercent;
    final deltaLabel = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          decline ? Icons.trending_down_rounded : Icons.trending_up_rounded,
          color: color,
        ),
        title: Text(metric.label),
        subtitle: Text(
          '7j: ${metric.recentAverage.toStringAsFixed(1)} ${metric.unit} • '
          'Référence: ${metric.previousAverage.toStringAsFixed(1)} ${metric.unit}',
        ),
        trailing: Text(
          deltaLabel,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SimpleTrendChart extends StatelessWidget {
  final List<DailyBehaviorStats> dailyStats;

  const _SimpleTrendChart({required this.dailyStats});

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return Card(
        child: SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'Pas assez de données pour afficher un graphique.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    final maxSleep = dailyStats
        .map((d) => d.sleepMinutes / 60)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 24);
    final maxMeals = dailyStats
        .map((d) => d.mealsCount.toDouble())
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 6);
    final maxOther = dailyStats
        .map((d) => d.otherActivitiesCount.toDouble())
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 20);

    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in dailyStats.take(14))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 4,
                              height: 90 * ((day.sleepMinutes / 60) / maxSleep),
                              decoration: BoxDecoration(
                                color: AppTheme.activityGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 4,
                              height: 60 * (day.mealsCount / maxMeals),
                              decoration: BoxDecoration(
                                color: AppTheme.activityOrange,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 4,
                              height:
                                  50 * (day.otherActivitiesCount / maxOther),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendSummaryCard extends StatelessWidget {
  final List<DeclineMetric> metrics;

  const _TrendSummaryCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final declining = metrics.where((m) => m.isDecline).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          declining.isEmpty
              ? 'Aucun signal de déclin marqué détecté sur la période récente.'
              : 'Signaux de déclin détectés: ${declining.map((m) => m.label).join(', ')}.',
          style: TextStyle(
            color: declining.isEmpty
                ? AppTheme.textPrimary
                : AppTheme.activityOrange,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
