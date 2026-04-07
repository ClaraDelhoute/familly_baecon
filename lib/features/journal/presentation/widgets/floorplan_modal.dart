import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';

class FloorplanModal extends StatelessWidget {
  final List<Activity> observedActivities;

  const FloorplanModal({super.key, required this.observedActivities});

  String? _getCurrentRoom() {
    if (observedActivities.isEmpty) return null;
    final latest = observedActivities.reduce((a, b) => a.startAt.isAfter(b.startAt) ? a : b);
    return latest.room;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = _getCurrentRoom();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Localisation en temps réel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Floorplan avec SVG
          Expanded(
            child: Stack(
              children: [
                // SVG du plan
                Center(
                  child: SvgPicture.asset(
                    'assets/floorplan.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                // Pointeur bleu pour localisation
                if (currentRoom != null)
                  Positioned(
                    left: _getXPosition(currentRoom),
                    top: _getYPosition(currentRoom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentRoom,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  double _getXPosition(String room) {
    // Coordonnées approximatives des pièces dans le SVG (420x680)
    switch (room.toUpperCase()) {
      case 'CHAMBRE':
        return 50;
      case 'SALLE DE BAIN':
        return 250;
      case 'SALON':
        return 120;
      case 'COULOIR':
        return 330;
      case 'CUISINE':
        return 60;
      default:
        return 150;
    }
  }

  double _getYPosition(String room) {
    switch (room.toUpperCase()) {
      case 'CHAMBRE':
        return 100;
      case 'SALLE DE BAIN':
        return 110;
      case 'SALON':
        return 280;
      case 'COULOIR':
        return 310;
      case 'CUISINE':
        return 500;
      default:
        return 300;
    }
  }
}

