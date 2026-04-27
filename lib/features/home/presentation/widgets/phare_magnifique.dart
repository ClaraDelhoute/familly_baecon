import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/home/presentation/widgets/phare_indicator.dart';
import 'dart:math' as Math;
import 'package:familly_baecon/core/widgets/animated_lighthouse.dart';

/// Widget affichant le grand phare magnifique de la modal pour la home page
class PhareMagnifique extends StatefulWidget {
  final List<Activity> expected;
  final List<Activity> observed;
  final bool hasActiveAnomaly;
  final String? alertSeverity;
  final bool forceGyrophare;
  final double width;
  final double height;
  final double lighthouseSize;

  const PhareMagnifique({
    super.key,
    required this.expected,
    required this.observed,
    this.hasActiveAnomaly = false,
    this.alertSeverity,
    this.forceGyrophare = false,
    this.width = 260,
    this.height = 210,
    this.lighthouseSize = 190,
  });

  @override
  State<PhareMagnifique> createState() => _PhareMagnifiqueState();
}

class _PhareMagnifiqueState extends State<PhareMagnifique>
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
    if (!widget.hasActiveAnomaly) {
      return ActivityStatus.ok;
    }
    return ActivityStatus.critical;
  }

  ActivityStatus _statusFor(Activity exp, Activity? obs) {
    if (obs == null) return ActivityStatus.warning;
    final sameRoom = exp.room == obs.room;
    if (!sameRoom) return ActivityStatus.critical;
    final expectedDuration = exp.endAt?.difference(exp.startAt).inMinutes ?? 0;
    if (expectedDuration == 0) return ActivityStatus.critical;
    final overlapStart = exp.startAt.isAfter(obs.startAt)
        ? exp.startAt
        : obs.startAt;
    final overlapEnd =
        (exp.endAt ?? exp.startAt).isBefore(obs.endAt ?? obs.startAt)
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
    final severity = widget.alertSeverity?.toLowerCase();
    if (severity == 'high') {
      return const Color(0xFFEF4444);
    }
    if (severity == 'medium') {
      return const Color(0xFFEF4444);
    }

    switch (status) {
      case ActivityStatus.ok:
        return const Color(0xFF10B981);
      case ActivityStatus.warning:
        return const Color(0xFFEF4444);
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
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Center(
              child: AnimatedLighthouse(
                color: color,
                size: widget.lighthouseSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyLighthouse(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Aura extérieure pulsante
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 200 + (_pulseController.value * 40),
              height: 200 + (_pulseController.value * 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.25 - (_pulseController.value * 0.1)),
                    color.withOpacity(0.1),
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
            return Stack(
              alignment: Alignment.center,
              children: [
                // Faisceau 1
                Transform.rotate(
                  angle: _rotationController.value * 2 * Math.pi,
                  child: LightBeamWidget(color: color, angle: -Math.pi / 2),
                ),
                // Faisceau 2
                Transform.rotate(
                  angle: _rotationController.value * 2 * Math.pi,
                  child: LightBeamWidget(color: color, angle: Math.pi / 6),
                ),
                // Faisceau 3
                Transform.rotate(
                  angle: _rotationController.value * 2 * Math.pi,
                  child: LightBeamWidget(color: color, angle: -Math.pi / 6),
                ),
              ],
            );
          },
        ),

        // Phare - Structure 3D
        Positioned(
          bottom: 0,
          child: Column(
            children: [
              // Chambre de lumière
              Container(
                width: 85,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2B47),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  border: Border.all(color: const Color(0xFF1E4A70), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                            width: 55 + (_pulseController.value * 12),
                            height: 40 + (_pulseController.value * 10),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  color,
                                  color.withOpacity(
                                    0.6 - (_pulseController.value * 0.2),
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.9),
                                  blurRadius:
                                      25 + (_pulseController.value * 20),
                                  spreadRadius:
                                      2 + (_pulseController.value * 8),
                                ),
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius:
                                      50 + (_pulseController.value * 25),
                                  spreadRadius:
                                      5 + (_pulseController.value * 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Reflet vitre
                    Positioned(
                      top: 4,
                      child: Container(
                        width: 70,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tour principale
              Container(
                width: 82,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  border: Border.all(color: Colors.grey.shade700, width: 2),
                ),
              ),
              // Base du phare
              Container(
                width: 75,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0f172a),
                  border: Border.all(color: Colors.grey.shade800, width: 2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
