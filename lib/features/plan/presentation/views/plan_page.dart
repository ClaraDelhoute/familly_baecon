import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/home/presentation/providers/floor_plan_providers.dart';
import 'package:familly_baecon/features/home/presentation/widgets/floor_plan_widget.dart';
import 'package:familly_baecon/core/utils/activity_labels.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final sensors = ref.watch(sensorsProvider);
    final selectedRoom = ref.watch(selectedRoomProvider);
    final activeSensor = ref.watch(activateSensorProvider);
    final sensorEvents =
        ref.watch(liveSensorEventsProvider).valueOrNull ?? const [];

    final latestEvent = sensorEvents.isEmpty
        ? null
        : sensorEvents.reduce(
            (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
          );
    final latestSensorId =
        _mapRoomToSensorId(latestEvent?.room, sensors) ?? activeSensor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              latestEvent == null
                  ? 'Dernière localisation: inconnue'
                  : 'Dernière localisation: ${roomLabel(latestEvent.room)} • ${_formatHm(latestEvent.timestamp)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: FloorPlanWidget(
                rooms: rooms,
                sensors: sensors,
                selectedRoomId: selectedRoom,
                activeSensorId: latestSensorId,
                height: double.infinity,
                frameless: true,
                showHeader: false,
                showLegend: false,
                onRoomTap: (roomId) {
                  ref.read(selectedRoomProvider.notifier).state = roomId;
                },
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legend(context, const Color(0xFFDC2626), 'Dernier capteur déclenché'),
                _legend(context, const Color(0xFF4B5563), 'Capteur inactif'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatHm(DateTime date) {
    final d = date.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _legend(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
        ),
      ],
    );
  }

  String? _mapRoomToSensorId(String? room, List<Sensor> sensors) {
    if (room == null) return null;
    final normalized = room.toLowerCase();
    final candidatesByRoom = <String, List<String>>{
      'cuisine': ['M001', 'M002'],
      'salon': ['M003', 'M004', 'M005'],
      'outside': ['D001'],
      'chambre': ['M006', 'M007'],
      'salle_de_bain': ['M008', 'M009', 'D004'],
      'sdb': ['M008', 'M009', 'D004'],
      'bain': ['M008', 'M009', 'D004'],
      'bathroom': ['M008', 'M009', 'D004'],
      'toilettes': ['M010', 'D005'],
      'wc': ['M010', 'D005'],
      'toilet': ['M010', 'D005'],
    };

    for (final entry in candidatesByRoom.entries) {
      if (normalized.contains(entry.key)) {
        for (final sensorId in entry.value) {
          if (sensors.any((sensor) => sensor.id == sensorId)) {
            return sensorId;
          }
        }
      }
    }
    return null;
  }
}
