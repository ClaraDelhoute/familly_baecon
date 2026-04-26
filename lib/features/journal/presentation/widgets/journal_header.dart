import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

class JournalHeader extends StatelessWidget {
  final String personName;
  final String? currentRoom;
  final VoidCallback onShowFloorplan;

  const JournalHeader({
    super.key,
    required this.personName,
    this.currentRoom,
    required this.onShowFloorplan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accentBlue, context.palette.surface],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currentRoom ?? 'Localisation inconnue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onShowFloorplan,
            icon: const Icon(Icons.map, size: 18),
            label: const Text(
              'Voir plan',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.accentBlue,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
