import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';

class FloorplanWidget extends StatelessWidget {
  final List<Activity> observed;
  const FloorplanWidget({super.key, required this.observed});

  @override
  Widget build(BuildContext context) {
    // Determine active room from observed latest activity
    final latest = observed.isNotEmpty ? observed.reduce((a, b) => a.startAt.isAfter(b.startAt) ? a : b) : null;
    final activeRoom = latest?.room?.toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Stack(
        children: [
          SvgPicture.asset('assets/floorplan.svg', fit: BoxFit.contain),
          if (activeRoom != null)
            Positioned(
              left: activeRoom == 'CHAMBRE' ? 80 : activeRoom == 'SALLE DE BAIN' ? 260 : activeRoom == 'SALON' ? 140 : 40,
              top: activeRoom == 'CHAMBRE' ? 130 : activeRoom == 'SALLE DE BAIN' ? 140 : activeRoom == 'SALON' ? 320 : 520,
              child: Column(
                children: [
                  Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.9), shape: BoxShape.circle)),
                  const SizedBox(height: 6),
                  Text(activeRoom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
