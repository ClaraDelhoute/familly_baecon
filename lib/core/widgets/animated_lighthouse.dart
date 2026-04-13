import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedLighthouse extends StatefulWidget {
  final Color color;
  final double size;

  const AnimatedLighthouse({super.key, required this.color, this.size = 220});

  @override
  State<AnimatedLighthouse> createState() => _AnimatedLighthouseState();
}

class _AnimatedLighthouseState extends State<AnimatedLighthouse>
    with TickerProviderStateMixin {
  late final AnimationController _sweep;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_sweep, _pulse]),
          builder: (context, _) {
            final pulse = 0.92 + (_pulse.value * 0.12);
            final sweep = math.sin(_sweep.value * 2 * math.pi); // -1..1
            final angle = sweep * 0.46; // horizontal sweep
            final facing =
                0.55 + (0.45 * (1 - sweep.abs())); // stronger near center
            final nearAlpha = 0.18 + (0.32 * facing);
            final farAlpha = 0.08 + (0.16 * facing);
            final svgSize = widget.size * pulse;
            final svgTop = (widget.size - svgSize) / 2;
            final sourceX = widget.size * 0.5; // viewBox cx=50
            final sourceY = svgTop + (svgSize * 0.22); // viewBox cy=22
            final beamHalfW = widget.size * 0.66;
            final beamH = widget.size * 0.26;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Single cone beam from lighthouse source sweeping left<->right
                Positioned(
                  left: sourceX,
                  top: sourceY - (beamH / 2),
                  child: Transform.rotate(
                    alignment: Alignment.centerLeft,
                    angle: angle,
                    child: _beamCone(
                      alphaNear: nearAlpha,
                      alphaFar: farAlpha,
                      spread: 1.0,
                      width: beamHalfW,
                      height: beamH,
                    ),
                  ),
                ),
                Container(
                  width: widget.size * (0.24 + (_pulse.value * 0.06)),
                  height: widget.size * (0.24 + (_pulse.value * 0.06)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withValues(
                          alpha: 0.30 + (_pulse.value * 0.08),
                        ),
                        widget.color.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/animations/lighthouse_beacon.svg',
                  width: widget.size * pulse,
                  height: widget.size * pulse,
                  colorFilter: ColorFilter.mode(
                    widget.color,
                    BlendMode.srcATop,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _beamCone({
    required double alphaNear,
    required double alphaFar,
    required double spread,
    required double width,
    required double height,
  }) {
    return ClipPath(
      clipper: _BeamClipperCone(spread: spread),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              widget.color.withValues(alpha: alphaNear),
              widget.color.withValues(alpha: alphaNear * 0.55),
              widget.color.withValues(alpha: alphaFar),
              Colors.transparent,
            ],
            stops: const [0.0, 0.32, 0.72, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BeamClipperCone extends CustomClipper<Path> {
  final double spread;

  const _BeamClipperCone({this.spread = 1.0});

  @override
  Path getClip(Size size) {
    final top = (size.height * 0.5) - (size.height * 0.28 * spread);
    final bottom = (size.height * 0.5) + (size.height * 0.28 * spread);
    return Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width, top)
      ..lineTo(size.width, bottom)
      ..close();
  }

  @override
  bool shouldReclip(covariant _BeamClipperCone oldClipper) {
    return oldClipper.spread != spread;
  }
}
