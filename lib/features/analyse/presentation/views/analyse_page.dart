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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Indicateurs'),
            const SizedBox(height: 14),
            ...declineMetrics.map(
              (metric) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DeclineMetricCard(metric: metric),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Évolution quotidienne (28 jours)'),
            const SizedBox(height: 14),
            _SimpleTrendChart(dailyStats: dailyStats),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Résumé des tendances'),
            const SizedBox(height: 14),
            _TrendSummaryCard(metrics: declineMetrics),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _surfaceDecoration() => BoxDecoration(
      color: AppTheme.darkBgLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppTheme.textSecondary.withValues(alpha: 0.12),
      ),
    );

class _DeclineMetricCard extends StatelessWidget {
  final DeclineMetric metric;

  const _DeclineMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final decline = metric.isDecline;
    final color = decline ? AppTheme.activityRed : AppTheme.activityGreen;
    final delta = metric.deltaPercent;
    final deltaLabel = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%';

    return Container(
      decoration: _surfaceDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              decline ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '7j: ${metric.recentAverage.toStringAsFixed(1)} ${metric.unit}  •  '
                  'Réf: ${metric.previousAverage.toStringAsFixed(1)} ${metric.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              deltaLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
      return Container(
        decoration: _surfaceDecoration(),
        height: 220,
        child: Center(
          child: Text(
            'Pas assez de données pour afficher un graphique.',
            style: TextStyle(color: AppTheme.textSecondary),
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

    return Container(
      decoration: _surfaceDecoration(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in dailyStats.take(14))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 6,
                                height:
                                    90 * ((day.sleepMinutes / 60) / maxSleep),
                                decoration: BoxDecoration(
                                  color: AppTheme.activityGreen,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 6,
                                height: 60 * (day.mealsCount / maxMeals),
                                decoration: BoxDecoration(
                                  color: AppTheme.activityOrange,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 6,
                                height:
                                    50 * (day.otherActivitiesCount / maxOther),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue,
                                  borderRadius: BorderRadius.circular(3),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: const [
              _LegendDot(color: AppTheme.activityGreen, label: 'Sommeil (h)'),
              _LegendDot(color: AppTheme.activityOrange, label: 'Repas'),
              _LegendDot(color: AppTheme.accentBlue, label: 'Autres'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TrendSummaryCard extends StatelessWidget {
  final List<DeclineMetric> metrics;

  const _TrendSummaryCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final declining = metrics.where((m) => m.isDecline).toList();
    final hasIssue = declining.isNotEmpty;
    final accent = hasIssue ? AppTheme.activityOrange : AppTheme.activityGreen;

    return Container(
      decoration: _surfaceDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasIssue
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasIssue
                  ? 'Signaux de déclin détectés : ${declining.map((m) => m.label).join(', ')}.'
                  : 'Aucun signal de déclin marqué détecté sur la période récente.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                height: 1.4,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
