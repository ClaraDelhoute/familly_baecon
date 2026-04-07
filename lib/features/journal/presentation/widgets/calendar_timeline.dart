import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/journal/presentation/widgets/timeline_schedule_view.dart';

class CalendarTimeline extends StatefulWidget {
  final List<Activity> expectedActivities;
  final List<Activity> observedActivities;
  final Function(Activity)? onActivityTap;

  const CalendarTimeline({
    super.key,
    required this.expectedActivities,
    required this.observedActivities,
    this.onActivityTap,
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
    );
  }
}

