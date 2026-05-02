import 'package:flutter/material.dart';
import 'package:familly_baecon/core/domain/activity_type.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

class TimelineScheduleView extends StatefulWidget {
  final List<Activity> expectedActivities;
  final List<Activity> observedActivities;
  final Function(Activity)? onActivityTap;
  final bool showExpectedColumn;
  final bool showObservedColumn;
  final String expectedColumnTitle;
  final String observedColumnTitle;
  final double? sharedVerticalOffset;
  final ValueChanged<double>? onVerticalOffsetChanged;

  const TimelineScheduleView({
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
  State<TimelineScheduleView> createState() => _TimelineScheduleViewState();
}

class _TimelineScheduleViewState extends State<TimelineScheduleView> {
  final ScrollController _verticalScrollController = ScrollController();
  int? _lastCenteredMinute;
  bool _isApplyingSharedOffset = false;

  // Journée type hardcodée avec heures exactes
  static const List<Map<String, dynamic>> journeeType = [
    // Matin
    {
      'startHour': 8,
      'startMin': 0,
      'endHour': 8,
      'endMin': 40,
      'label': 'Temps libre / réveil',
      'icon': '',
    },
    {
      'startHour': 8,
      'startMin': 40,
      'endHour': 8,
      'endMin': 55,
      'label': 'Douche',
      'icon': '🚿',
    },
    {
      'startHour': 9,
      'startMin': 10,
      'endHour': 9,
      'endMin': 30,
      'label': 'Petit-déjeuner',
      'icon': '🍳',
    },
    {
      'startHour': 9,
      'startMin': 55,
      'endHour': 11,
      'endMin': 30,
      'label': 'Sortie / déplacement',
      'icon': '🚗',
    },
    // Midi
    {
      'startHour': 11,
      'startMin': 30,
      'endHour': 12,
      'endMin': 36,
      'label': 'Temps libre / activité',
      'icon': '',
    },
    {
      'startHour': 12,
      'startMin': 36,
      'endHour': 13,
      'endMin': 10,
      'label': 'Déjeuner',
      'icon': '🍽️',
    },
    // Après-midi
    {
      'startHour': 13,
      'startMin': 10,
      'endHour': 16,
      'endMin': 45,
      'label': 'Temps libre / activité',
      'icon': '',
    },
    {
      'startHour': 16,
      'startMin': 45,
      'endHour': 18,
      'endMin': 15,
      'label': 'Sortie / déplacement',
      'icon': '🚗',
    },
    // Soir
    {
      'startHour': 18,
      'startMin': 15,
      'endHour': 19,
      'endMin': 30,
      'label': 'Temps libre',
      'icon': '',
    },
    {
      'startHour': 19,
      'startMin': 30,
      'endHour': 20,
      'endMin': 12,
      'label': 'Dîner',
      'icon': '🍽️',
    },
    {
      'startHour': 20,
      'startMin': 12,
      'endHour': 21,
      'endMin': 20,
      'label': 'Temps libre',
      'icon': '',
    },
    // Nuit
    {
      'startHour': 21,
      'startMin': 20,
      'endHour': 8,
      'endMin': 30,
      'label': 'Sommeil',
      'icon': '😴',
    },
  ];

  // Constantes pour la timeline
  static const double hourHeight = 100.0;
  static const double pixelsPerMinute = hourHeight / 60.0;
  static const double timeColumnWidth = 92.0;
  static const double _minCardHeight = 34.0;

  int _getMinutesFromMidnight(int hour, int minute) {
    return hour * 60 + minute;
  }

  int _minutesFromDateTime(DateTime dateTime) {
    return _getMinutesFromMidnight(dateTime.hour, dateTime.minute);
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

  String _categoryFromLabel(String label) =>
      ActivityType.fromTypeContains(label).category;

  String _categoryFromObserved(Activity activity) {
    final fromType = ActivityType.fromTypeContains(activity.type);
    if (fromType != ActivityType.unknown) return fromType.category;
    return ActivityType.fromRoom(activity.room ?? '').category;
  }

  int _observedEndMinutes(Activity activity, int startMinutes) {
    if (activity.endAt != null) {
      return _minutesFromDateTime(activity.endAt!);
    }
    if (activity.durationMin != null && activity.durationMin! > 0) {
      return startMinutes + activity.durationMin!;
    }
    return startMinutes + 60;
  }

  bool _matchesJourneeType(Activity observed) {
    final expectedSlots = _expectedSlots();
    if (expectedSlots.isEmpty) return false;

    final oStart = _minutesFromDateTime(observed.startAt);
    var oEnd = _observedEndMinutes(observed, oStart);
    if (oEnd < oStart) oEnd += 24 * 60;

    final oCat = _categoryFromObserved(observed);

    for (final slot in expectedSlots) {
      final eStart = _getMinutesFromMidnight(
        slot['startHour'] as int,
        slot['startMin'] as int,
      );
      var eEnd = _getMinutesFromMidnight(
        slot['endHour'] as int,
        slot['endMin'] as int,
      );
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
  void initState() {
    super.initState();
    _verticalScrollController.addListener(_handleVerticalScrollChanged);
    _scheduleAutoCenter();
  }

  @override
  void didUpdateWidget(covariant TimelineScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sharedVerticalOffset != null &&
        widget.sharedVerticalOffset != oldWidget.sharedVerticalOffset &&
        _verticalScrollController.hasClients) {
      final max = _verticalScrollController.position.maxScrollExtent;
      final target = widget.sharedVerticalOffset!.clamp(0.0, max);
      if ((_verticalScrollController.offset - target).abs() > 1) {
        _isApplyingSharedOffset = true;
        _verticalScrollController.jumpTo(target);
        _isApplyingSharedOffset = false;
      }
    }
    _scheduleAutoCenter();
  }

  @override
  void dispose() {
    _verticalScrollController.removeListener(_handleVerticalScrollChanged);
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _handleVerticalScrollChanged() {
    if (_isApplyingSharedOffset) return;
    widget.onVerticalOffsetChanged?.call(_verticalScrollController.offset);
  }

  void _scheduleAutoCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_verticalScrollController.hasClients) return;
      final shared = widget.sharedVerticalOffset;
      if (shared != null) {
        final max = _verticalScrollController.position.maxScrollExtent;
        final target = shared.clamp(0.0, max);
        if ((_verticalScrollController.offset - target).abs() > 1) {
          _isApplyingSharedOffset = true;
          _verticalScrollController.jumpTo(target);
          _isApplyingSharedOffset = false;
        }
        return;
      }
      _centerOnLatestActivity();
    });
  }

  int? _latestRelevantMinute() {
    if (widget.showObservedColumn && widget.observedActivities.isNotEmpty) {
      return widget.observedActivities
          .map((activity) {
            final start = _minutesFromDateTime(activity.startAt);
            return _observedEndMinutes(activity, start);
          })
          .reduce((a, b) => a > b ? a : b);
    }
    if (widget.showExpectedColumn && widget.expectedActivities.isNotEmpty) {
      return widget.expectedActivities
          .map((activity) {
            final end = activity.endAt ?? activity.startAt;
            return _minutesFromDateTime(end);
          })
          .reduce((a, b) => a > b ? a : b);
    }
    return null;
  }

  void _centerOnLatestActivity() {
    if (!_verticalScrollController.hasClients) return;
    final minute = _latestRelevantMinute();
    if (minute == null) return;
    if (_lastCenteredMinute == minute) return;
    _lastCenteredMinute = minute;

    const timelineHeaderOffset = 120.0;
    final viewport = _verticalScrollController.position.viewportDimension;
    final rawTarget =
        timelineHeaderOffset + (minute * pixelsPerMinute) - (viewport * 0.45);
    final target = rawTarget.clamp(
      0.0,
      _verticalScrollController.position.maxScrollExtent,
    );
    _isApplyingSharedOffset = true;
    _verticalScrollController.jumpTo(target);
    _isApplyingSharedOffset = false;
    widget.onVerticalOffsetChanged?.call(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showExpected = widget.showExpectedColumn;
        final showObserved = widget.showObservedColumn;
        final visibleColumns = (showExpected ? 1 : 0) + (showObserved ? 1 : 0);
        final effectiveColumns = visibleColumns == 0 ? 1 : visibleColumns;

        // Largeur disponible (hors padding)
        final availableWidth =
            (constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width) -
            24;
        final columnsWidth = (availableWidth - timeColumnWidth).clamp(
          240.0,
          double.infinity,
        );
        final colWidth = columnsWidth / effectiveColumns;
        final totalTableWidth = timeColumnWidth + (colWidth * effectiveColumns);

        return SingleChildScrollView(
          controller: _verticalScrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        if (showExpected)
                          SizedBox(
                            width: colWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.expectedColumnTitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
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
                                      color: AppTheme.accentBlue.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (showObserved && widget.observedColumnTitle.isNotEmpty)
                          SizedBox(
                            width: colWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.observedColumnTitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
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
                                      color: AppTheme.accentCyan.withValues(
                                        alpha: 0.3,
                                      ),
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
                        if (showExpected)
                          SizedBox(
                            width: colWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                border: showObserved
                                    ? Border(
                                        right: BorderSide(
                                          color: context.palette.textSecondary
                                              .withValues(alpha: 0.2),
                                          width: 1.5,
                                        ),
                                      )
                                    : null,
                              ),
                              child: _buildTimelineColumn(
                                _expectedSlots(),
                                isObserved: false,
                              ),
                            ),
                          ),
                        if (showObserved)
                          SizedBox(
                            width: colWidth,
                            child: _buildObservedColumn(colWidth),
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
        return Container(
          height: hourHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.15),
                width: 0.9,
              ),
              right: BorderSide(
                color: Colors.black.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 0),
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                '${index.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimelineColumn(
    List<Map<String, dynamic>> activities, {
    required bool isObserved,
  }) {
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
                      color: context.palette.textSecondary.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Activités positionnées (traverse-minuit → 2 barres)
          ...activities.expand((activity) {
            final startHour = activity['startHour'] as int;
            final startMin = activity['startMin'] as int;
            final endHour = activity['endHour'] as int;
            final endMin = activity['endMin'] as int;
            final label = activity['label'] as String;
            final icon = activity['icon'] as String;

            final startTotal = _getMinutesFromMidnight(startHour, startMin);
            final endTotal = _getMinutesFromMidnight(endHour, endMin);
            final crossesMidnight = endTotal < startTotal;

            if (!crossesMidnight) {
              final topPos = _getTopPosition(startHour, startMin);
              final height = _getHeight(startHour, startMin, endHour, endMin);
              return [Positioned(
                top: topPos,
                left: 4,
                right: 4,
                height: height.clamp(_minCardHeight, double.infinity),
                child: _buildTimelineActivityCard(
                  label: label, icon: icon,
                  startHour: startHour, startMin: startMin,
                  endHour: endHour, endMin: endMin,
                ),
              )];
            }

            // Segment soir : startHour→23h59
            final topPos1 = _getTopPosition(startHour, startMin);
            final height1 = _getHeight(startHour, startMin, 23, 59);
            // Segment matin : 00h00→endHour
            final height2 = _getHeight(0, 0, endHour, endMin);

            return [
              Positioned(
                top: topPos1,
                left: 4,
                right: 4,
                height: height1.clamp(_minCardHeight, double.infinity),
                child: _buildTimelineActivityCard(
                  label: label, icon: icon,
                  startHour: startHour, startMin: startMin,
                  endHour: 23, endMin: 59,
                ),
              ),
              Positioned(
                top: 0,
                left: 4,
                right: 4,
                height: height2.clamp(_minCardHeight, double.infinity),
                child: _buildTimelineActivityCard(
                  label: label, icon: icon,
                  startHour: 0, startMin: 0,
                  endHour: endHour, endMin: endMin,
                ),
              ),
            ];
          }),
        ],
      ),
    );
  }

  Widget _buildObservedColumn(double colWidth) {
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
                    color: context.palette.textSecondary.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    final layouts = _computeObservedLayouts(widget.observedActivities);
    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final usableWidth = constraints.maxWidth - 8;
          return Stack(
            children: [
              Column(
                children: List.generate(24, (index) {
                  return Container(
                    height: hourHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: context.palette.textSecondary.withValues(alpha: 0.18),
                          width: 1.2,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              ...layouts.map((layout) {
                final laneCount = layout.laneCount;
                final laneGap = laneCount > 1 ? 4.0 : 0.0;
                final laneWidth =
                    ((usableWidth - ((laneCount - 1) * laneGap)) / laneCount)
                        .clamp(56.0, usableWidth);
                final left = 4 + (layout.lane * (laneWidth + laneGap));
                final color = layout.isMatch
                    ? AppTheme.activityGreen
                    : AppTheme.activityRed;
                final label = _getActivityLabel(layout.activity);
                final emoji = _emojiForObserved(layout.activity);

                return Positioned(
                  top: layout.top,
                  left: left,
                  width: laneWidth,
                  height: layout.height,
                  child: GestureDetector(
                    onTap: () => widget.onActivityTap?.call(layout.activity),
                    child: _buildObservedActivityCard(
                      height: layout.height,
                      color: color,
                      emoji: emoji,
                      label: label,
                      startAt: layout.activity.startAt,
                      endAt: layout.activity.endAt,
                      durationMin: layout.activity.durationMin,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildObservedActivityCard({
    required double height,
    required Color color,
    required String emoji,
    required String label,
    required DateTime startAt,
    required DateTime? endAt,
    required int? durationMin,
  }) {
    final isTinyCard = height < 48;
    final isSmallCard = height < 72;
    final isCompactCard = height < 88;
    final background = Color.lerp(Colors.white, color, 0.22) ?? Colors.white;
    final borderColor = Color.lerp(Colors.black, color, 0.35) ?? Colors.black;
    final timeLabel = _formatObservedRange(startAt, endAt, durationMin);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTinyCard ? 4 : 6,
          vertical: isTinyCard ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: borderColor, width: 1.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactLabel = '$emoji ${label.split(' ').first}';

            if (isTinyCard || constraints.maxHeight < 42) {
              return Center(
                child: Text(
                  compactLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }

            if (isCompactCard || constraints.maxHeight < 58) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$emoji $label',
                    style: TextStyle(
                      fontSize: isSmallCard ? 13 : 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji $label',
                  style: TextStyle(
                    fontSize: isSmallCard ? 13 : 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  maxLines: isSmallCard ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: isSmallCard ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_ObservedLayout> _computeObservedLayouts(List<Activity> activities) {
    if (activities.isEmpty) return const <_ObservedLayout>[];
    final sorted = [...activities]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final result = <_ObservedLayout>[];

    var cluster = <_ObservedRawInterval>[];
    var clusterEnd = -1;
    for (final activity in sorted) {
      final start = _getMinutesFromMidnight(
        activity.startAt.hour,
        activity.startAt.minute,
      );
      var end = _observedEndMinutes(activity, start);
      if (end < start) end += 24 * 60;
      if (cluster.isEmpty || start < clusterEnd) {
        cluster.add(
          _ObservedRawInterval(activity: activity, start: start, end: end),
        );
        if (end > clusterEnd) clusterEnd = end;
      } else {
        result.addAll(_layoutCluster(cluster));
        cluster = <_ObservedRawInterval>[
          _ObservedRawInterval(activity: activity, start: start, end: end),
        ];
        clusterEnd = end;
      }
    }
    if (cluster.isNotEmpty) {
      result.addAll(_layoutCluster(cluster));
    }
    return result;
  }

  List<_ObservedLayout> _layoutCluster(List<_ObservedRawInterval> cluster) {
    final active = <_ObservedLaneInterval>[];
    final built = <_ObservedLayoutTemp>[];
    var maxLane = 0;

    for (final item in cluster) {
      active.removeWhere((interval) => interval.end <= item.start);
      final used = active.map((e) => e.lane).toSet();
      var lane = 0;
      while (used.contains(lane)) {
        lane++;
      }
      active.add(_ObservedLaneInterval(end: item.end, lane: lane));
      if (lane > maxLane) maxLane = lane;
      built.add(_ObservedLayoutTemp(item: item, lane: lane));
    }

    final laneCount = maxLane + 1;
    return built
        .map(
          (b) => _ObservedLayout(
            activity: b.item.activity,
            top: b.item.start * pixelsPerMinute,
            height: ((b.item.end - b.item.start) * pixelsPerMinute).clamp(
              _minCardHeight,
              double.infinity,
            ),
            lane: b.lane,
            laneCount: laneCount,
            isMatch: _matchesJourneeType(b.item.activity),
          ),
        )
        .toList();
  }

  Widget _buildTimelineActivityCard({
    required String label,
    required String icon,
    required int startHour,
    required int startMin,
    required int endHour,
    required int endMin,
  }) {
    int startTotal = _getMinutesFromMidnight(startHour, startMin);
    int endTotal = _getMinutesFromMidnight(endHour, endMin);
    if (endTotal < startTotal) endTotal += 24 * 60;
    final heightPx = (endTotal - startTotal) * pixelsPerMinute;
    final isTinyCard = heightPx < 44;
    final isSmallCard = heightPx < 64;
    final isCompactCard = heightPx < 88;

    final iconToShow = icon.isNotEmpty ? icon : _emojiFromLabel(label);
    final timeRange =
        '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';
    final compactLabel = _compactTypeLabel(label);

    return Opacity(
      opacity: 0.9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTinyCard ? 4 : 8,
            vertical: isTinyCard ? 3 : 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            border: Border.all(color: Colors.black54, width: 1.8),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactText =
                  '${iconToShow.isEmpty ? '' : '$iconToShow '}${compactLabel.split(' ').first}';

              if (isTinyCard || constraints.maxHeight < 40) {
                return Center(
                  child: Text(
                    compactText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }

              if (isCompactCard || constraints.maxHeight < 56) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${iconToShow.isEmpty ? '' : '$iconToShow '}$compactLabel',
                      style: TextStyle(
                        fontSize: isSmallCard ? 12 : 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${iconToShow.isEmpty ? '' : '$iconToShow '}$compactLabel',
                    style: TextStyle(
                      fontSize: isSmallCard ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isSmallCard) ...[
                    const SizedBox(height: 2),
                    Text(
                      '🕒 $timeRange',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _getActivityLabel(Activity activity) {
    final activityLabel = _formatTypeLabel(activity.type);
    return activityLabel.length > 18
        ? '${activityLabel.substring(0, 18)}...'
        : activityLabel;
  }

  String _emojiFromLabel(String label) {
    final t = ActivityType.fromTypeContains(label);
    return t == ActivityType.unknown ? '🕒' : t.emoji;
  }

  String _formatTypeLabel(String rawType) {
    final t = ActivityType.fromTypeContains(rawType);
    return t == ActivityType.unknown ? rawType : t.label;
  }

  String _compactTypeLabel(String label) {
    if (label.length <= 24) return label;
    return '${label.substring(0, 24)}…';
  }

  String _emojiForObserved(Activity activity) {
    final fromType = ActivityType.fromTypeContains(activity.type);
    if (fromType != ActivityType.unknown) return fromType.emoji;
    final fromRoom = ActivityType.fromRoom(activity.room ?? '');
    return fromRoom == ActivityType.unknown ? '📍' : fromRoom.emoji;
  }

  String _formatHmFromMinute(int minute) {
    final normalized = ((minute % (24 * 60)) + (24 * 60)) % (24 * 60);
    final h = (normalized ~/ 60).toString().padLeft(2, '0');
    final m = (normalized % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatObservedRange(
    DateTime startAt,
    DateTime? endAt,
    int? durationMin,
  ) {
    final startMinute = _minutesFromDateTime(startAt);
    final computedEnd = endAt != null
        ? _minutesFromDateTime(endAt)
        : (durationMin != null && durationMin > 0)
        ? startMinute + durationMin
        : startMinute + 60;
    final endMinute = computedEnd < startMinute
        ? computedEnd + (24 * 60)
        : computedEnd;
    return '${_formatHmFromMinute(startMinute)} - ${_formatHmFromMinute(endMinute)}';
  }

  List<Map<String, dynamic>> _expectedSlots() {
    if (widget.expectedActivities.isEmpty) return journeeType;
    return widget.expectedActivities.map((activity) {
      final startMinute = _minutesFromDateTime(activity.startAt);
      var endMinute = activity.endAt != null
          ? _minutesFromDateTime(activity.endAt!)
          : (activity.durationMin != null && activity.durationMin! > 0)
          ? startMinute + activity.durationMin!
          : startMinute + 60;
      if (endMinute < startMinute) endMinute += 24 * 60;
      return <String, dynamic>{
        'startHour': (startMinute ~/ 60) % 24,
        'startMin': startMinute % 60,
        'endHour': (endMinute ~/ 60) % 24,
        'endMin': endMinute % 60,
        'label': _formatTypeLabel(activity.type),
        'icon': _emojiForObserved(activity),
      };
    }).toList()..sort((a, b) {
      final aStart = (a['startHour'] as int) * 60 + (a['startMin'] as int);
      final bStart = (b['startHour'] as int) * 60 + (b['startMin'] as int);
      return aStart.compareTo(bStart);
    });
  }
}

class _ObservedRawInterval {
  final Activity activity;
  final int start;
  final int end;

  const _ObservedRawInterval({
    required this.activity,
    required this.start,
    required this.end,
  });
}

class _ObservedLaneInterval {
  final int end;
  final int lane;

  const _ObservedLaneInterval({required this.end, required this.lane});
}

class _ObservedLayoutTemp {
  final _ObservedRawInterval item;
  final int lane;

  const _ObservedLayoutTemp({required this.item, required this.lane});
}

class _ObservedLayout {
  final Activity activity;
  final double top;
  final double height;
  final int lane;
  final int laneCount;
  final bool isMatch;

  const _ObservedLayout({
    required this.activity,
    required this.top,
    required this.height,
    required this.lane,
    required this.laneCount,
    required this.isMatch,
  });
}
