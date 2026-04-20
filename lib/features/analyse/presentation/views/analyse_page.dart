import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/providers/watched_person_provider.dart';
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
    final anomalies =
        ref.watch(liveAnomaliesProvider).valueOrNull ?? const [];
    final name = ref.watch(watchedPersonNameProvider);

    final dailyStats = BehaviorStatsService.buildDailyStats(observed, maxDays: 14);

    // Stats semaine courante (7 derniers jours)
    final weekStats = dailyStats.length >= 7
        ? dailyStats.sublist(dailyStats.length - 7)
        : dailyStats;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final anomaliesThisWeek =
        anomalies.where((a) => a.lastSeenAt.isAfter(weekAgo)).length;

    final mealsThisWeek = weekStats.fold(0, (s, d) => s + d.mealsCount);
    final maxMealsPossible = weekStats.length * 3;

    final avgSleepH = weekStats.isEmpty
        ? 0.0
        : weekStats.fold(0, (s, d) => s + d.sleepMinutes) /
            weekStats.length /
            60;

    // Routine score : % de jours avec ≥2 repas et ≥4h de sommeil
    final goodDays = weekStats
        .where((d) => d.mealsCount >= 2 && d.sleepMinutes >= 240)
        .length;
    final routineScore =
        weekStats.isEmpty ? 0.0 : goodDays / weekStats.length;

    // Nuits courtes : sommeil < 5h
    final disturbedNights =
        weekStats.where((d) => d.sleepMinutes < 300).length;

    // Jours sans activité détectée
    final inactiveDays =
        weekStats.where((d) => d.totalActivities == 0).length;

    // Lever moyen : moyenne des firstActivityMinute des jours avec données
    final daysWithFirst = weekStats
        .where((d) => d.firstActivityMinute != null)
        .toList();
    final avgFirstMinute = daysWithFirst.isEmpty
        ? null
        : daysWithFirst
                .map((d) => d.firstActivityMinute!)
                .reduce((a, b) => a + b) /
            daysWithFirst.length;
    final avgFirstLabel = avgFirstMinute == null
        ? '--'
        : '${(avgFirstMinute ~/ 60).toString().padLeft(2, '0')}h'
            '${(avgFirstMinute % 60).round().toString().padLeft(2, '0')}';
    final avgFirstGood =
        avgFirstMinute != null && avgFirstMinute >= 6 * 60 && avgFirstMinute <= 10 * 60;

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
            _RoutineGauge(score: routineScore, name: name),
            const SizedBox(height: 20),
            _SectionLabel('Cette semaine'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.restaurant_rounded,
                    color: AppTheme.activityPurple,
                    value: '$mealsThisWeek',
                    label: 'Repas pris',
                    sub: 'sur $maxMealsPossible possibles',
                    good: mealsThisWeek >= (maxMealsPossible * 0.75).round(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.bedtime_rounded,
                    color: AppTheme.activityGreen,
                    value: '${avgSleepH.toStringAsFixed(1)}h',
                    label: 'Sommeil moyen',
                    sub: 'par nuit',
                    good: avgSleepH >= 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.nightlight_round,
                    color: AppTheme.accentBlue,
                    value: '$disturbedNights',
                    label: 'Nuits courtes',
                    sub: 'moins de 5h de sommeil',
                    good: disturbedNights == 0,
                    goodIsZero: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.activityRed,
                    value: '$anomaliesThisWeek',
                    label: 'Anomalies',
                    sub: 'détectées cette semaine',
                    good: anomaliesThisWeek == 0,
                    goodIsZero: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.wb_sunny_rounded,
                    color: AppTheme.accentCyan,
                    value: avgFirstLabel,
                    label: 'Lever moyen',
                    sub: 'première activité du matin',
                    good: avgFirstGood,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.do_not_disturb_on_rounded,
                    color: AppTheme.activityRed,
                    value: '$inactiveDays',
                    label: 'Jours sans activité',
                    sub: 'aucun capteur déclenché',
                    good: inactiveDays == 0,
                    goodIsZero: true,
                  ),
                ),
              ],
            ),
          ],
        ),
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

// ── Jauge circulaire ────────────────────────────────────────────────────────

class _RoutineGauge extends StatelessWidget {
  final double score; // 0.0 → 1.0
  final String name;

  const _RoutineGauge({required this.score, required this.name});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    final Color accent = pct >= 75
        ? AppTheme.activityGreen
        : pct >= 50
            ? AppTheme.accentBlue
            : AppTheme.activityRed;

    final String label = pct >= 75
        ? 'Bonne semaine'
        : pct >= 50
            ? 'Semaine correcte'
            : 'Semaine difficile';

    final String sub = pct >= 75
        ? 'La routine de $name est bien respectée.'
        : pct >= 50
            ? 'Quelques écarts dans la routine de $name.'
            : 'La routine de $name est perturbée cette semaine.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.85), accent.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _GaugePainter(score: score, color: Colors.white),
              child: Center(
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sub,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  const _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 8;
    const strokeWidth = 8.0;
    const startAngle = -math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * score.clamp(0.0, 1.0),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score;
}

// ── Tuile stat ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String sub;
  final bool good;
  final bool goodIsZero;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.sub,
    required this.good,
    this.goodIsZero = false,
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
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

