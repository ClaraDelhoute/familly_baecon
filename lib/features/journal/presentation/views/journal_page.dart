import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/journal/data/models/routine_activity_model.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/journal/presentation/widgets/calendar_timeline.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';

class JournalPage extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const JournalPage({super.key, this.onNavigate});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  DateTime? _selectedDate;
  DatePickerMode? _calendarMode;
  double? _sharedTimelineScrollOffset;

  @override
  Widget build(BuildContext context) {
    final observedAsync = ref.watch(liveObservedActivitiesProvider);
    final observed = observedAsync.when(
      data: (items) => items,
      loading: () => const <Activity>[],
      error: (_, __) => const <Activity>[],
    );
    final observedLocal = observed.map(_toLocalActivity).toList();
    final defaultDay = _defaultObservedDay(observedLocal);
    final selectedDay = _selectedDate ?? defaultDay;
    final selectedDayLabel = _formatDateShort(selectedDay);
    final observedForDay = _filterActivitiesByDay(observedLocal, selectedDay);
    final titleDateFormatter = _formatFrenchDateLong(selectedDay);
    final titleCapitalized = titleDateFormatter.isEmpty
        ? ''
        : '${titleDateFormatter[0].toUpperCase()}${titleDateFormatter.substring(1)}';

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.0,
          child: Text(
            titleCapitalized,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Afficher la vue mois',
            icon: const Icon(Icons.calendar_month, color: AppTheme.accentBlue),
            onPressed: () {
              setState(() {
                _calendarMode = _calendarMode == DatePickerMode.day
                    ? null
                    : DatePickerMode.day;
              });
            },
          ),
          IconButton(
            tooltip: 'Afficher la vue annee',
            icon: const Icon(Icons.calendar_today, color: AppTheme.accentBlue),
            onPressed: () {
              setState(() {
                _calendarMode = _calendarMode == DatePickerMode.year
                    ? null
                    : DatePickerMode.year;
              });
            },
          ),
          IconButton(
            tooltip: 'Parametres',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            if (_calendarMode != null)
              Container(
                margin: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.darkBgLight.withValues(alpha: 0.55),
                  border: Border.all(
                    color: const Color(0xFFBFC7D1),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _calendarMode == DatePickerMode.day
                    ? CalendarDatePicker(
                        initialDate: selectedDay,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        currentDate: DateTime.now(),
                        onDateChanged: (picked) {
                          setState(() {
                            _selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                            _calendarMode = null;
                          });
                        },
                      )
                    : SizedBox(
                        height: 220,
                        child: YearPicker(
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          selectedDate: selectedDay,
                          currentDate: DateTime.now(),
                          onChanged: (picked) {
                            setState(() {
                              _selectedDate = DateTime(
                                picked.year,
                                selectedDay.month,
                                selectedDay.day,
                              );
                              _calendarMode = DatePickerMode.day;
                            });
                          },
                        ),
                      ),
              ),
            Container(
              color: AppTheme.darkBgLight.withValues(alpha: 0.45),
              child: TabBar(
                tabs: [
                  Tab(text: selectedDayLabel),
                  const Tab(text: 'Journee type'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  CalendarTimeline(
                    expectedActivities: const <Activity>[],
                    observedActivities: observedForDay,
                    showExpectedColumn: false,
                    observedColumnTitle: '',
                    sharedVerticalOffset: _sharedTimelineScrollOffset,
                    onVerticalOffsetChanged: (offset) {
                      _sharedTimelineScrollOffset = offset;
                    },
                  ),
                  _RoutineTab(
                    selectedDay: selectedDay,
                    sharedVerticalOffset: _sharedTimelineScrollOffset,
                    onVerticalOffsetChanged: (offset) {
                      _sharedTimelineScrollOffset = offset;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _defaultObservedDay(List<Activity> observed) {
    if (observed.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final latest = observed
        .map((a) => (a.endAt ?? a.startAt).toLocal())
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime(latest.year, latest.month, latest.day);
  }

  List<Activity> _filterActivitiesByDay(
    List<Activity> activities,
    DateTime day,
  ) {
    final dayLocal = day.toLocal();
    return activities.where((activity) {
      final d = activity.startAt.toLocal();
      return d.year == dayLocal.year &&
          d.month == dayLocal.month &&
          d.day == dayLocal.day;
    }).toList();
  }

  String _formatFrenchDateLong(DateTime date) {
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
      'fevrier',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'aout',
      'septembre',
      'octobre',
      'novembre',
      'decembre',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday ${date.day} $month ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  Activity _toLocalActivity(Activity activity) {
    final startLocal = activity.startAt.toLocal();
    final endLocal = activity.endAt?.toLocal();
    return activity.copyWith(startAt: startLocal, endAt: endLocal);
  }
}

class _RoutineTab extends ConsumerWidget {
  final DateTime selectedDay;
  final double? sharedVerticalOffset;
  final ValueChanged<double>? onVerticalOffsetChanged;

  const _RoutineTab({
    required this.selectedDay,
    this.sharedVerticalOffset,
    this.onVerticalOffsetChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(liveRoutineProvider);

    return routineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Impossible de charger la routine.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      data: (items) {
        final routineItems = items
            .where((r) => r.isActivityProfile && r.frequency > 0)
            .toList()
          ..sort((a, b) => (a.startMin ?? 0).compareTo(b.startMin ?? 0));

        if (routineItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 48,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La journee type sera construite automatiquement\npar le systeme a partir des donnees observees.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final expectedActivities = routineItems
            .map((activity) => _toExpectedActivity(activity, selectedDay))
            .toList();

        return CalendarTimeline(
          expectedActivities: expectedActivities,
          observedActivities: const <Activity>[],
          showObservedColumn: false,
          expectedColumnTitle: 'JOURNEE TYPE',
          sharedVerticalOffset: sharedVerticalOffset,
          onVerticalOffsetChanged: onVerticalOffsetChanged,
        );
      },
    );
  }

  Activity _toExpectedActivity(RoutineActivityModel activity, DateTime day) {
    final startMinute = ((activity.startMin ?? 0).round().clamp(0, 1439)) as int;
    final duration = ((activity.durationMin ?? 60).round().clamp(1, 1440)) as int;
    final baseDay = DateTime(day.year, day.month, day.day);
    final startAt = baseDay.add(Duration(minutes: startMinute));
    final endAt = startAt.add(Duration(minutes: duration));

    return Activity(
      id: 'routine-${activity.sensorType}-${activity.room}-$startMinute',
      deviceId: 'routine',
      type: activity.room,
      room: activity.room,
      startAt: startAt,
      endAt: endAt,
      durationMin: duration,
      confidence: activity.frequency,
      metadata: <String, dynamic>{
        'sensorType': activity.sensorType,
        'sampleCount': activity.sampleCount,
      },
    );
  }
}
