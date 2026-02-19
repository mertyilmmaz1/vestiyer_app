import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/product/theme/app_colors.dart';
import '../core/product/theme/app_typography.dart';
import 'dart:math' as math;

/// A guide widget that shows an animation for a plain background.
class PlainBackgroundGuide extends StatefulWidget {
  const PlainBackgroundGuide({super.key});

  @override
  State<PlainBackgroundGuide> createState() => _PlainBackgroundGuideState();
}

class _PlainBackgroundGuideState extends State<PlainBackgroundGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.1, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 0.5),
            color: AppColors.softBackground,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grid background simulating "noise/clutter" that fades away
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(120, 120),
                    painter: _ClutterPainter(opacity: _fadeAnimation.value),
                  );
                },
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedCircle, // Changed from WallClock
                size: 40,
                color: AppColors.textPrimary,
              ),
              Positioned(
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'SADE ARKA PLAN',
                    style: AppTypography.label.copyWith(
                      color: AppColors.background,
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
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

/// A guide widget that shows an animation for fitting the whole clothing.
class ClothingFittingGuide extends StatefulWidget {
  const ClothingFittingGuide({super.key});

  @override
  State<ClothingFittingGuide> createState() => _ClothingFittingGuideState();
}

class _ClothingFittingGuideState extends State<ClothingFittingGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.7, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 0.5),
            color: AppColors.softBackground,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedTShirt,
                          size: 40,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'TAMAMINI ÇEKİN',
                    style: AppTypography.label.copyWith(
                      color: AppColors.background,
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
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

/// A guide widget that shows an animation for good lighting.
class LightingGuide extends StatefulWidget {
  const LightingGuide({super.key});

  @override
  State<LightingGuide> createState() => _LightingGuideState();
}

class _LightingGuideState extends State<LightingGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 0.5),
            color: AppColors.softBackground,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSun03,
                size: 40,
                color: AppColors.textPrimary,
              ),
              AnimatedBuilder(
                animation: _shineAnimation,
                builder: (context, child) {
                  return Positioned.fill(
                    child: ClipRect(
                      child: Transform.rotate(
                        angle: -math.pi / 4,
                        child: FractionallySizedBox(
                          widthFactor: 2.0,
                          heightFactor: 0.2,
                          alignment: Alignment(_shineAnimation.value, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.4),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'YETERLİ IŞIK',
                    style: AppTypography.label.copyWith(
                      color: AppColors.background,
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
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

class _ClutterPainter extends CustomPainter {
  final double opacity;
  _ClutterPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: opacity * 0.2)
      ..strokeWidth = 0.5;

    // Draw some random squiggly lines to represent clutter
    final random = math.Random(42);
    for (int i = 0; i < 15; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = random.nextDouble() * size.width;
      final endY = random.nextDouble() * size.height;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClutterPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
