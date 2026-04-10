import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/journal/presentation/widgets/timeline_schedule_view.dart';

class CalendarTimeline extends StatefulWidget {
  final List<Activity> expectedActivities;
  final List<Activity> observedActivities;
  final Function(Activity)? onActivityTap;
  final bool showExpectedColumn;
  final bool showObservedColumn;
  final String expectedColumnTitle;
  final String observedColumnTitle;
  final double? sharedVerticalOffset;
  final ValueChanged<double>? onVerticalOffsetChanged;

  const CalendarTimeline({
    super.key,
    required this.expectedActivities,
    required this.observedActivities,
    this.onActivityTap,
    this.showExpectedColumn = true,
    this.showObservedColumn = true,
    this.expectedColumnTitle = 'JOURNÉE TYPE',
    this.observedColumnTitle = 'JOURNÉE OBSERVÉE',
    this.sharedVerticalOffset,
    this.onVerticalOffsetChanged,
  });

  @override
  State<CalendarTimeline> createState() => _CalendarTimelineState();
}

class _CalendarTimelineState extends State<CalendarTimeline> {
  @override
  Widget build(BuildContext context) {
    return TimelineScheduleView(
      expectedActivities: widget.expectedActivities,
      observedActivities: widget.observedActivities,
      onActivityTap: widget.onActivityTap,
      showExpectedColumn: widget.showExpectedColumn,
      showObservedColumn: widget.showObservedColumn,
      expectedColumnTitle: widget.expectedColumnTitle,
      observedColumnTitle: widget.observedColumnTitle,
      sharedVerticalOffset: widget.sharedVerticalOffset,
      onVerticalOffsetChanged: widget.onVerticalOffsetChanged,
    );
  }
}

