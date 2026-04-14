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
class FloorPlanWidget extends StatefulWidget {
  final List<Room> rooms;
  final List<Sensor> sensors;
  final String? selectedRoomId;
  final String? activeSensorId;
  final Function(String roomId)? onRoomTap;
  final double height;
  final bool showHeader;
  final bool showLegend;
  final bool frameless;

  const FloorPlanWidget({
    super.key,
    required this.rooms,
    required this.sensors,
    this.selectedRoomId,
    this.activeSensorId,
    this.onRoomTap,
    this.height = 300,
    this.showHeader = true,
    this.showLegend = true,
    this.frameless = false,
  });

  @override
  State<FloorPlanWidget> createState() => _FloorPlanWidgetState();
}

class _FloorPlanWidgetState extends State<FloorPlanWidget> {
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomBy(double factor) {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(1.0, 4.0);
    final scale = target / current;
    final next = Matrix4.copy(_transformationController.value)
      ..scale(scale, scale, 1);
    _transformationController.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconSize = Theme.of(context).iconTheme.size ?? 24;

    final core = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppTheme.accentBlue,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              Text(
                'Plan du logement',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (widget.height.isFinite)
          SizedBox(height: widget.height, child: _buildPlanCanvas())
        else
          Expanded(child: _buildPlanCanvas()),
        if (widget.showLegend) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                icon: '🔴',
                label: 'Capteur actif',
                color: const Color(0xFFEF4444),
              ),
              _buildLegendItem(
                icon: '⚪',
                label: 'Capteur éteint',
                color: const Color(0xFF6B7280),
              ),
            ],
          ),
        ],
      ],
    );

    if (widget.frameless) {
      return core;
    }

    return Card(
      elevation: 3,
      shadowColor: AppTheme.accentBlue.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        child: core,
      ),
    );
  }

  Widget _buildPlanCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 300,
        );
        final transform = _PlanTransform.fit(
          widget.rooms,
          widget.sensors,
          size,
          padding: 6,
        );
        final canvas = SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
            painter: FloorPlanPainter(
              rooms: widget.rooms,
              sensors: widget.sensors,
              selectedRoomId: widget.selectedRoomId,
              activeSensorId: widget.activeSensorId,
              transform: transform,
            ),
          ),
        );

        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final scenePoint = _transformationController.toScene(
                  details.localPosition,
                );
                final originalPoint = transform.toOriginal(scenePoint);
                for (final room in widget.rooms) {
                  final rect = Rect.fromCenter(
                    center: room.position,
                    width: room.size.width,
                    height: room.size.height,
                  );
                  if (rect.contains(originalPoint)) {
                    widget.onRoomTap?.call(room.id);
                    break;
                  }
                }
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                constrained: false,
                panEnabled: true,
                scaleEnabled: true,
                child: canvas,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Zoom -',
                      onPressed: () => _zoomBy(1 / 1.2),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: 'Zoom +',
                      onPressed: () => _zoomBy(1.2),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
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
  final _PlanTransform transform;

  FloorPlanPainter({
    required this.rooms,
    required this.sensors,
    required this.transform,
    this.selectedRoomId,
    this.activeSensorId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner les pièces
    for (final room in rooms) {
      final paint = Paint()
        ..color = room.color
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      // Si sélectionnée, ajouter une bordure plus épaisse
      if (room.id == selectedRoomId) {
        final selectedPaint = Paint()
          ..color = AppTheme.accentBlue
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

        final rect = transform.transformRect(
          Rect.fromCenter(
            center: room.position,
            width: room.size.width,
            height: room.size.height,
          ),
        );

        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, selectedPaint);
      } else {
        final rect = transform.transformRect(
          Rect.fromCenter(
            center: room.position,
            width: room.size.width,
            height: room.size.height,
          ),
        );

        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
      }

      // Nom de la pièce
      final textPainter = TextPainter(
        text: TextSpan(
          text: room.name,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: 10 * transform.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final roomCenter = transform.toCanvas(room.position);
      final labelOffset = Offset(
        roomCenter.dx - (textPainter.width / 2),
        roomCenter.dy - (textPainter.height / 2),
      );
      textPainter.paint(canvas, labelOffset);
    }

    // Dessiner les capteurs
    for (final sensor in sensors) {
      final isActive = sensor.id == activeSensorId;
      if (isActive) {
        // Glow effect concentriques
        final glowPaint = Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;

        final c = transform.toCanvas(sensor.position);
        canvas.drawCircle(c, 20 * transform.scale, glowPaint);

        final glowPaint2 = Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(c, 30 * transform.scale, glowPaint2);
      }

      // Cercle du capteur
      final paint = Paint()
        ..color = isActive ? const Color(0xFFDC2626) : const Color(0xFF4B5563)
        ..style = PaintingStyle.fill;

      final center = transform.toCanvas(sensor.position);
      canvas.drawCircle(center, (isActive ? 12 : 8) * transform.scale, paint);

      // Bordure
      final borderPaint = Paint()
        ..color = isActive ? const Color(0xFF991B1B) : const Color(0xFF9CA3AF)
        ..strokeWidth = isActive ? 3 : 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(
        center,
        (isActive ? 12 : 8) * transform.scale,
        borderPaint,
      );

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: sensor.label,
          style: TextStyle(
            color: isActive ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
            fontSize: (isActive ? 10 : 9) * transform.scale,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx + (12 * transform.scale),
          center.dy - (6 * transform.scale),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) =>
      oldDelegate.selectedRoomId != selectedRoomId ||
      oldDelegate.activeSensorId != activeSensorId ||
      oldDelegate.transform != transform;
}

class _PlanTransform {
  final double scale;
  final double dx;
  final double dy;

  const _PlanTransform({
    required this.scale,
    required this.dx,
    required this.dy,
  });

  factory _PlanTransform.fit(
    List<Room> rooms,
    List<Sensor> sensors,
    Size canvasSize, {
    double padding = 0,
  }) {
    final roomRects = rooms
        .map(
          (room) => Rect.fromCenter(
            center: room.position,
            width: room.size.width,
            height: room.size.height,
          ),
        )
        .toList();
    final sensorRects = sensors
        .map((sensor) => Rect.fromCircle(center: sensor.position, radius: 16))
        .toList();
    final all = [...roomRects, ...sensorRects];
    var bounds = all.first;
    for (final rect in all.skip(1)) {
      bounds = bounds.expandToInclude(rect);
    }

    final availableW = (canvasSize.width - (padding * 2)).clamp(
      1.0,
      double.infinity,
    );
    final availableH = (canvasSize.height - (padding * 2)).clamp(
      1.0,
      double.infinity,
    );
    final sx = availableW / bounds.width;
    final sy = availableH / bounds.height;
    final scale = sx < sy ? sx : sy;

    final scaledW = bounds.width * scale;
    final scaledH = bounds.height * scale;
    final dx = (canvasSize.width - scaledW) / 2 - (bounds.left * scale);
    final dy = (canvasSize.height - scaledH) / 2 - (bounds.top * scale);

    return _PlanTransform(scale: scale, dx: dx, dy: dy);
  }

  Offset toCanvas(Offset point) =>
      Offset((point.dx * scale) + dx, (point.dy * scale) + dy);

  Offset toOriginal(Offset point) =>
      Offset((point.dx - dx) / scale, (point.dy - dy) / scale);

  Rect transformRect(Rect rect) => Rect.fromLTWH(
    (rect.left * scale) + dx,
    (rect.top * scale) + dy,
    rect.width * scale,
    rect.height * scale,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PlanTransform &&
          runtimeType == other.runtimeType &&
          scale == other.scale &&
          dx == other.dx &&
          dy == other.dy;

  @override
  int get hashCode => Object.hash(scale, dx, dy);
}
