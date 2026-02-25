import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/product/theme/app_colors.dart';
import '../core/product/theme/app_typography.dart';

/// Base class for intro cards to ensure consistent styling
class _BaseIntroCard extends StatelessWidget {
  const _BaseIntroCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRect(child: child),
    );
  }
}

/// Simulated upload process animation
class IntroUploadCard extends StatefulWidget {
  const IntroUploadCard({super.key});

  @override
  State<IntroUploadCard> createState() => _IntroUploadCardState();
}

class _IntroUploadCardState extends State<IntroUploadCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _scanAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseIntroCard(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          // Animated clothing item placeholder
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    width: 140,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedTShirt,
                        size: 64,
                        color: AppColors.textPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Scanning effect
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.maxHeight * _scanAnimation.value -
                        (constraints.maxHeight / 2);
                    return Stack(
                      children: [
                        Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.0),
                                  AppColors.primary.withValues(alpha: 0.2),
                                  AppColors.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          // Floating "Uploaded" badge
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _scanAnimation.value;
              if (val < 0.8) return const SizedBox.shrink();
              return Positioned(
                bottom: 40,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                        color: AppColors.background,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).introCardUploaded,
                        style: AppTypography.label.copyWith(
                          color: AppColors.background,
                          fontSize: 10,
                          letterSpacing: 1.5,
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
    );
  }
}

/// Simulated combination mixing animation
class IntroCombineCard extends StatefulWidget {
  const IntroCombineCard({super.key});

  @override
  State<IntroCombineCard> createState() => _IntroCombineCardState();
}

class _IntroCombineCardState extends State<IntroCombineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _topSlide;
  late Animation<Offset> _bottomSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _topSlide =
        Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _bottomSlide =
        Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseIntroCard(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Item
              SlideTransition(
                position: _topSlide,
                child: Container(
                  width: 120,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTShirt,
                      size: 40,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              // Bottom Item
              SlideTransition(
                position: _bottomSlide,
                child: Container(
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedClothes,
                      size: 40,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // "Match" Indicator
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              if (val < 0.8) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textPrimary),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  size: 24,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Simulated analysis typing animation
class IntroAnalysisCard extends StatefulWidget {
  const IntroAnalysisCard({super.key});

  @override
  State<IntroAnalysisCard> createState() => _IntroAnalysisCardState();
}

class _IntroAnalysisCardState extends State<IntroAnalysisCard> {
  String _message = "";
  String _displayedText = "";
  Timer? _timer;
  bool _typingStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_typingStarted) {
      _typingStarted = true;
      _message = AppLocalizations.of(context).introCardAnalysisMessage;
      _startTyping();
    }
  }

  void _startTyping() {
    int index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < _message.length) {
        if (mounted) {
          setState(() {
            _displayedText = _message.substring(0, index + 1);
          });
        }
        index++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _displayedText = "";
            });
            _startTyping();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseIntroCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAiChat02,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).introCardAiAssistant,
                  style: AppTypography.label.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _displayedText,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textPrimary,
                fontFamily: 'Courier', // Monospace for typing effect
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    const gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
