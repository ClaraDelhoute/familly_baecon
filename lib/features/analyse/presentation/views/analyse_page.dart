import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/analyse/data/models/stats_summary_model.dart';
import 'package:familly_baecon/features/analyse/presentation/providers/stats_summary_provider.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';

enum _Period { day, week, month, year }

extension _PeriodApiValue on _Period {
  String get apiValue => switch (this) {
        _Period.day => 'day',
        _Period.week => 'week',
        _Period.month => 'month',
        _Period.year => 'year',
      };
}

class AnalysePage extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;
  const AnalysePage({super.key, this.onNavigate});

  @override
  ConsumerState<AnalysePage> createState() => _AnalysePageState();
}

class _AnalysePageState extends ConsumerState<AnalysePage> {
  _Period _period = _Period.week;

  String get _periodLabel => switch (_period) {
        _Period.day => 'Aujourd\'hui',
        _Period.week => 'Cette semaine',
        _Period.month => 'Ce mois',
        _Period.year => 'Cette année',
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final referenceDate = DateTime(now.year, now.month, now.day);
    final query = StatsSummaryQuery(
      period: _period.apiValue,
      date: referenceDate,
    );
    final statsAsync = ref.watch(statsSummaryProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 20),
            _SectionLabel(_periodLabel),
            const SizedBox(height: 12),
            statsAsync.when(
              data: _buildStatsContent,
              loading: () => const _StatsLoading(),
              error: (error, _) => _StatsErrorCard(
                onRetry: () => ref.invalidate(statsSummaryProvider(query)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent(StatsSummaryModel stats) {
    final isDay = _period == _Period.day;
    final sleepMinutes = isDay ? stats.sleepMinutes : stats.avgSleepMinutes;
    final sleepH = sleepMinutes / 60;
    final sleepLabel = isDay
        ? '${sleepH.toStringAsFixed(1)}h'
        : '${sleepH.toStringAsFixed(1)}h moy.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.restaurant_rounded,
                color: AppTheme.activityPurple,
                value: '${stats.mealsCount}',
                label: 'Repas pris',
                good: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.bedtime_rounded,
                color: AppTheme.activityGreen,
                value: sleepLabel,
                label: isDay ? 'Sommeil' : 'Sommeil moyen',
                good: sleepH >= 6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.nights_stay_rounded,
                color: AppTheme.accentBlue,
                value: _minuteToLabel(stats.avgBedtimeMinute),
                label: 'Heure de coucher',
                good: stats.avgBedtimeMinute == null ||
                    (stats.avgBedtimeMinute! >= 20 * 60 &&
                        stats.avgBedtimeMinute! <= 24 * 60),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.wb_sunny_rounded,
                color: AppTheme.accentCyan,
                value: _minuteToLabel(stats.avgWakeMinute),
                label: 'Heure de réveil',
                good: stats.avgWakeMinute == null ||
                    (stats.avgWakeMinute! >= 6 * 60 &&
                        stats.avgWakeMinute! <= 10 * 60),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.directions_walk_rounded,
                color: AppTheme.activityPurple,
                value: _durationLabel(stats.avgOutingMinutes),
                label: 'Durée sortie moy.',
                good: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.warning_amber_rounded,
                color: AppTheme.activityRed,
                value: '${stats.anomaliesCount}',
                label: 'Anomalies',
                good: stats.anomaliesCount == 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _minuteToLabel(num? minutes) {
    if (minutes == null) return '--';
    final h = (minutes ~/ 60) % 24;
    final m = (minutes % 60).round();
    return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}';
  }

  String _durationLabel(int? minutes) {
    if (minutes == null) return '--';
    if (minutes >= 60) return '${(minutes / 60).toStringAsFixed(1)}h';
    return '${minutes}min';
  }
}

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const periods = [
      (_Period.day, 'Jour'),
      (_Period.week, 'Semaine'),
      (_Period.month, 'Mois'),
      (_Period.year, 'Année'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBgLight,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: periods.map((entry) {
          final (period, label) = entry;
          final isSelected = selected == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool good;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.good,
  });

  @override
  Widget build(BuildContext context) {
    final accent = good ? color : AppTheme.activityRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StatsErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _StatsErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.activityRed.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: AppTheme.activityRed,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            'Impossible de charger les statistiques',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Réessaie dans quelques instants ou vérifie ta connexion.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
