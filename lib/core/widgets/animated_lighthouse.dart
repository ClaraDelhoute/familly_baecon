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
      duration: const Duration(milliseconds: 3600),
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
            // theta : angle de rotation 0..2π (axe vertical du phare).
            final theta = _sweep.value * 2 * math.pi;
            // cos(theta) : +1 = faisceau face caméra, -1 = derrière, 0 = de profil.
            final facing = math.cos(theta);
            // Visibilité : pic quand le faisceau nous fait face, nul derrière.
            final visibility = ((facing + 1) / 2).clamp(0.0, 1.0);
            // Compression latérale par perspective : profil = ligne, face = pleine largeur.
            final lateralScale = facing.abs().clamp(0.05, 1.0);
            // Le faisceau bascule à 180° (passe derrière le phare).
            final beamBehind = facing < 0;

            final svgSize = widget.size * pulse;
            final svgTop = (widget.size - svgSize) / 2;
            final sourceX = widget.size * 0.5;
            final sourceY = svgTop + (svgSize * 0.22);
            final beamLen = widget.size * 0.95;
            final beamH = widget.size * 0.55;

            // Halo de la lampe : pulse léger + flash quand le faisceau nous fait face.
            final lampGlow = 0.35 + (visibility * 0.55) + (_pulse.value * 0.08);

            Widget beam = Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..scaleByDouble(1.0, lateralScale, 1.0, 1.0),
              child: _beamCone(
                alphaNear: 0.55,
                alphaFar: 0.0,
                width: beamLen,
                height: beamH,
              ),
            );

            // Deux instances : l'une face caméra, l'autre dos (atténuée et derrière le phare).
            final frontBeam = Positioned(
              left: sourceX,
              top: sourceY - (beamH / 2),
              child: beamBehind
                  ? const SizedBox.shrink()
                  : beam,
            );
            final backBeam = Positioned(
              left: sourceX - beamLen,
              top: sourceY - (beamH / 2),
              child: beamBehind
                  ? Transform(
                      alignment: Alignment.centerRight,
                      transform: Matrix4.identity()
                        ..scaleByDouble(1.0, lateralScale, 1.0, 1.0),
                      child: _beamCone(
                        alphaNear: 0.55,
                        alphaFar: 0.0,
                        width: beamLen,
                        height: beamH,
                        mirrored: true,
                      ),
                    )
                  : const SizedBox.shrink(),
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                // Faisceau derrière le phare (atténué, passe à l'arrière).
                if (beamBehind) backBeam,
                // SVG du phare au milieu : occulte le faisceau quand il est derrière.
                SvgPicture.asset(
                  'assets/animations/lighthouse_beacon.svg',
                  width: widget.size * pulse,
                  height: widget.size * pulse,
                  colorFilter: ColorFilter.mode(
                    widget.color,
                    BlendMode.srcATop,
                  ),
                ),
                // Faisceau devant le phare (visible).
                if (!beamBehind) frontBeam,
                // Halo lumineux de la lampe : brille fort quand face caméra.
                Positioned(
                  left: sourceX - (widget.size * 0.16),
                  top: sourceY - (widget.size * 0.16),
                  child: IgnorePointer(
                    child: Container(
                      width: widget.size * 0.32,
                      height: widget.size * 0.32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.color.withValues(alpha: lampGlow),
                            widget.color.withValues(alpha: lampGlow * 0.35),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
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
    required double width,
    required double height,
    double spread = 1.0,
    bool mirrored = false,
  }) {
    return ClipPath(
      clipper: _BeamClipperCone(spread: spread, mirrored: mirrored),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: mirrored ? Alignment.centerRight : Alignment.centerLeft,
            end: mirrored ? Alignment.centerLeft : Alignment.centerRight,
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
  final bool mirrored;

  const _BeamClipperCone({this.spread = 1.0, this.mirrored = false});

  @override
  Path getClip(Size size) {
    final top = (size.height * 0.5) - (size.height * 0.28 * spread);
    final bottom = (size.height * 0.5) + (size.height * 0.28 * spread);
    if (mirrored) {
      // Pointe à droite (vers la source), base large à gauche.
      return Path()
        ..moveTo(size.width, size.height * 0.5)
        ..lineTo(0, top)
        ..lineTo(0, bottom)
        ..close();
    }
    return Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width, top)
      ..lineTo(size.width, bottom)
      ..close();
  }

  @override
  bool shouldReclip(covariant _BeamClipperCone oldClipper) {
    return oldClipper.spread != spread || oldClipper.mirrored != mirrored;
  }
}
