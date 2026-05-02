import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/analyse/data/models/stats_summary_model.dart';
import 'package:familly_baecon/features/analyse/presentation/providers/stats_summary_provider.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

enum _Period { day, week, month, year }

extension _PeriodApiValue on _Period {
  String get apiValue => switch (this) {
        _Period.day => 'day',
        _Period.week => 'week',
        _Period.month => 'month',
        _Period.year => 'year',
      };

  String get sectionLabel => switch (this) {
        _Period.day => "Aujourd'hui",
        _Period.week => 'Cette semaine',
        _Period.month => 'Ce mois',
        _Period.year => 'Cette année',
      };
}

final _analysePeriodProvider = StateProvider<_Period>((ref) => _Period.week);

class AnalysePage extends ConsumerWidget {
  final Function(int)? onNavigate;
  const AnalysePage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_analysePeriodProvider);
    final now = DateTime.now();
    final referenceDate = DateTime(now.year, now.month, now.day);
    final query = StatsSummaryQuery(
      period: period.apiValue,
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
              selected: period,
              onChanged: (p) =>
                  ref.read(_analysePeriodProvider.notifier).state = p,
            ),
            const SizedBox(height: 20),
            _SectionLabel(period.sectionLabel),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (result) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.fromCache) ...[
                    _OfflineBanner(
                      cachedAt: result.cachedAt,
                      onRetry: () =>
                          ref.invalidate(statsSummaryProvider(query)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildStatsContent(result.summary, period),
                ],
              ),
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
}

Widget _buildStatsContent(StatsSummaryModel stats, _Period period) {
  final isDay = period == _Period.day;
  final sleepMinutes = isDay ? stats.sleepMinutes : stats.avgSleepMinutes;
  final sleepH = sleepMinutes ~/ 60;
  final sleepM = sleepMinutes % 60;
  final sleepFmt = sleepM == 0 ? '${sleepH}h' : '${sleepH}h${sleepM.toString().padLeft(2, '0')}';
  final sleepLabel = isDay ? sleepFmt : '$sleepFmt moy.';

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
  if (minutes >= 60) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }
  return '${minutes}min';
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
        color: context.palette.surface,
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
                    color: isSelected ? Colors.white : context.palette.textSecondary,
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
        color: context.palette.textSecondary,
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
        color: context.palette.surface,
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
              color: context.palette.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: context.palette.textPrimary,
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

class _OfflineBanner extends StatelessWidget {
  final DateTime? cachedAt;
  final VoidCallback onRetry;

  const _OfflineBanner({required this.cachedAt, required this.onRetry});

  String _formatCachedAt(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) return "aujourd'hui à ${hh}h$mm";
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return 'le $dd/$mo à ${hh}h$mm';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = cachedAt == null
        ? 'Affichage des dernières données enregistrées.'
        : 'Dernière mise à jour ${_formatCachedAt(cachedAt!)}.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentCyan.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: AppTheme.accentCyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode hors ligne',
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Réessayer',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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
        color: context.palette.surface,
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
              color: context.palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Réessaie dans quelques instants ou vérifie ta connexion.',
            style: TextStyle(color: context.palette.textSecondary, fontSize: 13),
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
