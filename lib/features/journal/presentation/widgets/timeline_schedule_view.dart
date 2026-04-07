import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

class TimelineScheduleView extends StatefulWidget {
  final List<Activity> expectedActivities;
  final List<Activity> observedActivities;
  final Function(Activity)? onActivityTap;

  const TimelineScheduleView({
    super.key,
    required this.expectedActivities,
    required this.observedActivities,
    this.onActivityTap,
  });

  @override
  State<TimelineScheduleView> createState() => _TimelineScheduleViewState();
}

class _TimelineScheduleViewState extends State<TimelineScheduleView> {
  // Journée type hardcodée avec heures exactes
  static const List<Map<String, dynamic>> journeeType = [
    // Matin
    {'startHour': 8, 'startMin': 0, 'endHour': 8, 'endMin': 40, 'label': 'Temps libre / réveil', 'icon': ''},
    {'startHour': 8, 'startMin': 40, 'endHour': 8, 'endMin': 55, 'label': 'Douche', 'icon': '🚿'},
    {'startHour': 9, 'startMin': 10, 'endHour': 9, 'endMin': 30, 'label': 'Petit-déjeuner', 'icon': '🍳'},
    {'startHour': 9, 'startMin': 55, 'endHour': 11, 'endMin': 30, 'label': 'Sortie / déplacement', 'icon': '🚗'},
    // Midi
    {'startHour': 11, 'startMin': 30, 'endHour': 12, 'endMin': 36, 'label': 'Temps libre / activité', 'icon': ''},
    {'startHour': 12, 'startMin': 36, 'endHour': 13, 'endMin': 10, 'label': 'Déjeuner', 'icon': '🍽️'},
    // Après-midi
    {'startHour': 13, 'startMin': 10, 'endHour': 16, 'endMin': 45, 'label': 'Temps libre / activité', 'icon': ''},
    {'startHour': 16, 'startMin': 45, 'endHour': 18, 'endMin': 15, 'label': 'Sortie / déplacement', 'icon': '🚗'},
    // Soir
    {'startHour': 18, 'startMin': 15, 'endHour': 19, 'endMin': 30, 'label': 'Temps libre', 'icon': ''},
    {'startHour': 19, 'startMin': 30, 'endHour': 20, 'endMin': 12, 'label': 'Dîner', 'icon': '🍽️'},
    {'startHour': 20, 'startMin': 12, 'endHour': 21, 'endMin': 20, 'label': 'Temps libre', 'icon': ''},
    // Nuit
    {'startHour': 21, 'startMin': 20, 'endHour': 8, 'endMin': 30, 'label': 'Sommeil', 'icon': '😴'},
  ];

  // Constantes pour la timeline
  static const double pixelsPerMinute = 1.0;
  static const double hourHeight = 100.0;
  static const double timeColumnWidth = 60.0;

  Color _getActivityColor(String label) {
    if (label.toLowerCase().contains('sommeil') || label.toLowerCase().contains('sleep')) {
      return AppTheme.activityGreen;
    }
    if (label.toLowerCase().contains('douche') || label.toLowerCase().contains('toilettes')) {
      return AppTheme.accentBlue;
    }
    if (label.toLowerCase().contains('déjeuner') || label.toLowerCase().contains('petit-déjeuner') || label.toLowerCase().contains('dîner')) {
      return AppTheme.activityOrange;
    }
    if (label.toLowerCase().contains('sortie') || label.toLowerCase().contains('déplacement')) {
      return Color(0xFF6200EE);
    }
    return AppTheme.textSecondary;
  }

  int _getMinutesFromMidnight(int hour, int minute) {
    return hour * 60 + minute;
  }

  double _getTopPosition(int hour, int minute) {
    return _getMinutesFromMidnight(hour, minute) * pixelsPerMinute;
  }

  double _getHeight(int startHour, int startMin, int endHour, int endMin) {
    int startTotal = _getMinutesFromMidnight(startHour, startMin);
    int endTotal = _getMinutesFromMidnight(endHour, endMin);

    // Gérer le cas où l'activité traverse minuit
    if (endTotal < startTotal) {
      endTotal += 24 * 60;
    }

    return (endTotal - startTotal) * pixelsPerMinute;
  }

  // --- Matching Observé vs Journée type ---

  String _categoryFromLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('sommeil') || l.contains('sleep')) return 'sleep';
    if (l.contains('douche') || l.contains('toilet')) return 'hygiene';
    if (l.contains('petit-déjeuner') || l.contains('déjeuner') || l.contains('dîner') || l.contains('repas')) return 'meal';
    if (l.contains('sortie') || l.contains('déplacement')) return 'out';
    return 'other';
  }

  String _categoryFromObserved(Activity activity) {
    final t = activity.type.toLowerCase();
    final r = (activity.room ?? '').toLowerCase();

    if (t.contains('sleep') || r.contains('chambre') || r.contains('lit')) return 'sleep';
    if (t.contains('toilettes') || t.contains('douche') || r.contains('salle de bain') || r.contains('toilet')) return 'hygiene';
    if (t.contains('cuisine') || t.contains('repas') || t.contains('meal') || r.contains('cuisine') || r.contains('salle à manger')) return 'meal';
    if (t.contains('sortie') || t.contains('outside') || t.contains('déplacement') || r.contains('extérieur')) return 'out';

    return 'other';
  }

  int _observedEndMinutes(Activity activity, int startMinutes) {
    if (activity.endAt != null) {
      return _getMinutesFromMidnight(activity.endAt!.hour, activity.endAt!.minute);
    }
    if (activity.durationMin != null && activity.durationMin! > 0) {
      return startMinutes + activity.durationMin!;
    }
    return startMinutes + 60;
  }

  bool _matchesJourneeType(Activity observed) {
    if (journeeType.isEmpty) return false;

    final oStart = _getMinutesFromMidnight(observed.startAt.hour, observed.startAt.minute);
    var oEnd = _observedEndMinutes(observed, oStart);
    if (oEnd < oStart) oEnd += 24 * 60;

    final oCat = _categoryFromObserved(observed);

    for (final slot in journeeType) {
      final eStart = _getMinutesFromMidnight(slot['startHour'] as int, slot['startMin'] as int);
      var eEnd = _getMinutesFromMidnight(slot['endHour'] as int, slot['endMin'] as int);
      if (eEnd < eStart) eEnd += 24 * 60;

      final eCat = _categoryFromLabel(slot['label'] as String);
      if (oCat != eCat) continue;

      final overlapStart = oStart > eStart ? oStart : eStart;
      final overlapEnd = oEnd < eEnd ? oEnd : eEnd;
      final overlap = (overlapEnd - overlapStart);
      if (overlap <= 0) continue;

      final oDur = (oEnd - oStart).clamp(1, 24 * 60);
      final overlapRatio = overlap / oDur;

      // Match si au moins 50% de l'activité observée chevauche le créneau attendu
      if (overlapRatio >= 0.5) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Responsivité: adapter la hauteur en fonction de l'écran
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = (screenHeight / 800).clamp(0.8, 1.2);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Largeur disponible (hors padding)
        final availableWidth = (constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width) - 24;
        final columnsWidth = (availableWidth - timeColumnWidth).clamp(240.0, double.infinity);
        final colWidth = columnsWidth / 2;
        final totalTableWidth = timeColumnWidth + (colWidth * 2);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-têtes des colonnes (sans Expanded dans un scroll horizontal)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalTableWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: timeColumnWidth),
                        SizedBox(
                          width: colWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'JOURNÉE TYPE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 2,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '28 JAN. - OBSERVÉ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentCyan,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 2,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentCyan.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Timeline avec deux colonnes
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalTableWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: timeColumnWidth,
                          child: _buildTimeColumn(),
                        ),
                        SizedBox(
                          width: colWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: AppTheme.textSecondary.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: _buildTimelineColumn(
                              journeeType,
                              isObserved: false,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colWidth,
                          child: _buildObservedColumn(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(24, (index) {
        return SizedBox(
          height: hourHeight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                '${index.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimelineColumn(List<Map<String, dynamic>> activities, {required bool isObserved}) {
    final totalHeight = 24 * hourHeight;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // Grille horaire en arrière-plan
          Column(
            children: List.generate(24, (index) {
              return Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.textSecondary.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Activités positionnées
          ...activities.map((activity) {
            final startHour = activity['startHour'] as int;
            final startMin = activity['startMin'] as int;
            final endHour = activity['endHour'] as int;
            final endMin = activity['endMin'] as int;
            final label = activity['label'] as String;
            final icon = activity['icon'] as String;
            final color = _getActivityColor(label);

            final topPos = _getTopPosition(startHour, startMin);
            final height = _getHeight(startHour, startMin, endHour, endMin);

            return Positioned(
              top: topPos,
              left: 4,
              right: 4,
              height: height.clamp(20, double.infinity),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildTimelineActivityCard(
                  label: label,
                  icon: icon,
                  color: color,
                  startHour: startHour,
                  startMin: startMin,
                  endHour: endHour,
                  endMin: endMin,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildObservedColumn() {
    final totalHeight = 24 * hourHeight;

    if (widget.observedActivities.isEmpty) {
      return SizedBox(
        height: totalHeight,
        child: Column(
          children: List.generate(24, (index) {
            return Container(
              height: hourHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.textSecondary.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // Grille horaire en arrière-plan
          Column(
            children: List.generate(24, (index) {
              return Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.textSecondary.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Activités observées positionnées
          ...widget.observedActivities.map((activity) {
            final startMinutes = _getMinutesFromMidnight(
              activity.startAt.hour,
              activity.startAt.minute,
            );
            final endMinutes = _observedEndMinutes(activity, startMinutes);

            final topPos = startMinutes * pixelsPerMinute;
            final height = ((endMinutes - startMinutes) * pixelsPerMinute).clamp(20.0, double.infinity);

            final isMatch = _matchesJourneeType(activity);
            final color = isMatch ? AppTheme.activityGreen : AppTheme.activityRed;
            final label = _getActivityLabel(activity);

            // Adapter l'affichage selon la hauteur
            final isSmallCard = height < 50;
            final isTinyCard = height < 35;

            return Positioned(
              top: topPos,
              left: 4,
              right: 4,
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: GestureDetector(
                  onTap: () => widget.onActivityTap?.call(activity),
                  child: Container(
                    padding: EdgeInsets.all(isTinyCard ? 4 : 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isTinyCard
                        ? // Très petit : juste label
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label.split(' ').first,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                        : isSmallCard
                            ? // Petit : label + temps minimalistes
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              ],
                            )
                            : // Normal : affichage complet
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (height > 35)
                                  Text(
                                    '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineActivityCard({
    required String label,
    required String icon,
    required Color color,
    required int startHour,
    required int startMin,
    required int endHour,
    required int endMin,
  }) {
    // Calculer la hauteur pour adapter l'affichage
    int startTotal = _getMinutesFromMidnight(startHour, startMin);
    int endTotal = _getMinutesFromMidnight(endHour, endMin);
    if (endTotal < startTotal) endTotal += 24 * 60;
    final heightPx = (endTotal - startTotal) * pixelsPerMinute;
    final isSmallCard = heightPx < 50;
    final isTinyCard = heightPx < 35;

    return Opacity(
      opacity: 0.45,  // Grisement de la journée type
      child: Container(
        padding: EdgeInsets.all(isTinyCard ? 4 : 8),
        decoration: BoxDecoration(
          // Fond gris pour journée type
          color: Colors.grey.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne de couleur accent en haut - GRISE
          Container(
            height: 1.5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          if (!isTinyCard) const SizedBox(height: 3),
          // Contenu adapté à la taille - TEXTE GRIS
          if (isTinyCard)
            // Pour les TRÈS petites cartes : juste le label court
            Flexible(
              child: Text(
                label.split(' ').first, // Juste le premier mot
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else if (isSmallCard)
            // Pour les petites cartes : label + icône compact
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon.isNotEmpty)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (icon.isNotEmpty) const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            // Pour les cartes normales : affichage complet
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon.isNotEmpty)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    if (icon.isNotEmpty) const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
        ],
      ),
      ),
    );
  }

  Color _getActivityColorFromType(Activity activity) {
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
    return room.length > 12 ? '${room.substring(0, 12)}...' : room;
  }
}
