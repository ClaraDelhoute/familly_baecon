import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/providers/watched_person_provider.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';

class AnomalyDetailPage extends ConsumerWidget {
  final AnomalyHistoryModel anomaly;

  const AnomalyDetailPage({super.key, required this.anomaly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isHigh = anomaly.severity == 'high';
    final accent = isHigh ? AppTheme.activityRed : AppTheme.accentBlue;
    final activityTime = _toFranceTime(anomaly.simulatedAt);
    final notifTime = _toFranceTime(anomaly.lastSeenAt);
    final firstSeen = _toFranceTime(anomaly.firstDetectedAt);
    final name = ref.watch(watchedPersonNameProvider);
    final title = _prettyTitle(anomaly, name);

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
            severityLabel: isHigh ? 'Important' : 'À surveiller',
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
                accent: AppTheme.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle('Pourquoi cette alerte ?'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkBgLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              _explanationByType(anomaly.anomalyType),
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          ...(() {
            final metrics = _extractMetrics(anomaly.message);
            if (metrics.isEmpty) return const <Widget>[];
            return [
              const SizedBox(height: 18),
              _SectionTitle('Valeurs mesurées'),
              const SizedBox(height: 8),
              _InfoCard(
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    if (i > 0) const _Separator(),
                    _InfoRow(
                      icon: Icons.insights_rounded,
                      label: metrics[i],
                      accent: accent,
                    ),
                  ],
                ],
              ),
            ];
          })(),
          if (anomaly.seenCount > 1) ...[
            const SizedBox(height: 18),
            _SectionTitle('Historique des détections'),
            const SizedBox(height: 8),
            _InfoCard(
              children: [
                _InfoRow(
                  icon: Icons.repeat_rounded,
                  label: 'Cette anomalie a été observée ${anomaly.seenCount} fois au total.',
                  accent: accent,
                ),
                const _Separator(),
                _InfoRow(
                  icon: Icons.first_page_rounded,
                  label: 'Première détection : ${_relativeDay(firstSeen)}',
                  accent: accent,
                ),
                const _Separator(),
                _InfoRow(
                  icon: Icons.update_rounded,
                  label: 'Détection la plus récente : ${_relativeDay(notifTime)}',
                  accent: accent,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String severityLabel;
  final String title;

  const _HeroCard({
    required this.icon,
    required this.accent,
    required this.severityLabel,
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
          Row(
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
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  severityLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
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
          color: AppTheme.textSecondary,
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
        color: AppTheme.darkBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.12),
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
                color: AppTheme.textPrimary,
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
      color: AppTheme.textSecondary.withValues(alpha: 0.08),
      indent: 16,
      endIndent: 16,
    );
  }
}

IconData _iconForActivity(String activityKey) {
  return switch (activityKey) {
    'sleep'           => Icons.bedtime_rounded,
    'petit-déjeuner'  => Icons.free_breakfast_rounded,
    'déjeuner'        => Icons.lunch_dining_rounded,
    'souper'          => Icons.dinner_dining_rounded,
    'outside'         => Icons.directions_walk_rounded,
    _                 => Icons.home_rounded,
  };
}

String _prettyActivityLabel(String activityKey) {
  return switch (activityKey) {
    'sleep'          => 'le sommeil',
    'petit-déjeuner' => 'le petit-déjeuner',
    'déjeuner'       => 'le déjeuner',
    'souper'         => 'le souper',
    'outside'        => 'la sortie',
    _                => "l'activité",
  };
}

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

List<String> _extractMetrics(String rawMessage) {
  final result = <String>[];
  if (rawMessage.isEmpty) return result;
  final paren = RegExp(r'\(([^)]+)\)').firstMatch(rawMessage)?.group(1)?.trim();
  final source = (paren != null && paren.isNotEmpty) ? paren : rawMessage;

  final ratioVs = RegExp(
    r'ratio\s*[:=]\s*([\d.]+)\s*vs\s*normal\s*[:=]\s*([\d.]+)',
    caseSensitive: false,
  ).firstMatch(source);
  if (ratioVs != null) {
    final ratio = double.tryParse(ratioVs.group(1)!);
    final normal = double.tryParse(ratioVs.group(2)!);
    if (ratio != null && normal != null && normal > 0) {
      final pct = ((ratio - normal) / normal * 100).round();
      final sign = pct >= 0 ? '+' : '';
      result.add('$sign$pct % par rapport à la moyenne');
    }
    result.add('Ratio mesuré : ${ratioVs.group(1)} (valeur normale : ${ratioVs.group(2)})');
  } else {
    final ratio =
        RegExp(r'ratio\s*[:=]\s*([\d.]+)', caseSensitive: false).firstMatch(source);
    if (ratio != null) {
      result.add('Ratio mesuré : ${ratio.group(1)}×');
    }
  }

  final similarity = RegExp(
    r'similarit[eé]\s*[:=]\s*([\d.]+)',
    caseSensitive: false,
  ).firstMatch(source);
  if (similarity != null) {
    final value = double.tryParse(similarity.group(1)!);
    if (value != null) {
      final pct = (value <= 1 ? value * 100 : value).round();
      result.add('Ressemblance avec la routine : $pct %');
    }
  }

  final score =
      RegExp(r'score\s*[:=]\s*([\d.]+)', caseSensitive: false).firstMatch(source);
  if (score != null) {
    result.add('Score d\'écart : ${score.group(1)}');
  }

  return result;
}

String _explanationByType(String type) {
  return switch (type.toLowerCase()) {
    'missing' =>
      "Cette activité fait normalement partie de la routine quotidienne, "
          "mais elle n'a pas été détectée aujourd'hui.",
    'timing' =>
      "L'activité s'est déroulée à un horaire inhabituel par rapport "
          "aux jours précédents.",
    'duration_short' =>
      "L'activité a duré nettement moins longtemps que ce que la routine "
          "habituelle laisse attendre.",
    'duration_long' =>
      "L'activité a duré nettement plus longtemps que ce que la routine "
          "habituelle laisse attendre.",
    'freq_high' =>
      "Cette activité est revenue plus souvent qu'à l'ordinaire au cours "
          "de la journée.",
    'freq_low' =>
      "Cette activité a eu lieu moins souvent que d'habitude. "
          "Son absence partielle a déclenché cette alerte.",
    _ => "Un écart significatif par rapport à la routine habituelle a été détecté.",
  };
}

String _dayLabel(DateTime day) {
  final today = _todayFrance();
  final d = DateTime(day.year, day.month, day.day);
  if (_isSameDay(d, today)) return "Aujourd'hui";
  final yesterday = today.subtract(const Duration(days: 1));
  if (_isSameDay(d, yesterday)) return 'Hier';
  const weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
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

DateTime _todayFrance() {
  final n = _toFranceTime(DateTime.now().toUtc());
  return DateTime(n.year, n.month, n.day);
}

DateTime _toFranceTime(DateTime date) {
  final utc = date.toUtc();
  final isDst = _isFranceDst(utc);
  final offsetHours = isDst ? 2 : 1;
  return utc.add(Duration(hours: offsetHours));
}

bool _isFranceDst(DateTime utc) {
  final start = _lastSundayUtc(utc.year, 3).add(const Duration(hours: 1));
  final end = _lastSundayUtc(utc.year, 10).add(const Duration(hours: 1));
  return utc.isAfter(start) && utc.isBefore(end);
}

DateTime _lastSundayUtc(int year, int month) {
  final firstNextMonth = month == 12
      ? DateTime.utc(year + 1, 1, 1)
      : DateTime.utc(year, month + 1, 1);
  final lastDayOfMonth = firstNextMonth.subtract(const Duration(days: 1));
  return lastDayOfMonth.subtract(Duration(days: lastDayOfMonth.weekday % 7));
}
