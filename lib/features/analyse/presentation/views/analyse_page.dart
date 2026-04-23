import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/analyse/domain/services/behavior_stats_service.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';

enum _Period { day, week, month, year }

class AnalysePage extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;
  const AnalysePage({super.key, this.onNavigate});

  @override
  ConsumerState<AnalysePage> createState() => _AnalysePageState();
}

class _AnalysePageState extends ConsumerState<AnalysePage> {
  _Period _period = _Period.week;

  int get _maxDays => switch (_period) {
        _Period.day => 1,
        _Period.week => 7,
        _Period.month => 30,
        _Period.year => 365,
      };

  String get _periodLabel => switch (_period) {
        _Period.day => 'Aujourd\'hui',
        _Period.week => 'Cette semaine',
        _Period.month => 'Ce mois',
        _Period.year => 'Cette année',
      };

  @override
  Widget build(BuildContext context) {
    final observed =
        ref.watch(liveObservedActivitiesProvider).valueOrNull ?? const [];
    final anomalies =
        ref.watch(liveAnomaliesProvider).valueOrNull ?? const [];

    final now = DateTime.now();

    // Heure simulée courante : simulatedAt le plus récent parmi les anomalies
    // du jour. Permet d'exclure les activités qui n'ont pas encore eu lieu.
    final todayAnomalies = anomalies.where((a) {
      final d = a.simulatedAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final simulatedNow = todayAnomalies.isEmpty
        ? now
        : todayAnomalies
            .map((a) => a.simulatedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);

    final periodStart = simulatedNow.subtract(Duration(days: _maxDays));

    // Activités passées uniquement (startAt <= heure simulée courante)
    final pastObserved = observed
        .where((a) => !a.startAt.isAfter(simulatedNow))
        .toList();

    final dailyStats =
        BehaviorStatsService.buildDailyStats(pastObserved, maxDays: _maxDays);

    final periodAnomalies =
        anomalies.where((a) => a.lastSeenAt.isAfter(periodStart)).length;

    final periodActivities = pastObserved
        .where((a) => a.startAt.isAfter(periodStart))
        .toList();

    final isDay = _period == _Period.day;

    // Nombre de repas — brut pour le jour, cumulé sinon
    final mealsCount = isDay
        ? (dailyStats.isEmpty ? 0 : dailyStats.last.mealsCount)
        : dailyStats.fold(0, (s, d) => s + d.mealsCount);

    // Sommeil — durée brute pour le jour, moyenne sinon
    final sleepH = isDay
        ? (dailyStats.isEmpty ? 0.0 : dailyStats.last.sleepMinutes / 60)
        : (dailyStats.isEmpty
            ? 0.0
            : dailyStats.fold(0, (s, d) => s + d.sleepMinutes) /
                dailyStats.length /
                60);
    final sleepLabel = isDay
        ? '${sleepH.toStringAsFixed(1)}h'
        : '${sleepH.toStringAsFixed(1)}h moy.';
    final sleepGood = sleepH >= 6;

    final sleepActivities =
        periodActivities.where((a) => a.type == 'sleep').toList();

    // Coucher : heure de début du sleep
    final bedtimeMinutes = sleepActivities
        .map((a) => a.startAt.toLocal().hour * 60 + a.startAt.toLocal().minute)
        .toList();
    final avgBedtimeMinute = bedtimeMinutes.isEmpty
        ? null
        : bedtimeMinutes.reduce((a, b) => a + b) / bedtimeMinutes.length;
    final avgBedtimeLabel = _minuteToLabel(avgBedtimeMinute);

    // Réveil : heure de fin du sleep
    final wakeMinutes = sleepActivities
        .map((a) {
          if (a.endAt != null) {
            final e = a.endAt!.toLocal();
            return e.hour * 60 + e.minute;
          } else if (a.durationMin != null) {
            final end = a.startAt.add(Duration(minutes: a.durationMin!)).toLocal();
            return end.hour * 60 + end.minute;
          }
          return null;
        })
        .whereType<int>()
        .toList();
    final avgWakeMinute = wakeMinutes.isEmpty
        ? null
        : wakeMinutes.reduce((a, b) => a + b) / wakeMinutes.length;
    final avgWakeLabel = _minuteToLabel(avgWakeMinute);

    // Durée sortie — brute pour le jour, moyenne sinon
    final outingActivities =
        periodActivities.where((a) => a.type == 'sortie').toList();
    final outingDurations = outingActivities
        .map((a) {
          if (a.durationMin != null) return a.durationMin!;
          if (a.endAt != null) return a.endAt!.difference(a.startAt).inMinutes;
          return null;
        })
        .whereType<int>()
        .toList();
    final avgOutingMin = outingDurations.isEmpty
        ? null
        : outingDurations.reduce((a, b) => a + b) /
            (isDay ? 1 : outingDurations.length);
    final avgOutingLabel = avgOutingMin == null
        ? '--'
        : avgOutingMin >= 60
            ? '${(avgOutingMin / 60).toStringAsFixed(1)}h'
            : '${avgOutingMin.round()}min';

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
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.restaurant_rounded,
                    color: AppTheme.activityPurple,
                    value: '$mealsCount',
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
                    good: sleepGood,
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
                    value: avgBedtimeLabel,
                    label: 'Heure de coucher',
                    good: avgBedtimeMinute == null ||
                        (avgBedtimeMinute >= 20 * 60 &&
                            avgBedtimeMinute <= 24 * 60),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.wb_sunny_rounded,
                    color: AppTheme.accentCyan,
                    value: avgWakeLabel,
                    label: 'Heure de réveil',
                    good: avgWakeMinute == null ||
                        (avgWakeMinute >= 6 * 60 && avgWakeMinute <= 10 * 60),
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
                    value: avgOutingLabel,
                    label: 'Durée sortie moy.',
                    good: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.activityRed,
                    value: '$periodAnomalies',
                    label: 'Anomalies',
                    good: periodAnomalies == 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _minuteToLabel(double? minutes) {
    if (minutes == null) return '--';
    final h = (minutes ~/ 60) % 24;
    final m = (minutes % 60).round();
    return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}';
  }
}

// ── Period selector ───────────────────────────────────────────────────────────

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
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
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

// ── Section label ─────────────────────────────────────────────────────────────

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

// ── Stat tile ─────────────────────────────────────────────────────────────────

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
