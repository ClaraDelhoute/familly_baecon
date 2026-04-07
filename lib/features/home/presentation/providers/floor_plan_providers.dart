import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/home/presentation/widgets/floor_plan_widget.dart';

/// Provider pour les pièces du logement
final roomsProvider = Provider<List<Room>>((ref) {
  return [
    // CUISINE (haut gauche - beige)
    Room(
      id: 'kitchen',
      name: 'CUISINE\n(6.2m²)',
      position: const Offset(120, 120),
      size: const Size(100, 70),
      color: const Color(0xFFFEF3C7), // Beige
    ),

    // SALON (haut droit - bleu clair)
    Room(
      id: 'living',
      name: 'SALON\n(6.2m²)',
      position: const Offset(220, 120),
      size: const Size(100, 70),
      color: const Color(0xFFBFDBFE), // Bleu clair
    ),

    // CHAMBRE (bas gauche - rose)
    Room(
      id: 'bedroom',
      name: 'CHAMBRE\n(6.2m²)',
      position: const Offset(120, 220),
      size: const Size(100, 70),
      color: const Color(0xFFFCE7F3), // Rose
    ),

    // DB - Dressing/Bain (bas centre)
    Room(
      id: 'bathroom',
      name: 'DB\n(3.8m²)',
      position: const Offset(170, 220),
      size: const Size(70, 70),
      color: const Color(0xFFF0FDF4), // Vert clair
    ),

    // WC (bas droit - vert)
    Room(
      id: 'wc',
      name: 'WC\n(2.5m²)',
      position: const Offset(230, 220),
      size: const Size(70, 70),
      color: const Color(0xFFF0FDF4), // Vert clair
    ),
  ];
});

/// Provider pour les capteurs
final sensorsProvider = Provider<List<Sensor>>((ref) {
  return [
    // Cuisine
    Sensor(
      id: 'M001',
      label: 'M001',
      position: const Offset(100, 90),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M002',
      label: 'M002',
      position: const Offset(130, 110),
      isMotionDetector: true,
    ),

    // Salon
    Sensor(
      id: 'M003',
      label: 'M003',
      position: const Offset(210, 125),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M004',
      label: 'M004',
      position: const Offset(200, 100),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M005',
      label: 'M005',
      position: const Offset(240, 110),
      isMotionDetector: true,
    ),

    // Entrée
    Sensor(
      id: 'D001',
      label: 'D001',
      position: const Offset(260, 115),
      isMotionDetector: false,
    ),

    // Chambre
    Sensor(
      id: 'M006',
      label: 'M006',
      position: const Offset(100, 200),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M007',
      label: 'M007',
      position: const Offset(130, 220),
      isMotionDetector: true,
    ),

    // DB
    Sensor(
      id: 'M008',
      label: 'M008',
      position: const Offset(160, 225),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'M009',
      label: 'M009',
      position: const Offset(180, 210),
      isMotionDetector: true,
    ),
    Sensor(
      id: 'D006',
      label: 'D006',
      position: const Offset(200, 240),
      isMotionDetector: false,
    ),

    // WC
    Sensor(
      id: 'M010',
      label: 'M010',
      position: const Offset(240, 215),
      isMotionDetector: true,
    ),

    // Détecteurs portes/capteurs distributin
    Sensor(
      id: 'D003',
      label: 'D003',
      position: const Offset(150, 140),
      isMotionDetector: false,
    ),
    Sensor(
      id: 'D008',
      label: 'D008',
      position: const Offset(170, 190),
      isMotionDetector: false,
    ),
  ];
});

/// Provider pour la pièce sélectionnée
final selectedRoomProvider = StateProvider<String?>((ref) => null);

/// Provider pour le dernier capteur activé (anomalie)
final lastActiveSensorProvider = StateProvider<String?>((ref) => null);

/// Provider pour activer un capteur (anomalie détectée)
final activateSensorProvider = StateNotifierProvider<SensorActivationNotifier, String?>((ref) {
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

