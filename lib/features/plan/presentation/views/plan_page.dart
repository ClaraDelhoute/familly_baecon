import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/utils/orientation_lock.dart';
import 'package:familly_baecon/features/home/presentation/providers/floor_plan_providers.dart';
import 'package:familly_baecon/features/home/presentation/widgets/floor_plan_widget.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final sensors = ref.watch(sensorsProvider);
    final selectedRoom = ref.watch(selectedRoomProvider);
    final activeSensor = ref.watch(activateSensorProvider);
    final observed =
        ref.watch(liveObservedActivitiesProvider).valueOrNull ?? const [];
    final sensorEvents =
        ref.watch(liveSensorEventsProvider).valueOrNull ?? const [];

    final latest = observed.isEmpty
        ? null
        : observed.reduce((a, b) => a.startAt.isAfter(b.startAt) ? a : b);
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
            tooltip: 'Mode horizontal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _PlanLandscapePage(
                    rooms: rooms,
                    sensors: sensors,
                    selectedRoom: selectedRoom,
                    activeSensor: latestSensorId,
                    onRoomTap: (roomId) {
                      ref.read(selectedRoomProvider.notifier).state = roomId;
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.screen_rotation_alt),
          ),
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
              latest == null
                  ? 'Dernière localisation: inconnue'
                  : 'Dernière localisation: ${latest.room ?? 'Inconnue'} • ${_formatHm(latest.startAt)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
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
                _legend(const Color(0xFFDC2626), 'Dernier capteur déclenché'),
                _legend(const Color(0xFF4B5563), 'Capteur inactif'),
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

  Widget _legend(Color color, String label) {
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
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
      'chambre': ['M006', 'M007'],
      'db': ['M008', 'M009', 'D006'],
      'bain': ['M008', 'M009', 'D006'],
      'bathroom': ['M008', 'M009', 'D006'],
      'wc': ['M010'],
      'toilet': ['M010'],
      'toilettes': ['M010'],
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

class _PlanLandscapePage extends StatefulWidget {
  final List<Room> rooms;
  final List<Sensor> sensors;
  final String? selectedRoom;
  final String? activeSensor;
  final ValueChanged<String> onRoomTap;

  const _PlanLandscapePage({
    required this.rooms,
    required this.sensors,
    required this.selectedRoom,
    required this.activeSensor,
    required this.onRoomTap,
  });

  @override
  State<_PlanLandscapePage> createState() => _PlanLandscapePageState();
}

class _PlanLandscapePageState extends State<_PlanLandscapePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    applyDefaultOrientationLock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan (horizontal)'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text('Quitter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox.expand(
          child: FloorPlanWidget(
            rooms: widget.rooms,
            sensors: widget.sensors,
            selectedRoomId: widget.selectedRoom,
            activeSensorId: widget.activeSensor,
            height: double.infinity,
            frameless: true,
            showHeader: false,
            showLegend: false,
            onRoomTap: widget.onRoomTap,
          ),
        ),
      ),
    );
  }
}
