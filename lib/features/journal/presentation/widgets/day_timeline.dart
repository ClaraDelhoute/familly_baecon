import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

class DayTimeline extends StatelessWidget {
  final List<Activity> expectedActivities;
  final List<Activity> observedActivities;
  final Function(Activity)? onActivityTap;

  const DayTimeline({
    super.key,
    required this.expectedActivities,
    required this.observedActivities,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // En-tête des colonnes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'JOURNÉE TYPE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '28 JAN. - OBSERVÉ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCyan,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          // Corps des activités avec timeline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne gauche : Journée type
                Expanded(
                  child: _ActivityTimelineColumn(
                    activities: expectedActivities,
                    onActivityTap: onActivityTap,
                    isObserved: false,
                  ),
                ),
                const SizedBox(width: 8),
                // Colonne droite : Journée détectée
                Expanded(
                  child: _ActivityTimelineColumn(
                    activities: observedActivities,
                    onActivityTap: onActivityTap,
                    isObserved: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActivityTimelineColumn extends StatelessWidget {
  final List<Activity> activities;
  final Function(Activity)? onActivityTap;
  final bool isObserved;

  const _ActivityTimelineColumn({
    required this.activities,
    this.onActivityTap,
    required this.isObserved,
  });

  Color _getActivityColor(Activity activity) {
    if (!isObserved) {
      return AppTheme.activityGreen;
    }
    // Logique couleur pour observé
    if (activity.type.toLowerCase().contains('sleep')) {
      return AppTheme.activityGreen;
    }
    if (activity.type.toLowerCase().contains('toilettes')) {
      return AppTheme.accentBlue;
    }
    if (activity.type.toLowerCase().contains('television')) {
      return AppTheme.accentCyan;
    }
    return AppTheme.activityOrange;
  }

  String _getActivityLabel(Activity activity) {
    final room = activity.room ?? activity.type;
    return room.split(' ').first.toUpperCase();
  }

  String _getTimeRange(Activity activity) {
    final start = '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')}';
    final end = activity.endAt != null
        ? '${activity.endAt!.hour.toString().padLeft(2, '0')}:${activity.endAt!.minute.toString().padLeft(2, '0')}'
        : '--:--';
    return '$start\n$end';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        final color = _getActivityColor(activity);
        final label = _getActivityLabel(activity);
        final timeRange = _getTimeRange(activity);
        final isLast = index == activities.length - 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => onActivityTap?.call(activity),
              child: Opacity(
                opacity: isObserved ? 1.0 : 0.45,  // Encore plus grisé (0.45 au lieu de 0.5)
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBgLight,
                    border: Border(
                      left: BorderSide(
                        color: isObserved ? color : Colors.grey.shade600,
                        width: 4,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isObserved
                              ? color.withValues(alpha: 0.2)
                              : Colors.grey.shade600.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isObserved ? color : Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeRange,
                        style: TextStyle(
                          fontSize: 10,
                          color: isObserved
                              ? AppTheme.textSecondary
                              : Colors.grey.shade500,
                          height: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.room ?? activity.type,
                        style: TextStyle(
                          fontSize: 10,
                          color: isObserved
                              ? AppTheme.textSecondary
                              : Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Divider(
                  color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  height: 8,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}


