import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

/// Représentation d'une pièce
class Room {
  final String name;
  final String id;
  final Offset position; // Centre de la pièce
  final Size size;
  final Color color;

  Room({
    required this.name,
    required this.id,
    required this.position,
    required this.size,
    required this.color,
  });
}

/// Représentation d'un capteur
class Sensor {
  final String id;
  final String label;
  final Offset position;
  final bool isMotionDetector;

  Sensor({
    required this.id,
    required this.label,
    required this.position,
    this.isMotionDetector = false,
  });
}

/// Widget affichant le plan du logement
class FloorPlanWidget extends StatelessWidget {
  final List<Room> rooms;
  final List<Sensor> sensors;
  final String? selectedRoomId;
  final String? activeSensorId;
  final Function(String roomId)? onRoomTap;

  const FloorPlanWidget({
    super.key,
    required this.rooms,
    required this.sensors,
    this.selectedRoomId,
    this.activeSensorId,
    this.onRoomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: AppTheme.accentBlue.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentBlue.withValues(alpha: 0.1),
              AppTheme.accentCyan.withValues(alpha: 0.08),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.accentBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Plan du logement',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Plan avec CustomPaint
            SizedBox(
              height: 300,
              child: CustomPaint(
                painter: FloorPlanPainter(
                  rooms: rooms,
                  sensors: sensors,
                  selectedRoomId: selectedRoomId,
                  activeSensorId: activeSensorId,
                ),
                child: GestureDetector(
                  onTapDown: (details) {
                    // Déterminer quelle pièce a été tapée
                    final localPosition = details.localPosition;
                    for (final room in rooms) {
                      final rectLeft = room.position.dx - (room.size.width / 2);
                      final rectTop = room.position.dy - (room.size.height / 2);
                      final rect = Rect.fromLTWH(
                        rectLeft,
                        rectTop,
                        room.size.width,
                        room.size.height,
                      );
                      if (rect.contains(localPosition)) {
                        onRoomTap?.call(room.id);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Légende
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(
                  icon: '🔴',
                  label: 'Capteur IR',
                  color: const Color(0xFFEF4444),
                ),
                _buildLegendItem(
                  icon: '🟠',
                  label: 'Porte/Fenêtre',
                  color: const Color(0xFFF97316),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter pour dessiner le plan
class FloorPlanPainter extends CustomPainter {
  final List<Room> rooms;
  final List<Sensor> sensors;
  final String? selectedRoomId;
  final String? activeSensorId;

  FloorPlanPainter({
    required this.rooms,
    required this.sensors,
    this.selectedRoomId,
    this.activeSensorId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Échelle (pixels per meter)
    const scale = 40.0;

    // Dessiner les pièces
    for (final room in rooms) {
      final paint = Paint()
        ..color = room.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = room.color.withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Si sélectionnée, ajouter une bordure plus épaisse
      if (room.id == selectedRoomId) {
        final selectedPaint = Paint()
          ..color = AppTheme.accentBlue
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

        final rect = Rect.fromCenter(
          center: room.position,
          width: room.size.width,
          height: room.size.height,
        );

        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, selectedPaint);
      } else {
        final rect = Rect.fromCenter(
          center: room.position,
          width: room.size.width,
          height: room.size.height,
        );

        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
      }

      // Nom de la pièce
      final textPainter = TextPainter(
        text: TextSpan(
          text: room.name,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          room.position.dx - (textPainter.width / 2),
          room.position.dy - (textPainter.height / 2),
        ),
      );
    }

    // Dessiner les capteurs
    for (final sensor in sensors) {
      // Si c'est le capteur actif, afficher le glow effect
      if (sensor.id == activeSensorId) {
        // Glow effect concentriques
        final glowPaint = Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(sensor.position, 20, glowPaint);

        final glowPaint2 = Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(sensor.position, 30, glowPaint2);
      }

      // Cercle du capteur
      final paint = Paint()
        ..color = sensor.id == activeSensorId
            ? const Color(0xFFDC2626)  // Plus sombre si actif
            : const Color(0xFFEF4444)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(sensor.position, sensor.id == activeSensorId ? 12 : 8, paint);

      // Bordure
      final borderPaint = Paint()
        ..color = sensor.id == activeSensorId
            ? const Color(0xFF991B1B)
            : const Color(0xFFDC2626)
        ..strokeWidth = sensor.id == activeSensorId ? 3 : 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(sensor.position, sensor.id == activeSensorId ? 12 : 8, borderPaint);

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: sensor.label,
          style: TextStyle(
            color: sensor.id == activeSensorId
                ? const Color(0xFFDC2626)
                : const Color(0xFFEF4444),
            fontSize: sensor.id == activeSensorId ? 10 : 9,
            fontWeight: sensor.id == activeSensorId ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          sensor.position.dx + 12,
          sensor.position.dy - 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) =>
      oldDelegate.selectedRoomId != selectedRoomId ||
      oldDelegate.activeSensorId != activeSensorId;
}

