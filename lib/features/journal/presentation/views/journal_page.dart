import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/journal/presentation/widgets/calendar_timeline.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/widgets/common_header.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';

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

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final observedAsync = ref.watch(liveObservedActivitiesProvider);
    final observed = observedAsync.when(
      data: (items) => items,
      loading: () => const <Activity>[],
      error: (error, stackTrace) => const <Activity>[],
    );
    final simulatedNow = _simulatedNowFromObserved(observed);
    final defaultDay = DateTime(simulatedNow.year, simulatedNow.month, simulatedNow.day);
    final selectedDay = _selectedDate ?? defaultDay;

    final observedForDay = _filterActivitiesByDay(observed, selectedDay);
    final expected = _buildTypeDayFromObserved(observedForDay);

    final dateFormatter = _formatFrenchDate(selectedDay);
    final currentWindow = _buildTwoHoursWindow(observedForDay, simulatedNow);
    final observedWindow = _filterWindow(observedForDay, currentWindow.$1, currentWindow.$2);

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
                          'Fenêtre lisible: ${_formatHm(currentWindow.$1)} - ${_formatHm(currentWindow.$2)}',
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
                            observedActivities: observedWindow,
                            showExpectedColumn: false,
                            observedColumnTitle: 'JOURNÉE OBSERVÉE',
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

  DateTime _simulatedNowFromObserved(List<Activity> observed) {
    if (observed.isEmpty) return DateTime.now();
    return observed
        .map((a) => a.endAt ?? a.startAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  (DateTime, DateTime) _buildTwoHoursWindow(List<Activity> observed, DateTime simulatedNow) {
    if (observed.isEmpty) {
      return (simulatedNow.subtract(const Duration(hours: 2)), simulatedNow);
    }
    final end = observed
        .map((a) => a.endAt ?? a.startAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return (end.subtract(const Duration(hours: 2)), end);
  }

  List<Activity> _filterActivitiesByDay(List<Activity> activities, DateTime day) {
    return activities.where((activity) {
      final d = activity.startAt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  List<Activity> _filterWindow(List<Activity> activities, DateTime start, DateTime end) {
    return activities.where((activity) {
      final activityStart = activity.startAt;
      final activityEnd = activity.endAt ?? activity.startAt;
      final overlaps = !activityEnd.isBefore(start) && !activityStart.isAfter(end);
      return overlaps;
    }).toList();
  }

  String _formatFrenchDate(DateTime date) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatHm(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<Activity> _buildTypeDayFromObserved(List<Activity> observed) {
    if (observed.isEmpty) return const <Activity>[];
    final byType = <String, List<Activity>>{};
    for (final activity in observed) {
      byType.putIfAbsent(activity.type, () => <Activity>[]).add(activity);
    }

    final merged = <Activity>[];
    for (final entry in byType.entries) {
      final items = entry.value..sort((a, b) => a.startAt.compareTo(b.startAt));
      final first = items.first;
      final latestEnd = items
          .map((a) => a.endAt ?? a.startAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      merged.add(
        first.copyWith(
          id: 'type_${first.type}',
          startAt: first.startAt,
          endAt: latestEnd,
          durationMin: latestEnd.difference(first.startAt).inMinutes,
        ),
      );
    }

    merged.sort((a, b) => a.startAt.compareTo(b.startAt));
    return merged;
  }
}

