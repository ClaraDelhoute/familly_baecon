// filepath: c:\Users\clara\StudioProjects\familly_baecon\lib\features\home\presentation\widgets\phare_indicator.dart
import 'package:flutter/material.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';
import 'package:familly_baecon/features/home/domain/entities/anomaly_explainer.dart';
import 'package:familly_baecon/core/services/app_badge_service.dart';
import 'dart:math' as Math;
import 'dart:ui' as ui;

enum ActivityStatus { ok, warning, critical }

class PhareIndicator extends StatefulWidget {
  final List<Activity> expected;
  final List<Activity> observed;
  final BuildContext? parentContext;

  const PhareIndicator({
    super.key,
    required this.expected,
    required this.observed,
    this.parentContext,
  });

  @override
  State<PhareIndicator> createState() => _PhareIndicatorState();
}

class _PhareIndicatorState extends State<PhareIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  bool _hasShownModal = false;
  ActivityStatus _lastStatus = ActivityStatus.ok;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = _overallStatus();
      _updateAppBadge(status);

      // Afficher la modal seulement si le statut change vers CRITICAL et on ne l'a pas déjà affichée
      if (status == ActivityStatus.critical && !_hasShownModal) {
        _hasShownModal = true;
        _lastStatus = status;
        if (mounted) {
          _showPhareModal(context);
        }
      } else if (status != ActivityStatus.critical) {
        // Réinitialiser le flag si le statut n'est plus critique
        _hasShownModal = false;
      }
      _lastStatus = status;
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
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
    if (ratio >= 0.85) return ActivityStatus.ok;  // 85% pour vert
    if (ratio >= 0.50) return ActivityStatus.warning;  // 50-85% pour orange
    return ActivityStatus.critical;  // <50% pour rouge
  }

  ActivityStatus _overallStatus() {
    var worst = ActivityStatus.ok;
    for (final exp in widget.expected) {
      Activity? match;
      // Chercher d'abord un match EXACT (pièce ET type)
      for (final obs in widget.observed) {
        if (obs.room == exp.room && obs.type == exp.type) {
          match = obs;
          break;
        }
      }
      // Si pas de match exact, chercher par pièce au moins
      if (match == null) {
        for (final obs in widget.observed) {
          if (obs.room == exp.room) {
            match = obs;
            break;
          }
        }
      }
      // Si toujours pas de match, chercher par type
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

  String _labelFor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ok:
        return 'Tout va bien';
      case ActivityStatus.warning:
        return 'Attention';
      case ActivityStatus.critical:
      default:
        return 'Nous avons une observation';
    }
  }

  String _descriptionFor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ok:
        return 'Les activités correspondent à la journée type';
      case ActivityStatus.warning:
        return 'Certaines activités diffèrent légèrement de la journée type';
      case ActivityStatus.critical:
      default:
        return 'Nous avons remarqué des écarts dans les activités. Consultez les détails pour comprendre';
    }
  }

  void _updateAppBadge(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ok:
        AppBadgeService.updateBadge('ok');
        break;
      case ActivityStatus.warning:
        AppBadgeService.updateBadge('warning');
        break;
      case ActivityStatus.critical:
        AppBadgeService.updateBadge('critical');
        break;
    }
  }

  void _showPhareModal(BuildContext context) {
    final status = _overallStatus();
    final color = _colorFor(status);
    final label = _labelFor(status);
    final description = _descriptionFor(status);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (BuildContext dialogContext) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.82,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PHARE MAGNIFIQUE
                    SizedBox(
                      width: 260,
                      height: 320,
                      child: Stack(
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
                                    child: LightBeamWidget(
                                      color: color,
                                      angle: -Math.pi / 2,
                                    ),
                                  ),
                                  // Faisceau 2
                                  Transform.rotate(
                                    angle: _rotationController.value * 2 * Math.pi,
                                    child: LightBeamWidget(
                                      color: color,
                                      angle: Math.pi / 6,
                                    ),
                                  ),
                                  // Faisceau 3
                                  Transform.rotate(
                                    angle: _rotationController.value * 2 * Math.pi,
                                    child: LightBeamWidget(
                                      color: color,
                                      angle: -Math.pi / 6,
                                    ),
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
                                    border: Border.all(
                                      color: const Color(0xFF1E4A70),
                                      width: 2,
                                    ),
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
                                                    color.withOpacity(0.6 - (_pulseController.value * 0.2)),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(25),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: color.withOpacity(0.9),
                                                    blurRadius: 25 + (_pulseController.value * 20),
                                                    spreadRadius: 2 + (_pulseController.value * 8),
                                                  ),
                                                  BoxShadow(
                                                    color: color.withOpacity(0.4),
                                                    blurRadius: 50 + (_pulseController.value * 25),
                                                    spreadRadius: 5 + (_pulseController.value * 10),
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

                                // Tour principale
                                Container(
                                  width: 80,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade50,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 12,
                                        offset: const Offset(3, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Fenêtres supérieures
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildWindow(size: 8),
                                          const SizedBox(width: 24),
                                          _buildWindow(size: 8),
                                        ],
                                      ),
                                      // Porte
                                      Container(
                                        width: 14,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B6F47),
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.25),
                                              blurRadius: 4,
                                              offset: const Offset(1, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Fenêtre inférieure
                                      _buildWindow(size: 8),
                                    ],
                                  ),
                                ),

                                // Base du phare
                                Container(
                                  width: 75,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF1E4A70),
                                        const Color(0xFF0F2B47),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.4),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Titre avec couleur dynamique
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    // Bouttons d'action
                    Row(
                      children: [
                        // Bouton Fermer
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Fermer',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Bouton Voir l'anomalie
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              // Naviguer vers les détails de l'anomalie
                              // Pour l'instant on affiche le bottom sheet
                              _showAnomalyDetailsSheet(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 6,
                              shadowColor: color.withOpacity(0.4),
                            ),
                            child: const Text(
                              'Voir l\'anomalie',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAnomalyDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec bouton fermer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Détails des anomalies',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey.shade700,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Afficher seulement la première anomalie (pas OK)
                Builder(
                  builder: (context) {
                    // Chercher la première anomalie
                    for (int index = 0; index < widget.expected.length; index++) {
                      final exp = widget.expected[index];
                      Activity? match;
                      // Chercher d'abord un match EXACT (pièce ET type)
                      for (final obs in widget.observed) {
                        if (obs.room == exp.room && obs.type == exp.type) {
                          match = obs;
                          break;
                        }
                      }
                      // Si pas de match exact, chercher par pièce au moins
                      if (match == null) {
                        for (final obs in widget.observed) {
                          if (obs.room == exp.room) {
                            match = obs;
                            break;
                          }
                        }
                      }
                      // Si toujours pas de match, chercher par type
                      if (match == null) {
                        for (final obs in widget.observed) {
                          if (obs.type == exp.type) {
                            match = obs;
                            break;
                          }
                        }
                      }

                      final isOk = match != null && exp.room == match.room;

                      // Si pas ok, afficher cette anomalie uniquement
                      if (!isOk) {
                        final color = const Color(0xFFEF4444);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            border: Border.all(color: color.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      exp.type,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '❌',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Prévu: ${exp.startAt.hour.toString().padLeft(2, '0')}:${exp.startAt.minute.toString().padLeft(2, '0')} - ${exp.endAt!.hour.toString().padLeft(2, '0')}:${exp.endAt!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (match != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Observé: ${match.startAt.hour.toString().padLeft(2, '0')}:${match.startAt.minute.toString().padLeft(2, '0')} - ${match.endAt?.hour.toString().padLeft(2, '0') ?? '--'}:${match.endAt?.minute.toString().padLeft(2, '0') ?? '--'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                    }

                    // Si tout est ok
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 64,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tout va bien !',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Les activités correspondent parfaitement',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWindow({double size = 7}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF6BA3D4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6BA3D4).withOpacity(0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Widget de faisceau de lumière
class LightBeamWidget extends StatelessWidget {
  final Color color;
  final double angle;

  const LightBeamWidget({
    super.key,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(280, 320),
      painter: LightBeamPainter(
        color: color,
        angle: angle,
      ),
    );
  }
}

/// Painter pour les faisceaux de lumière réalistes
class LightBeamPainter extends CustomPainter {
  final Color color;
  final double angle;

  LightBeamPainter({required this.color, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.55;

    final dirX = Math.cos(angle);
    final dirY = Math.sin(angle);

    final beamLength = 180.0;
    final beamEndX = centerX + dirX * beamLength;
    final beamEndY = centerY + dirY * beamLength;

    final path = Path();

    final sourceWidth = 18.0;
    final sourceLeft = Offset(
      centerX - sourceWidth * (-dirY),
      centerY - sourceWidth * dirX,
    );
    final sourceRight = Offset(
      centerX + sourceWidth * (-dirY),
      centerY + sourceWidth * dirX,
    );

    final endWidth = 75.0;
    final endLeft = Offset(
      beamEndX - endWidth * (-dirY),
      beamEndY - endWidth * dirX,
    );
    final endRight = Offset(
      beamEndX + endWidth * (-dirY),
      beamEndY + endWidth * dirX,
    );

    path.moveTo(sourceLeft.dx, sourceLeft.dy);
    path.lineTo(sourceRight.dx, sourceRight.dy);
    path.lineTo(endRight.dx, endRight.dy);
    path.lineTo(endLeft.dx, endLeft.dy);
    path.close();

    final paint = Paint();
    final shader = ui.Gradient.linear(
      Offset(centerX, centerY),
      Offset(beamEndX, beamEndY),
      [
        color.withOpacity(0.85),
        color.withOpacity(0.45),
        color.withOpacity(0.12),
        Colors.transparent,
      ],
      [0.0, 0.25, 0.65, 1.0],
    );

    paint.shader = shader;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LightBeamPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.angle != angle;
}

/// Indicateur discret pour la home page
class PhareStatusIndicator extends StatelessWidget {
  final List<Activity> expected;
  final List<Activity> observed;
  final VoidCallback? onTap;

  const PhareStatusIndicator({
    super.key,
    required this.expected,
    required this.observed,
    this.onTap,
  });

  ActivityStatus _overallStatus() {
    var worst = ActivityStatus.ok;
    for (final exp in expected) {
      Activity? match;
      // Chercher d'abord un match EXACT (pièce ET type)
      for (final obs in observed) {
        if (obs.room == exp.room && obs.type == exp.type) {
          match = obs;
          break;
        }
      }
      // Si pas de match exact, chercher par pièce au moins
      if (match == null) {
        for (final obs in observed) {
          if (obs.room == exp.room) {
            match = obs;
            break;
          }
        }
      }
      // Si toujours pas de match, chercher par type
      if (match == null) {
        for (final obs in observed) {
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
    if (ratio >= 0.85) return ActivityStatus.ok;  // 85% pour vert
    if (ratio >= 0.50) return ActivityStatus.warning;  // 50-85% pour orange
    return ActivityStatus.critical;  // <50% pour rouge
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

  String _labelFor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ok:
        return 'Tout va bien';
      case ActivityStatus.warning:
        return 'Anomalie légère';
      case ActivityStatus.critical:
      default:
        return 'Anomalie grave';
    }
  }

  String _getDescriptionForStatus(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ok:
        return 'Les activités correspondent parfaitement';
      case ActivityStatus.warning:
        return 'Quelques écarts détectés';
      case ActivityStatus.critical:
      default:
        return 'Des anomalies importantes';
    }
  }

  IconData _getIconForStatus(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.ok:
        return Icons.check_circle_rounded;
      case ActivityStatus.warning:
        return Icons.warning_rounded;
      case ActivityStatus.critical:
      default:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculer le VRAI statut en utilisant les données passées en paramètre
    final status = _overallStatus();
    final color = _colorFor(status);
    final label = _labelFor(status);
    final description = _getDescriptionForStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Cercle indicateur avec icône
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              _getIconForStatus(status),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          // Contenu texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Flèche
          Icon(
            Icons.arrow_forward_rounded,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}
