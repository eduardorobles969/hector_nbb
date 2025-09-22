import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    Timer(const Duration(milliseconds: 3400), () {
      if (mounted) {
        context.go('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).animate(_scaleAnimation),
            child: _ForgeEmblem(animation: _controller),
          ),
        ),
      ),
    );
  }
}

class _ForgeEmblem extends StatelessWidget {
  const _ForgeEmblem({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final sweepRadians = (animation.value * 360) * pi / 180;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x33FFD54F), Colors.transparent],
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size.square(220),
                  painter: _ArcPainter(progress: sweepRadians),
                ),
                ShaderMask(
                  shaderCallback: (rect) {
                    final offset = animation.value.clamp(0.0, 1.0);
                    return LinearGradient(
                      colors: [
                        Colors.white.withAlpha(0),
                        Colors.white.withAlpha(200),
                        Colors.white.withAlpha(0),
                      ],
                      stops: [
                        (offset - 0.2).clamp(0.0, 1.0),
                        offset,
                        (offset + 0.2).clamp(0.0, 1.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFB300),
                        width: 3,
                      ),
                      color: Colors.black,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 18),
                          blurRadius: 36,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/HectorNBB.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 38),
            const _ForgedTitle(),
            const SizedBox(height: 14),
            const Text(
              'Forja tu destino. Mantente indomable.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 0.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawArc(rect.deflate(8), -0.9, progress, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ForgedTitle extends StatelessWidget {
  const _ForgedTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'NEVER BE BROKEN',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.6
                  ..color = Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'NEVER BE BROKEN',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: Color(0xFFF5D580),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFFFFE082)],
            ),
          ),
        ),
      ],
    );
  }
}
