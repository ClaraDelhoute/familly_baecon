import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/journal/presentation/providers/journal_providers.dart';
import 'package:familly_baecon/features/journal/presentation/widgets/calendar_timeline.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/widgets/common_header.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';

class JournalPage extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const JournalPage({
    super.key,
    this.onNavigate,
  });

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
    final anomaliesAsync = ref.watch(liveAnomaliesProvider);
    final observed = observedAsync.when(
      data: (items) => items,
      loading: () => const <Activity>[],
      error: (error, stackTrace) => const <Activity>[],
    );
    final observedLocal = observed.map(_toLocalActivity).toList();
    final anomalies = anomaliesAsync.when(
      data: (items) => items,
      loading: () => const <AnomalyHistoryModel>[],
      error: (error, stackTrace) => const <AnomalyHistoryModel>[],
    );
    final simulatedNow = _simulatedNow(observedLocal, anomalies);
    final defaultDay = DateTime(simulatedNow.year, simulatedNow.month, simulatedNow.day);
    final selectedDay = _selectedDate ?? defaultDay;

    final observedForDay = _filterActivitiesByDay(observedLocal, selectedDay);
    final expectedTemplate = ref.watch(expectedActivitiesProvider);
    final expected = _rebaseExpectedToDay(expectedTemplate, selectedDay);

    final dateFormatter = _formatFrenchDate(selectedDay);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            CommonHeader(
              title: 'Journal',
              subtitle: dateFormatter,
              actionWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Afficher la vue mois',
                    icon: Icon(
                      Icons.calendar_month,
                      color: _calendarMode == DatePickerMode.day ? Colors.white : Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _calendarMode =
                            _calendarMode == DatePickerMode.day ? null : DatePickerMode.day;
                      });
                    },
                  ),
                  IconButton(
                    tooltip: 'Afficher la vue année',
                    icon: Icon(
                      Icons.calendar_today,
                      color: _calendarMode == DatePickerMode.year ? Colors.white : Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _calendarMode =
                            _calendarMode == DatePickerMode.year ? null : DatePickerMode.year;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_calendarMode != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.darkBgLight.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _calendarMode == DatePickerMode.day
                    ? CalendarDatePicker(
                        initialDate: selectedDay,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        currentDate: defaultDay,
                        onDateChanged: (picked) {
                          setState(() {
                            _selectedDate = DateTime(picked.year, picked.month, picked.day);
                          });
                        },
                      )
                    : SizedBox(
                        height: 220,
                        child: YearPicker(
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          selectedDate: selectedDay,
                          currentDate: defaultDay,
                          onChanged: (picked) {
                            setState(() {
                              _selectedDate =
                                  DateTime(picked.year, selectedDay.month, selectedDay.day);
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      const SizedBox(height: 4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      const SizedBox(height: 4),
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

  DateTime _simulatedNow(List<Activity> observed, List<AnomalyHistoryModel> anomalies) {
    if (observed.isNotEmpty) {
      return observed
          .map((a) => (a.endAt ?? a.startAt).toLocal())
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    if (anomalies.isNotEmpty) {
      return anomalies
          .map((a) => a.simulatedAt.toLocal())
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    return DateTime.now();
  }

  List<Activity> _filterActivitiesByDay(List<Activity> activities, DateTime day) {
    final dayLocal = day.toLocal();
    return activities.where((activity) {
      final d = activity.startAt.toLocal();
      return d.year == dayLocal.year && d.month == dayLocal.month && d.day == dayLocal.day;
    }).toList();
  }

  String _formatFrenchDate(DateTime date) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Activity _toLocalActivity(Activity activity) {
    final startLocal = activity.startAt.toLocal();
    final endLocal = activity.endAt?.toLocal();
    return activity.copyWith(
      startAt: startLocal,
      endAt: endLocal,
    );
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
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
}

