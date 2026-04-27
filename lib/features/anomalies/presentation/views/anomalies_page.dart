import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/domain/activity_type.dart';
import 'package:familly_baecon/core/domain/anomaly_type.dart';
import 'package:familly_baecon/core/providers/watched_person_provider.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';
import 'package:familly_baecon/features/anomalies/presentation/providers/anomaly_focus_provider.dart';
import 'package:familly_baecon/features/anomalies/presentation/providers/anomaly_read_provider.dart';
import 'package:familly_baecon/features/anomalies/presentation/views/anomaly_detail_page.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

class AnomaliesPage extends ConsumerWidget {
  const AnomaliesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomaliesAsync = ref.watch(liveAnomaliesProvider);
    final focusedId = ref.watch(focusedAnomalyIdProvider);
    final readIds = ref.watch(anomalyReadProvider);
    final anomalies = <AnomalyHistoryModel>[
      ...(anomaliesAsync.valueOrNull ?? const <AnomalyHistoryModel>[]),
    ]..sort((a, b) => b.simulatedAt.compareTo(a.simulatedAt));

    final hasUnread = anomalies.any((a) => !readIds.contains(a.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomalies'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () {
                ref
                    .read(anomalyReadProvider.notifier)
                    .markAllRead(anomalies.map((a) => a.id).toList());
              },
              child: const Text('Tout marquer lu'),
            ),
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
          : _AnomaliesList(
              anomalies: anomalies,
              focusedId: focusedId,
              readIds: readIds,
            ),
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
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune anomalie détectée pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.palette.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnomaliesList extends ConsumerStatefulWidget {
  final List<AnomalyHistoryModel> anomalies;
  final int? focusedId;
  final Set<int> readIds;

  const _AnomaliesList({
    required this.anomalies,
    required this.readIds,
    this.focusedId,
  });

  @override
  ConsumerState<_AnomaliesList> createState() => _AnomaliesListState();
}

class _AnomaliesListState extends ConsumerState<_AnomaliesList> {
  @override
  void initState() {
    super.initState();
    if (widget.focusedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(focusedAnomalyIdProvider.notifier).state = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final anomalies = widget.anomalies;
    final focusedId = widget.focusedId;
    final readIds = widget.readIds;
    final grouped = _groupByDay(anomalies);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final entry in grouped.entries) ...[
          _DayHeader(
            day: entry.key,
            unreadCount: entry.value.where((a) => !readIds.contains(a.id)).length,
          ),
          const SizedBox(height: 10),
          for (final anomaly in entry.value) ...[
            _AnomalyCard(
              anomaly: anomaly,
              highlighted: anomaly.id == focusedId,
              isRead: readIds.contains(anomaly.id),
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
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final key in sortedKeys) key: map[key]!};
  }
}

// ── Day header ────────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final int unreadCount;
  const _DayHeader({required this.day, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 4),
      child: Row(
        children: [
          Text(
            _dayLabel(day),
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 6),
            Text(
              '— $unreadCount non ${unreadCount > 1 ? 'lues' : 'lue'}',
              style: TextStyle(
                color: AppTheme.activityRed,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Anomaly card ──────────────────────────────────────────────────────────────

class _AnomalyCard extends ConsumerWidget {
  final AnomalyHistoryModel anomaly;
  final bool highlighted;
  final bool isRead;

  const _AnomalyCard({
    required this.anomaly,
    required this.isRead,
    this.highlighted = false,
  });

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

    final cardColor = context.palette.surface;
    final borderColor = highlighted
        ? accent.withValues(alpha: 0.6)
        : context.palette.textSecondary.withValues(alpha: 0.12);
    final borderWidth = highlighted ? 2.0 : 1.0;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ref.read(anomalyReadProvider.notifier).markRead(anomaly.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnomalyDetailPage(anomaly: anomaly),
            ),
          );
        },
        child: SizedBox(
          height: 88,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: borderWidth),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        activityName,
                        style: (textTheme.titleLarge ??
                                const TextStyle(fontSize: 20))
                            .copyWith(
                              fontWeight: isRead ? FontWeight.w400 : FontWeight.w800,
                              color: isRead ? context.palette.textSecondary : context.palette.textPrimary,
                              height: 1.15,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        anomalyNature,
                        style: TextStyle(
                          color: isRead ? context.palette.textSecondary : context.palette.textPrimary,
                          fontSize: 13,
                          fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: context.palette.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              when,
                              style: TextStyle(
                                color: context.palette.textSecondary,
                                fontSize: 12,
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
                  color: context.palette.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

IconData _iconForActivity(String activityKey) =>
    ActivityType.fromKey(activityKey).icon;

String _prettyActivityLabel(String activityKey) =>
    ActivityType.fromKey(activityKey).label;

String _shortAnomalyDescription(AnomalyHistoryModel anomaly, String _) =>
    AnomalyType.fromKey(anomaly.anomalyType).shortDescription;

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

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _todayFrance() {
  final n = _toFranceTime(DateTime.now().toUtc());
  return DateTime(n.year, n.month, n.day);
}

DateTime _toFranceTime(DateTime date) {
  final utc = date.toUtc();
  final isDst = _isFranceDst(utc);
  return utc.add(Duration(hours: isDst ? 2 : 1));
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
