import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

class CalendarGridView extends StatefulWidget {
  final List<Activity> expectedActivities;
  final List<Activity> observedActivities;
  final Function(Activity)? onActivityTap;

  const CalendarGridView({
    super.key,
    required this.expectedActivities,
    required this.observedActivities,
    this.onActivityTap,
  });

  @override
  State<CalendarGridView> createState() => _CalendarGridViewState();
}

class _CalendarGridViewState extends State<CalendarGridView> {
  Color _getActivityColor(Activity activity) {
    if (activity.type.toLowerCase().contains('sleep')) {
      return AppTheme.activityGreen;
    }
    if (activity.type.toLowerCase().contains('toilettes')) {
      return AppTheme.accentBlue;
    }
    if (activity.type.toLowerCase().contains('television')) {
      return AppTheme.accentCyan;
    }
    if (activity.type.toLowerCase().contains('ordinateur')) {
      return Color(0xFFBB86FC);
    }
    return AppTheme.activityOrange;
  }

  String _getActivityLabel(Activity activity) {
    final label = activity.room ?? activity.type;
    return label.length > 15 ? '${label.substring(0, 12)}...' : label;
  }

  double _getHeightFromDuration(int? minutes) {
    if (minutes == null || minutes == 0) return 50;
    // Plus compact : 0.8px par minute (au lieu de 1px)
    return (minutes * 0.8).clamp(20.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Colonne heures (gauche - fixe)
        Container(
          width: 50,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: AppTheme.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: List.generate(24, (hour) {
              return SizedBox(
                height: 50, // Même hauteur que les activités
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Colonnes activités
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // En-tête
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'JOURNÉE TYPE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '28 JAN. - OBSERVÉ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentCyan,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  height: 1,
                ),
                // Grille
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCalendarColumn(
                        widget.expectedActivities,
                        isObserved: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCalendarColumn(
                        widget.observedActivities,
                        isObserved: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarColumn(List<Activity> activities, {required bool isObserved}) {
    return Stack(
      children: [
        // Grille horaire (background)
        Column(
          children: List.generate(24, (hour) {
            final isEvenHour = hour % 2 == 0;
            return Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.textSecondary.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                color: isEvenHour
                    ? Colors.transparent
                    : AppTheme.darkBg.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
        // Activités
        Column(
          children: List.generate(24, (hour) {
            final hourActivities = activities
                .where((a) => a.startAt.hour == hour)
                .toList();

            return SizedBox(
              height: 50,
              child: Stack(
                children: hourActivities.map((activity) {
                  final height = _getHeightFromDuration(activity.durationMin);
                  final color = _getActivityColor(activity);
                  final label = _getActivityLabel(activity);

                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => widget.onActivityTap?.call(activity),
                      child: Container(
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25),
                          border: Border.all(
                            color: color,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (height > 28)
                              Text(
                                '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            if (height > 35 && activity.durationMin != null)
                              Text(
                                '${activity.durationMin}min',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ),
      ],
    );
  }
}

