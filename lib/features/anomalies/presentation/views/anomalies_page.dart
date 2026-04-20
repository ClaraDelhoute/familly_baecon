import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/providers/watched_person_provider.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';
import 'package:familly_baecon/features/anomalies/presentation/providers/anomaly_focus_provider.dart';
import 'package:familly_baecon/features/anomalies/presentation/views/anomaly_detail_page.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';

class AnomaliesPage extends ConsumerWidget {
  const AnomaliesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomaliesAsync = ref.watch(liveAnomaliesProvider);
    final focusedId = ref.watch(focusedAnomalyIdProvider);
    final anomalies = <AnomalyHistoryModel>[
      ...(anomaliesAsync.valueOrNull ?? const <AnomalyHistoryModel>[]),
    ];

    if (focusedId != null && anomalies.isNotEmpty) {
      final index = anomalies.indexWhere((item) => item.id == focusedId);
      if (index > 0) {
        final focused = anomalies.removeAt(index);
        anomalies.insert(0, focused);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomalies'),
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
      body: anomalies.isEmpty
          ? const _EmptyState()
          : _AnomaliesList(anomalies: anomalies, focusedId: focusedId),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.activityGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppTheme.activityGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tout va bien',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune anomalie détectée pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnomaliesList extends StatelessWidget {
  final List<AnomalyHistoryModel> anomalies;
  final int? focusedId;

  const _AnomaliesList({required this.anomalies, this.focusedId});

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(anomalies);
    final highToday = anomalies
        .where(
          (a) =>
              a.severity == 'high' &&
              _isSameDay(_toFranceTime(a.simulatedAt), _todayFrance()),
        )
        .length;
    final totalToday = anomalies
        .where(
          (a) => _isSameDay(_toFranceTime(a.simulatedAt), _todayFrance()),
        )
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _TodaySummary(total: totalToday, severe: highToday),
        const SizedBox(height: 18),
        for (final entry in grouped.entries) ...[
          _DayHeader(day: entry.key),
          const SizedBox(height: 10),
          for (final anomaly in entry.value) ...[
            _AnomalyCard(
              anomaly: anomaly,
              highlighted: anomaly.id == focusedId,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Map<DateTime, List<AnomalyHistoryModel>> _groupByDay(
    List<AnomalyHistoryModel> items,
  ) {
    final map = <DateTime, List<AnomalyHistoryModel>>{};
    for (final item in items) {
      final local = _toFranceTime(item.simulatedAt);
      final day = DateTime(local.year, local.month, local.day);
      map.putIfAbsent(day, () => []).add(item);
    }
    return map;
  }
}

class _TodaySummary extends StatelessWidget {
  final int total;
  final int severe;

  const _TodaySummary({required this.total, required this.severe});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasAny = total > 0;
    final accent = severe > 0
        ? AppTheme.activityRed
        : (hasAny ? AppTheme.accentBlue : AppTheme.activityGreen);

    final title = severe > 0
        ? "À surveiller aujourd'hui"
        : (hasAny ? "Quelques écarts aujourd'hui" : 'Journée sans souci');
    final subtitle = severe > 0
        ? '$severe anomalie${severe > 1 ? 's' : ''} importante${severe > 1 ? 's' : ''} sur $total au total'
        : (hasAny
              ? '$total anomalie${total > 1 ? 's' : ''} légère${total > 1 ? 's' : ''} détectée${total > 1 ? 's' : ''}'
              : 'Aucune anomalie détectée ce jour');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkBgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              severe > 0
                  ? Icons.warning_amber_rounded
                  : (hasAny
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_rounded),
              color: accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.3,
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

class _DayHeader extends StatelessWidget {
  final DateTime day;
  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 4),
      child: Text(
        _dayLabel(day),
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _AnomalyCard extends ConsumerWidget {
  final AnomalyHistoryModel anomaly;
  final bool highlighted;

  const _AnomalyCard({required this.anomaly, this.highlighted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isHigh = anomaly.severity == 'high';
    final accent = isHigh ? AppTheme.activityRed : AppTheme.accentBlue;
    final activityIcon = _iconForActivity(anomaly.activityKey);
    final activityName = _prettyActivityLabel(anomaly.activityKey);
    final name = ref.watch(watchedPersonNameProvider);
    final anomalyNature = _shortAnomalyDescription(anomaly, name);
    final when = _activityWhenLabel(anomaly);

    return Material(
      color: AppTheme.darkBgLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnomalyDetailPage(anomaly: anomaly),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted
                  ? accent.withValues(alpha: 0.6)
                  : AppTheme.textSecondary.withValues(alpha: 0.12),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(activityIcon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activityName,
                      style: (textTheme.titleLarge ??
                              const TextStyle(fontSize: 20))
                          .copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.15,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      anomalyNature,
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            when,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForActivity(String activityKey) {
  return switch (activityKey) {
    'sleep'          => Icons.bedtime_rounded,
    'petit-déjeuner' => Icons.free_breakfast_rounded,
    'déjeuner'       => Icons.lunch_dining_rounded,
    'souper'         => Icons.ramen_dining_rounded,
    'outside'        => Icons.directions_walk_rounded,
    _                => Icons.home_rounded,
  };
}

String _prettyActivityLabel(String activityKey) {
  return switch (activityKey) {
    'sleep'          => 'Sommeil',
    'petit-déjeuner' => 'Petit-déjeuner',
    'déjeuner'       => 'Déjeuner',
    'souper'         => 'Souper',
    'outside'        => 'Sortie',
    _                => activityKey,
  };
}

String _shortAnomalyDescription(AnomalyHistoryModel anomaly, String personName) {
  final who = personName.isNotEmpty ? personName : null;
  final type = anomaly.anomalyType;

  if (who != null) {
    return switch (anomaly.activityKey) {
      'sleep' => switch (type) {
        'missing'        => "$who n'a pas dormi cette nuit",
        'timing'         => "$who s'est couché(e) à un horaire inhabituel",
        'duration_short' => "$who a dormi moins longtemps que d'habitude",
        'duration_long'  => "$who a dormi plus longtemps que d'habitude",
        _                => "$who a eu un sommeil inhabituel",
      },
      'petit-déjeuner' => switch (type) {
        'missing'        => "$who n'a pas pris son petit-déjeuner",
        'timing'         => "$who a petit-déjeuné à un horaire inhabituel",
        'duration_short' => "$who a pris un petit-déjeuner plus rapide que d'habitude",
        'duration_long'  => "$who a pris un petit-déjeuner plus long que d'habitude",
        _                => "$who a eu un petit-déjeuner inhabituel",
      },
      'déjeuner' => switch (type) {
        'missing'        => "$who n'a pas déjeuné aujourd'hui",
        'timing'         => "$who a déjeuné à un horaire inhabituel",
        'duration_short' => "$who a déjeuné plus rapidement que d'habitude",
        'duration_long'  => "$who a déjeuné plus longuement que d'habitude",
        _                => "$who a eu un déjeuner inhabituel",
      },
      'souper' => switch (type) {
        'missing'        => "$who n'a pas soupé ce soir",
        'timing'         => "$who a soupé à un horaire inhabituel",
        'duration_short' => "$who a soupé plus rapidement que d'habitude",
        'duration_long'  => "$who a soupé plus longuement que d'habitude",
        _                => "$who a eu un souper inhabituel",
      },
      'outside' => switch (type) {
        'missing'        => "$who n'est pas sorti(e) aujourd'hui",
        'timing'         => "$who est sorti(e) à un horaire inhabituel",
        'duration_short' => "$who est resté(e) sorti(e) moins longtemps que d'habitude",
        'duration_long'  => "$who est resté(e) sorti(e) plus longtemps que d'habitude",
        'freq_high'      => "$who est sorti(e) plus souvent que d'habitude",
        'freq_low'       => "$who sort moins souvent que d'habitude",
        _                => "$who a eu une sortie inhabituelle",
      },
      _ => "Comportement inhabituel pour $who",
    };
  }

  return switch (type) {
    'missing'        => "N'a pas eu lieu aujourd'hui",
    'timing'         => "A eu lieu à un horaire inhabituel",
    'duration_short' => "A duré moins longtemps que prévu",
    'duration_long'  => "A duré plus longtemps que prévu",
    'freq_high'      => "S'est produit plus souvent que d'habitude",
    'freq_low'       => "S'est produit moins souvent que d'habitude",
    _                => "Comportement inhabituel détecté",
  };
}

String _whenLabel(DateTime local) {
  final today = _todayFrance();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (_isSameDay(local, today)) return "Aujourd'hui à ${hh}h$mm";
  final yesterday = today.subtract(const Duration(days: 1));
  if (_isSameDay(local, yesterday)) return 'Hier à ${hh}h$mm';
  return "${_dayLabel(local)} à ${hh}h$mm";
}

String _activityWhenLabel(AnomalyHistoryModel anomaly) {
  return _whenLabel(_toFranceTime(anomaly.simulatedAt));
}

String _dayLabel(DateTime day) {
  final today = _todayFrance();
  if (_isSameDay(day, today)) return "Aujourd'hui";
  final yesterday = today.subtract(const Duration(days: 1));
  if (_isSameDay(day, yesterday)) return 'Hier';
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
