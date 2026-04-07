import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';

class TimelineColumn extends StatelessWidget {
  final List<Activity> expected;
  final List<Activity> observed;

  const TimelineColumn({super.key, required this.expected, required this.observed});

  Color _colorFor(Activity expected, Activity? observed) {
    if (observed == null) return Colors.red;
    // simple equality check: same room and overlap > 50% -> green else red
    final sameRoom = expected.room == observed.room;
    if (!sameRoom) return Colors.red;

    final expectedDuration = expected.endAt?.difference(expected.startAt).inMinutes ?? 0;
    final overlapStart = expected.startAt.isAfter(observed.startAt) ? expected.startAt : observed.startAt;
    final overlapEnd = (expected.endAt ?? expected.startAt).isBefore(observed.endAt ?? observed.startAt) ? (expected.endAt ?? expected.startAt) : (observed.endAt ?? observed.startAt);
    final overlap = overlapEnd.isAfter(overlapStart) ? overlapEnd.difference(overlapStart).inMinutes : 0;

    if (expectedDuration == 0) return Colors.red;
    final ratio = overlap / expectedDuration;
    return ratio >= 0.5 ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Journée type', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: expected.length,
              itemBuilder: (c, i) {
                final e = expected[i];
                Activity? match;
                for (final o in observed) {
                  if (o.room == e.room || o.type == e.type) {
                    match = o;
                    break;
                  }
                }
                final color = _colorFor(e, match);
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.room ?? e.type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${e.startAt.hour.toString().padLeft(2,'0')}:${e.startAt.minute.toString().padLeft(2,'0')} - ${e.endAt?.hour.toString().padLeft(2,'0') ?? '--'}:${e.endAt?.minute.toString().padLeft(2,'0') ?? '--'}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
