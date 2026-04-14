import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/journal/presentation/providers/journal_providers.dart';
import 'package:familly_baecon/features/journal/presentation/widgets/calendar_timeline.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
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
    final ref = this.ref;
    final observedAsync = ref.watch(liveObservedActivitiesProvider);
    final observed = observedAsync.when(
      data: (items) => items,
      loading: () => const <Activity>[],
      error: (error, stackTrace) => const <Activity>[],
    );
    final observedLocal = observed.map(_toLocalActivity).toList();
    final defaultDay = _defaultObservedDay(observedLocal);
    final selectedDay = _selectedDate ?? defaultDay;

    final observedForDay = _filterActivitiesByDay(observedLocal, selectedDay);
    final expectedTemplate = ref.watch(expectedActivitiesProvider);
    final expected = _rebaseExpectedToDay(expectedTemplate, selectedDay);
    final titleDateFormatter = _formatFrenchDateLong(selectedDay);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('Activités - $titleDateFormatter'),
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
            tooltip: 'Afficher la vue année',
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
            tooltip: 'Paramètres',
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
              child: const TabBar(
                tabs: [
                  Tab(text: 'Journée en cours'),
                  Tab(text: 'Journée type'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: AppTheme.darkBgLight.withValues(alpha: 0.35),
                        child: Text(
                          'Activités observées de la journée',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CalendarTimeline(
                          expectedActivities: const <Activity>[],
                          observedActivities: observedForDay,
                          showExpectedColumn: false,
                          observedColumnTitle: 'JOURNÉE OBSERVÉE',
                          sharedVerticalOffset: _sharedTimelineScrollOffset,
                          onVerticalOffsetChanged: (offset) {
                            _sharedTimelineScrollOffset = offset;
                          },
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: AppTheme.darkBgLight.withValues(alpha: 0.35),
                        child: Text(
                          'Routine théorique complète',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CalendarTimeline(
                          expectedActivities: expected,
                          observedActivities: const <Activity>[],
                          showObservedColumn: false,
                          expectedColumnTitle: 'JOURNÉE TYPE',
                          sharedVerticalOffset: _sharedTimelineScrollOffset,
                          onVerticalOffsetChanged: (offset) {
                            _sharedTimelineScrollOffset = offset;
                          },
                        ),
                      ),
                    ],
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
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday ${date.day} $month ${date.year}';
  }

  Activity _toLocalActivity(Activity activity) {
    final startLocal = activity.startAt.toLocal();
    final endLocal = activity.endAt?.toLocal();
    return activity.copyWith(startAt: startLocal, endAt: endLocal);
  }

  List<Activity> _rebaseExpectedToDay(List<Activity> template, DateTime day) {
    return template.map((activity) {
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        activity.startAt.hour,
        activity.startAt.minute,
        activity.startAt.second,
      );
      final end = activity.durationMin != null
          ? start.add(Duration(minutes: activity.durationMin!))
          : activity.endAt == null
          ? null
          : DateTime(
              day.year,
              day.month,
              day.day,
              activity.endAt!.hour,
              activity.endAt!.minute,
              activity.endAt!.second,
            );
      return activity.copyWith(startAt: start, endAt: end);
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
}
