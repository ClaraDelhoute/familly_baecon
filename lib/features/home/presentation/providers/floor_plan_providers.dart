import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/home/presentation/widgets/floor_plan_widget.dart';

const double _planUnitScale = 100; // 1 mètre = 100 unités canvas

Offset _metersToOffset(double x, double y) =>
    Offset(x * _planUnitScale, y * _planUnitScale);
Size _metersToSize(double width, double height) =>
    Size(width * _planUnitScale, height * _planUnitScale);

/// Provider pour les pièces du logement
final roomsProvider = Provider<List<Room>>((ref) {
  return [
    // Données alignées sur le plan JSON (5m x 5m)
    Room(
      id: 'cuisine',
      name: 'CUISINE',
      position: _metersToOffset(1.25, 3.75),
      size: _metersToSize(2.5, 2.5),
      color: const Color(0xFFE8E2D0),
    ),
    Room(
      id: 'salon',
      name: 'SALON',
      position: _metersToOffset(3.75, 3.75),
      size: _metersToSize(2.5, 2.5),
      color: const Color(0xFFCFD8E3),
    ),
    Room(
      id: 'chambre',
      name: 'CHAMBRE',
      position: _metersToOffset(1.25, 1.25),
      size: _metersToSize(2.5, 2.5),
      color: const Color(0xFFE6CFCF),
    ),
    Room(
      id: 'sdb',
      name: 'SALLE DE BAIN',
      position: _metersToOffset(3.125, 1.25),
      size: _metersToSize(1.25, 2.5),
      color: const Color(0xFFD7E0D7),
    ),
    Room(
      id: 'wc',
      name: 'WC',
      position: _metersToOffset(4.375, 1.25),
      size: _metersToSize(1.25, 2.5),
      color: const Color(0xFFDFE4DF),
    ),
  ];
});

/// Provider pour les capteurs
final sensorsProvider = Provider<List<Sensor>>((ref) {
  return [
    Sensor(
      id: 'M001',
      label: 'M001',
      position: _metersToOffset(1.0, 4.6),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M002',
      label: 'M002',
      position: _metersToOffset(1.8, 3.9),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M003',
      label: 'M003',
      position: _metersToOffset(3.1, 3.1),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M004',
      label: 'M004',
      position: _metersToOffset(2.9, 4.4),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M005',
      label: 'M005',
      position: _metersToOffset(3.9, 4.1),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M006',
      label: 'M006',
      position: _metersToOffset(0.4, 2.1),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M007',
      label: 'M007',
      position: _metersToOffset(1.9, 0.7),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M008',
      label: 'M008',
      position: _metersToOffset(3.0, 0.6),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M009',
      label: 'M009',
      position: _metersToOffset(3.1, 1.4),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M010',
      label: 'M010',
      position: _metersToOffset(4.4, 0.9),
      isMotionDetector: true,
    ),
    // Portes (détecteurs)
    Sensor(
      id: 'D001',
      label: 'D001',
      position: _metersToOffset(5.0, 4.0),
      isMotionDetector: false,
    ),
    Sensor(
      id: 'D002',
      label: 'D002',
      position: _metersToOffset(2.5, 3.7),
      isMotionDetector: false,
    ),
    Sensor(
      id: 'D003',
      label: 'D003',
      position: _metersToOffset(2.5, 1.2),
      isMotionDetector: false,
    ),
    Sensor(
      id: 'D004',
      label: 'D004',
      position: _metersToOffset(4.0, 1.2),
      isMotionDetector: false,
    ),
  ];
});

/// Provider pour la pièce sélectionnée
final selectedRoomProvider = StateProvider<String?>((ref) => null);

/// Provider pour le dernier capteur activé (anomalie)
final lastActiveSensorProvider = StateProvider<String?>((ref) => null);

/// Provider pour activer un capteur (anomalie détectée)
final activateSensorProvider =
    StateNotifierProvider<SensorActivationNotifier, String?>((ref) {
      return SensorActivationNotifier();
    });

class SensorActivationNotifier extends StateNotifier<String?> {
  SensorActivationNotifier() : super(null);

  void activateSensor(String sensorId) {
    state = sensorId;
  }

  void deactivateSensor() {
    state = null;
  }
}
