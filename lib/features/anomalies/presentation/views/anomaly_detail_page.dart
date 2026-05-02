import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/domain/activity_type.dart';
import 'package:familly_baecon/core/domain/anomaly_type.dart';
import 'package:familly_baecon/core/providers/watched_person_provider.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';
import 'package:familly_baecon/features/anomalies/presentation/providers/anomaly_read_provider.dart';
import 'package:familly_baecon/features/journal/data/models/routine_activity_model.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

class AnomalyDetailPage extends ConsumerWidget {
  final AnomalyHistoryModel anomaly;

  const AnomalyDetailPage({super.key, required this.anomaly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Marquer comme lu dès l'ouverture
    ref.read(anomalyReadProvider.notifier).markRead(anomaly.id);

    final textTheme = Theme.of(context).textTheme;
    final isHigh = anomaly.severity == 'high';
    final accent = isHigh ? AppTheme.activityRed : AppTheme.accentBlue;
    final activityTime = _toLocal(anomaly.simulatedAt);
    final notifTime = _toLocal(anomaly.lastSeenAt);
    final name = ref.watch(watchedPersonNameProvider);
    final title = _prettyTitle(anomaly, name);

    // Heure habituelle depuis la routine
    final routine = ref.watch(liveRoutineProvider).valueOrNull ?? const [];
    final routineEntry = _matchRoutine(routine, anomaly.activityKey);
    // sleep : toujours montrer l'heure de réveil habituelle (startMin + duration)
    // timing/duration_* autres activités : heure de fin habituelle
    // missing : heure de début habituelle
    final _showEndLabel = anomaly.activityKey == 'sleep' ||
        anomaly.anomalyType == 'timing' ||
        anomaly.anomalyType == 'duration_long' ||
        anomaly.anomalyType == 'duration_short';
    final usualTimeLabel = _showEndLabel
        ? routineEntry?.endLabel
        : routineEntry?.startLabel;
    final usualDurationLabel = routineEntry?.durationLabel;
    final bedtimeLabel = anomaly.activityKey == 'sleep'
        ? routineEntry?.bedtimeLabel
        : null;

    // Heure détectée depuis simulatedAt (fiable)
    final detectedTimeLabel = anomaly.anomalyType != 'missing'
        ? '${activityTime.hour.toString().padLeft(2, '0')}h${activityTime.minute.toString().padLeft(2, '0')}'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeroCard(
            icon: _iconForActivity(anomaly.activityKey),
            accent: accent,
            title: title,
          ),
          const SizedBox(height: 18),
          _SectionTitle('Activité détectée'),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: _dayLabel(activityTime),
                accent: accent,
              ),
              const _Separator(),
              _InfoRow(
                icon: Icons.schedule_rounded,
                label:
                    'À ${activityTime.hour.toString().padLeft(2, '0')}h${activityTime.minute.toString().padLeft(2, '0')}',
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionTitle('Notification reçue'),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.notifications_rounded,
                label: _relativeDay(notifTime),
                accent: context.palette.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle('Pourquoi cette alerte ?'),
          const SizedBox(height: 8),
          _AlertExplanationCard(
            anomaly: anomaly,
            accent: accent,
            textTheme: textTheme,
            detectedTimeLabel: detectedTimeLabel,
            usualTimeLabel: usualTimeLabel,
            usualDurationLabel: usualDurationLabel,
            bedtimeLabel: bedtimeLabel,
          ),
        ],
      ),
    );
  }
}

// ── Hero card (sans badge severity) ──────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;

  const _HeroCard({
    required this.icon,
    required this.accent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: (textTheme.headlineSmall ?? const TextStyle(fontSize: 22))
                .copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Explication enrichie ──────────────────────────────────────────────────────

class _AlertExplanationCard extends StatelessWidget {
  final AnomalyHistoryModel anomaly;
  final Color accent;
  final TextTheme textTheme;
  final String? detectedTimeLabel;
  final String? usualTimeLabel;
  final String? usualDurationLabel;
  final String? bedtimeLabel;

  const _AlertExplanationCard({
    required this.anomaly,
    required this.accent,
    required this.textTheme,
    this.detectedTimeLabel,
    this.usualTimeLabel,
    this.usualDurationLabel,
    this.bedtimeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String)>[];

    if (anomaly.anomalyType == 'missing') {
      rows.add((Icons.not_interested_rounded, 'Activité absente ce jour'));
    } else {
      if (detectedTimeLabel != null) {
        rows.add((Icons.schedule_rounded, 'Réveil détecté : $detectedTimeLabel'));
      }
      if (usualTimeLabel != null && usualTimeLabel!.isNotEmpty) {
        final timeLabel = anomaly.anomalyType == 'timing'
            ? 'Réveil habituel : $usualTimeLabel'
            : 'Réveil habituel : $usualTimeLabel';
        rows.add((Icons.history_rounded, timeLabel));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.palette.textSecondary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              _explanationByType(anomaly.anomalyType),
              style: textTheme.bodyMedium?.copyWith(
                color: context.palette.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          if (rows.isNotEmpty) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: context.palette.textSecondary.withValues(alpha: 0.1),
              indent: 16,
              endIndent: 16,
            ),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.palette.textSecondary.withValues(alpha: 0.07),
                  indent: 56,
                  endIndent: 16,
                ),
              _DataRow(icon: rows[i].$1, label: rows[i].$2, accent: accent),
            ],
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Routine matching ──────────────────────────────────────────────────────────

RoutineActivityModel? _matchRoutine(
  List<RoutineActivityModel> routine,
  String activityKey,
) {
  // Correspondance activityKey → sensorType attendu dans la routine
  final targetSensor = switch (activityKey) {
    'daily_activity' => 'activity_profile',
    _                => activityKey,
  };

  try {
    return routine.firstWhere(
      (r) => r.sensorType.toLowerCase() == targetSensor.toLowerCase(),
    );
  } catch (_) {
    // Correspondance partielle stricte : les deux tokens doivent se contenir mutuellement
    // sans confusion petit-dejeuner ↔ dejeuner
    final target = targetSensor.toLowerCase();
    try {
      return routine.firstWhere((r) {
        final s = r.sensorType.toLowerCase();
        // Évite que 'petit-dejeuner'.contains('dejeuner') matche l'entrée déjeuner
        if (target.contains('petit') != s.contains('petit')) return false;
        return s.contains(target) || target.contains(s);
      });
    } catch (_) {
      return null;
    }
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.palette.textSecondary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.palette.textSecondary.withValues(alpha: 0.08),
      indent: 16,
      endIndent: 16,
    );
  }
}

IconData _iconForActivity(String activityKey) =>
    ActivityType.fromKey(activityKey).icon;

String _prettyActivityLabel(String activityKey) =>
    ActivityType.fromKey(activityKey).subject;

String _prettyTitle(AnomalyHistoryModel anomaly, String personName) {
  final type = anomaly.anomalyType;
  final who = personName.isNotEmpty ? personName : null;

  if (who != null) {
    return switch (anomaly.activityKey) {
      'sleep' => switch (type) {
        'missing'        => '$who n\'a pas dormi cette nuit.',
        'timing'         => '$who s\'est couché(e) à un horaire inhabituel.',
        'duration_short' => '$who a dormi moins longtemps que d\'habitude.',
        'duration_long'  => '$who a dormi plus longtemps que d\'habitude.',
        'freq_high'      => '$who s\'est recouché(e) plus souvent que d\'habitude.',
        'freq_low'       => '$who a peu dormi aujourd\'hui.',
        _                => '$who a eu un sommeil inhabituel.',
      },
      'petit-déjeuner' => switch (type) {
        'missing'        => '$who n\'a pas pris son petit-déjeuner ce matin.',
        'timing'         => '$who a petit-déjeuné à un horaire inhabituel.',
        'duration_short' => '$who a pris un petit-déjeuner plus rapide que d\'habitude.',
        'duration_long'  => '$who a pris un petit-déjeuner plus long que d\'habitude.',
        _                => '$who a eu un petit-déjeuner inhabituel.',
      },
      'déjeuner' => switch (type) {
        'missing'        => '$who n\'a pas déjeuné aujourd\'hui.',
        'timing'         => '$who a déjeuné à un horaire inhabituel.',
        'duration_short' => '$who a déjeuné plus rapidement que d\'habitude.',
        'duration_long'  => '$who a déjeuné plus longuement que d\'habitude.',
        _                => '$who a eu un déjeuner inhabituel.',
      },
      'souper' => switch (type) {
        'missing'        => '$who n\'a pas soupé ce soir.',
        'timing'         => '$who a soupé à un horaire inhabituel.',
        'duration_short' => '$who a soupé plus rapidement que d\'habitude.',
        'duration_long'  => '$who a soupé plus longuement que d\'habitude.',
        _                => '$who a eu un souper inhabituel.',
      },
      'outside' => switch (type) {
        'missing'        => '$who n\'est pas sorti(e) aujourd\'hui.',
        'timing'         => '$who est sorti(e) à un horaire inhabituel.',
        'duration_short' => '$who est resté(e) sorti(e) moins longtemps que d\'habitude.',
        'duration_long'  => '$who est resté(e) sorti(e) plus longtemps que d\'habitude.',
        'freq_high'      => '$who est sorti(e) plus souvent que d\'habitude.',
        'freq_low'       => '$who sort moins souvent que d\'habitude.',
        _                => '$who a eu une sortie inhabituelle.',
      },
      _ => 'Comportement inhabituel détecté pour $who.',
    };
  }

  final label = _prettyActivityLabel(anomaly.activityKey);
  final cap = '${label[0].toUpperCase()}${label.substring(1)}';
  return switch (type) {
    'missing'        => '$cap absent aujourd\'hui.',
    'timing'         => '$cap à un horaire inhabituel.',
    'duration_short' => '$cap plus court que d\'habitude.',
    'duration_long'  => '$cap plus long que d\'habitude.',
    'freq_high'      => '$cap plus fréquent que d\'habitude.',
    'freq_low'       => '$cap moins fréquent que d\'habitude.',
    _                => '$cap : comportement inhabituel.',
  };
}

String _explanationByType(String type) =>
    AnomalyType.fromKey(type).explanation;

String _dayLabel(DateTime day) {
  final today = _todayFrance();
  final d = DateTime(day.year, day.month, day.day);
  if (_isSameDay(d, today)) return "Aujourd'hui";
  final yesterday = today.subtract(const Duration(days: 1));
  if (_isSameDay(d, yesterday)) return 'Hier';
  const weekdays = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche',
  ];
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  final weekday = weekdays[day.weekday - 1];
  final month = months[day.month - 1];
  final cap = '${weekday[0].toUpperCase()}${weekday.substring(1)}';
  return '$cap ${day.day} $month';
}

String _relativeDay(DateTime dt) {
  final today = _todayFrance();
  final d = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(d).inDays;
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  if (diff == 0) return "aujourd'hui à ${hh}h$mm";
  if (diff == 1) return 'hier à ${hh}h$mm';
  if (diff < 7) return 'il y a $diff jours à ${hh}h$mm';
  return 'le ${_dayLabel(dt).toLowerCase()} à ${hh}h$mm';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _toLocal(DateTime dt) => dt.toLocal();

DateTime _todayFrance() {
  final n = _toLocal(DateTime.now());
  return DateTime(n.year, n.month, n.day);
}

