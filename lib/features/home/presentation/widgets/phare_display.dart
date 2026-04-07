import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/home/presentation/widgets/phare_indicator.dart';
import 'dart:math' as Math;
import 'dart:ui' as ui;

/// Widget affichant le phare miniaturisé avec les faisceaux de lumière
class PhareDisplay extends StatefulWidget {
  final List<Activity> expected;
  final List<Activity> observed;

  const PhareDisplay({
    super.key,
    required this.expected,
    required this.observed,
  });

  @override
  State<PhareDisplay> createState() => _PhareDisplayState();
}

class _PhareDisplayState extends State<PhareDisplay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  ActivityStatus _overallStatus() {
    var worst = ActivityStatus.ok;
    for (final exp in widget.expected) {
      Activity? match;
      for (final obs in widget.observed) {
        if (obs.room == exp.room && obs.type == exp.type) {
          match = obs;
          break;
        }
      }
      if (match == null) {
        for (final obs in widget.observed) {
          if (obs.room == exp.room) {
            match = obs;
            break;
          }
        }
      }
      if (match == null) {
        for (final obs in widget.observed) {
          if (obs.type == exp.type) {
            match = obs;
            break;
          }
        }
      }

      final status = _statusFor(exp, match);
      if (status == ActivityStatus.critical) {
        return ActivityStatus.critical;
      }
      if (status == ActivityStatus.warning) {
        worst = ActivityStatus.warning;
      }
    }
    return worst;
  }

  ActivityStatus _statusFor(Activity exp, Activity? obs) {
    if (obs == null) return ActivityStatus.warning;
    final sameRoom = exp.room == obs.room;
    if (!sameRoom) return ActivityStatus.critical;
    final expectedDuration = exp.endAt?.difference(exp.startAt).inMinutes ?? 0;
    if (expectedDuration == 0) return ActivityStatus.critical;
    final overlapStart = exp.startAt.isAfter(obs.startAt) ? exp.startAt : obs.startAt;
    final overlapEnd = (exp.endAt ?? exp.startAt).isBefore(obs.endAt ?? obs.startAt)
        ? (exp.endAt ?? exp.startAt)
        : (obs.endAt ?? obs.startAt);
    final overlap = overlapEnd.isAfter(overlapStart)
        ? overlapEnd.difference(overlapStart).inMinutes
        : 0;
    final ratio = overlap / expectedDuration;
    if (ratio >= 0.85) return ActivityStatus.ok;
    if (ratio >= 0.50) return ActivityStatus.warning;
    return ActivityStatus.critical;
  }

  Color _colorFor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ok:
        return const Color(0xFF10B981);
      case ActivityStatus.warning:
        return const Color(0xFFF59E0B);
      case ActivityStatus.critical:
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _overallStatus();
    final color = _colorFor(status);

    return Center(
      child: SizedBox(
        width: 180,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Aura extérieure pulsante - PLUS VISIBLE
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 140 + (_pulseController.value * 35),
                  height: 140 + (_pulseController.value * 35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.3 - (_pulseController.value * 0.12)),
                        color.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Faisceaux de lumière rotatifs
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: LightBeamsPainter(
                    color: color,
                    rotation: _rotationController.value * 2 * Math.pi,
                    scale: 1.3,
                  ),
                  size: const Size(180, 240),
                );
              },
            ),

            // Phare - Structure 3D MAGNIFIQUE
            Positioned(
              bottom: 0,
              child: Column(
                children: [
                  // Chambre de lumière
                  Container(
                    width: 72,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2B47),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: const Color(0xFF1E4A70),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Lumière pulsante
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Center(
                              child: Container(
                                width: 48 + (_pulseController.value * 10),
                                height: 32 + (_pulseController.value * 8),
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      color,
                                      color.withOpacity(0.5 - (_pulseController.value * 0.15)),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(1),
                                      blurRadius: 18 + (_pulseController.value * 14),
                                      spreadRadius: 2 + (_pulseController.value * 5),
                                    ),
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 35 + (_pulseController.value * 18),
                                      spreadRadius: 4 + (_pulseController.value * 8),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Reflet vitre
                        Positioned(
                          top: 3,
                          left: 6,
                          child: Container(
                            width: 60,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tour principale avec fenêtres
                  Container(
                    width: 68,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2d3d5c),
                          const Color(0xFF1e293b),
                        ],
                      ),
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey.shade700,
                          width: 1.5,
                        ),
                        right: BorderSide(
                          color: Colors.grey.shade700,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWindow(5),
                        _buildWindow(5),
                      ],
                    ),
                  ),
                  // Base du phare
                  Container(
                    width: 60,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0f172a),
                          const Color(0xFF030712),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.grey.shade800,
                        width: 1.5,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWindow(4),
                        Container(
                          width: 6,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.brown.shade800,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        _buildWindow(4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF6BA3D4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6BA3D4).withOpacity(0.4),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}

/// CustomPainter pour les faisceaux de lumière
class LightBeamsPainter extends CustomPainter {
  final Color color;
  final double rotation;
  final double scale;

  LightBeamsPainter({
    required this.color,
    required this.rotation,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2.5);
    const beamCount = 3;

    for (int i = 0; i < beamCount; i++) {
      final angle = (rotation + (i * (2 * Math.pi / beamCount)));
      final beamLength = 120 * scale;

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          center,
          center +
              Offset(
                Math.cos(angle) * beamLength,
                Math.sin(angle) * beamLength,
              ),
          [
            color.withOpacity(0.7),
            color.withOpacity(0.3),
            color.withOpacity(0),
          ],
          [0.0, 0.5, 1.0],
        )
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + Math.cos(angle - 0.35) * beamLength,
          center.dy + Math.sin(angle - 0.35) * beamLength,
        )
        ..lineTo(
          center.dx + Math.cos(angle + 0.35) * beamLength,
          center.dy + Math.sin(angle + 0.35) * beamLength,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(LightBeamsPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.color != color ||
      oldDelegate.scale != scale;
}

