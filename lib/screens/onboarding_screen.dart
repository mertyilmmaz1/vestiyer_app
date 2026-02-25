import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

/// Onboarding ekranı — Zara-editorial animasyonlu tanıtım.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.nextScreen});

  final Widget nextScreen;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;
  static const _prefsKey = 'onboarding_completed';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      EditorialPageRoute(page: widget.nextScreen),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.onboardingTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                      letterSpacing: 4.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: _completeOnboarding,
                    child: Text(
                      l10n.onboardingSkip,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Thin progress line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          right: index < _totalPages - 1 ? 4 : 0),
                      height: 1,
                      color: index <= _currentPage
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.12),
                    ),
                  );
                }),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _EditorialSlide(
                    active: _currentPage == 0,
                    number: '01',
                    title: l10n.onboardingSlide1Title,
                    subtitle: l10n.onboardingSlide1Subtitle,
                    demo: _UploadDemoWidget(active: _currentPage == 0),
                  ),
                  _EditorialSlide(
                    active: _currentPage == 1,
                    number: '02',
                    title: l10n.onboardingSlide2Title,
                    subtitle: l10n.onboardingSlide2Subtitle,
                    demo: _WardrobeGridDemoWidget(active: _currentPage == 1),
                  ),
                  _EditorialSlide(
                    active: _currentPage == 2,
                    number: '03',
                    title: l10n.onboardingSlide3Title,
                    subtitle: l10n.onboardingSlide3Subtitle,
                    demo: _AIStylistDemoWidget(active: _currentPage == 2),
                  ),
                  _EditorialSlide(
                    active: _currentPage == 3,
                    number: '04',
                    title: l10n.onboardingSlide4Title,
                    subtitle: l10n.onboardingSlide4Subtitle,
                    demo: _AIChatDemoWidget(active: _currentPage == 3),
                  ),
                ],
              ),
            ),
            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _totalPages - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < _totalPages - 1
                            ? l10n.onboardingNext
                            : l10n.onboardingStart,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 3.0,
                        ),
                      ),
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
}

// ─── Editorial Slide Layout ───
class _EditorialSlide extends StatefulWidget {
  const _EditorialSlide({
    required this.active,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.demo,
  });

  final bool active;
  final String number;
  final String title;
  final String subtitle;
  final Widget demo;

  @override
  State<_EditorialSlide> createState() => _EditorialSlideState();
}

class _EditorialSlideState extends State<_EditorialSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.active) {
      _playAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant _EditorialSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _playAnimation();
    }
  }

  Future<void> _playAnimation() async {
    if (mounted && widget.active) {
      _fadeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Number
              Text(
                widget.number,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary.withValues(alpha: 0.35),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              // Thin line
              Container(
                width: 32,
                height: 0.5,
                color: AppColors.textPrimary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              // Title — large editorial
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  letterSpacing: 3.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              // Subtitle
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary.withValues(alpha: 0.55),
                  height: 1.7,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              // Demo area
              SizedBox(
                height: 200,
                child: Center(child: widget.demo),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Demo: Kıyafet Yükle — editorial photo arrival ───
class _UploadDemoWidget extends StatefulWidget {
  const _UploadDemoWidget({required this.active});
  final bool active;
  @override
  State<_UploadDemoWidget> createState() => _UploadDemoWidgetState();
}

class _UploadDemoWidgetState extends State<_UploadDemoWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_UploadDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted && widget.active) {
      _mainController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active &&
        !_mainController.isAnimating &&
        _mainController.value == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.active && mounted) _startAnimation();
      });
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _pulseController]),
      builder: (context, child) {
        final step = _mainController.value;
        return Center(
          child: SizedBox(
            width: 260,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background frame
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                ),
                // Phase 1: Camera icon pulse (0-0.25)
                if (step < 0.3) _buildCameraPhase(step / 0.25),
                // Phase 2: Photo slides in (0.25-0.5)
                if (step >= 0.2 && step < 0.55)
                  _buildPhotoArrival((step - 0.2).clamp(0.0, 0.3) / 0.3),
                // Phase 3: Progress scan (0.5-0.75)
                if (step >= 0.45 && step < 0.8)
                  _buildScanLine((step - 0.45).clamp(0.0, 0.3) / 0.3),
                // Phase 4: Check mark (0.75-1.0)
                if (step >= 0.75) _buildCheckMark((step - 0.75) / 0.25),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraPhase(double t) {
    final pulse = 1.0 + 0.04 * math.sin(_pulseController.value * math.pi * 2);
    final opacity = t < 0.8 ? 1.0 : (1.0 - (t - 0.8) / 0.2);
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: pulse,
        child: Icon(
          Icons.camera_alt_outlined,
          size: 48,
          color: AppColors.textPrimary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildPhotoArrival(double t) {
    final curveT = Curves.easeOutCubic.transform(t);
    return Opacity(
      opacity: curveT,
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - curveT)),
        child: Container(
          width: 120,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.checkroom_outlined,
                size: 40,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Container(
                width: 48,
                height: 3,
                color: AppColors.textPrimary.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 3,
                color: AppColors.textPrimary.withValues(alpha: 0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanLine(double t) {
    final scanPos = Curves.easeInOut.transform(t);
    return Positioned(
      top: 10 + scanPos * 140,
      left: 70,
      right: 70,
      child: Opacity(
        opacity: t < 0.1 ? t / 0.1 : (t > 0.9 ? (1 - t) / 0.1 : 1.0),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primary.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckMark(double t) {
    final curveT = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: curveT.clamp(0.0, 1.2),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Icon(
            Icons.check,
            size: 28,
            color: AppColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ─── Demo: Dolabım — floating grid marquee ───
class _WardrobeGridDemoWidget extends StatefulWidget {
  const _WardrobeGridDemoWidget({required this.active});
  final bool active;
  @override
  State<_WardrobeGridDemoWidget> createState() =>
      _WardrobeGridDemoWidgetState();
}

class _WardrobeGridDemoWidgetState extends State<_WardrobeGridDemoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  static const List<IconData> _icons = [
    Icons.checkroom_outlined,
    Icons.dry_cleaning_outlined,
    Icons.shopping_bag_outlined,
    Icons.style_outlined,
    Icons.accessibility_new_outlined,
    Icons.watch_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didUpdateWidget(_WardrobeGridDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted && widget.active) {
      _fadeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active &&
        !_fadeController.isAnimating &&
        _fadeController.value == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.active && mounted) _startAnimation();
      });
    }
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Center(
          child: SizedBox(
            width: 220,
            height: 180,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final delay = index * 0.12;
                final itemT =
                    ((_fadeController.value - delay) / 0.4).clamp(0.0, 1.0);
                final curveT = Curves.easeOutCubic.transform(itemT);
                return Opacity(
                  opacity: curveT,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - curveT)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary
                            .withValues(alpha: 0.03 + index * 0.01),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _icons[index],
                          size: 26,
                          color: AppColors.textPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Demo: AI Stilist — outfit assembly animation ───
class _AIStylistDemoWidget extends StatefulWidget {
  const _AIStylistDemoWidget({required this.active});
  final bool active;
  @override
  State<_AIStylistDemoWidget> createState() => _AIStylistDemoWidgetState();
}

class _AIStylistDemoWidgetState extends State<_AIStylistDemoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 5 clothing pieces: top, bottom, shoes, accessory, and outer
  static const List<IconData> _pieceIcons = [
    Icons.checkroom_outlined,     // üst (0)
    Icons.dry_cleaning_outlined,  // alt (1)
    Icons.shopping_bag_outlined,  // ayakkabı (2)
    Icons.watch_outlined,         // aksesuar (3) — deselected
    Icons.face_outlined,          // diş (4) — deselected
  ];

  // Starting positions (scattered)
  static final List<Offset> _startPositions = [
    const Offset(-70, -40),  // üst: sol üst
    const Offset(70, -30),   // alt: sağ üst
    const Offset(-80, 30),   // ayakkabı: sol alt
    const Offset(75, 50),    // aksesuar: sağ alt
    const Offset(0, -60),    // diş: merkez üst
  ];

  // Ending positions (selected 3 centered, others faded)
  static final List<Offset> _endPositions = [
    const Offset(-50, 0),    // üst: sol merkez
    const Offset(0, 0),      // alt: merkez
    const Offset(50, 0),     // ayakkabı: sağ merkez
    const Offset(100, 100),  // aksesuar: off-screen
    const Offset(100, 100),  // diş: off-screen
  ];

  // Which pieces are selected in the final combo
  static const List<bool> _isSelected = [true, true, true, false, false];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void didUpdateWidget(_AIStylistDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted && widget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active && !_controller.isAnimating && _controller.value == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.active && mounted) _startAnimation();
      });
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        return Center(
          child: SizedBox(
            width: 260,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 5 clothing pieces
                ...List.generate(5, (index) {
                  // Phase 1 (0.0–0.2): Fade in at start positions
                  if (t < 0.2) {
                    final fadeT = Curves.easeOut.transform(t / 0.2);
                    return Positioned(
                      left: 130 + _startPositions[index].dx,
                      top: 90 + _startPositions[index].dy,
                      child: Opacity(
                        opacity: fadeT,
                        child: _buildPieceCard(index, isSelected: false),
                      ),
                    );
                  }

                  // Phase 2 (0.2–0.5): Highlight scan effect
                  final highlightT = (t - 0.2).clamp(0.0, 0.3) / 0.3;
                  final pieceHighlightPhase = ((highlightT * 5) - index).clamp(0.0, 0.15) / 0.15;
                  final highlightOpacity = pieceHighlightPhase > 0 ? (1.0 - (pieceHighlightPhase - 1.0).abs()) : 0.0;

                  // Phase 3 (0.5–0.9): Move to final positions
                  final moveT = (t - 0.5).clamp(0.0, 0.4) / 0.4;
                  final moveCurve = Curves.easeInOutCubic.transform(moveT);
                  final finalOpacity = t < 0.5 ? 1.0 : (_isSelected[index] ? (1.0 - (t - 0.5) * 0.5).clamp(0.3, 1.0) : ((0.5 - (t - 0.5)).clamp(0.0, 1.0)));

                  final Offset currentPos = Offset.lerp(
                    _startPositions[index],
                    _endPositions[index],
                    moveCurve,
                  )!;

                  return Positioned(
                    left: 130 + currentPos.dx,
                    top: 90 + currentPos.dy,
                    child: Opacity(
                      opacity: finalOpacity,
                      child: Stack(
                        children: [
                          _buildPieceCard(index, isSelected: _isSelected[index] && t > 0.5),
                          // Highlight glow during scan
                          if (highlightOpacity > 0)
                            Container(
                              width: 64,
                              height: 82,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.textPrimary.withValues(alpha: 0.4 * highlightOpacity),
                                  width: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                // Phase 4 (0.9–1.0): "KOMBIN HAZIR" badge
                if (t > 0.9)
                  Positioned(
                    bottom: 10,
                    child: Opacity(
                      opacity: ((t - 0.9) / 0.1).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: Curves.easeOutBack.transform(((t - 0.9) / 0.1).clamp(0.0, 1.0)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textPrimary.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 12,
                                color: AppColors.textPrimary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'KOMBİN HAZIR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieceCard(int index, {required bool isSelected}) {
    return Container(
      width: 64,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(
          alpha: isSelected ? 0.06 : 0.03,
        ),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: isSelected ? 0.2 : 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _pieceIcons[index],
            size: 24,
            color: AppColors.textPrimary.withValues(
              alpha: isSelected ? 0.5 : 0.35,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 20,
            height: 2,
            color: AppColors.textPrimary.withValues(
              alpha: isSelected ? 0.15 : 0.08,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Demo: AI Assistant Chat — typewriter animation ───
class _AIChatDemoWidget extends StatefulWidget {
  const _AIChatDemoWidget({required this.active});
  final bool active;
  @override
  State<_AIChatDemoWidget> createState() => _AIChatDemoWidgetState();
}

class _ChatDemoMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  const _ChatDemoMessage({required this.role, required this.text});
}

class _AIChatDemoWidgetState extends State<_AIChatDemoWidget>
    with TickerProviderStateMixin {
  late AnimationController _messageController;

  // Demo conversation (hardcoded Turkish)
  static const List<_ChatDemoMessage> _demoMessages = [
    _ChatDemoMessage(role: 'user', text: 'Yarınki iş toplantısı için ne giymeliyim?'),
    _ChatDemoMessage(role: 'assistant', text: 'Siyah blazer + beyaz gömlek harika durur.'),
    _ChatDemoMessage(role: 'user', text: 'Ayakkabı önerir misin?'),
    _ChatDemoMessage(role: 'assistant', text: 'Oxford veya loafer mükemmel tamamlar.'),
  ];

  List<_ChatDemoMessage> _visibleMessages = [];
  List<int> _visibleLengths = [];
  Timer? _typingTimer;
  int _currentMessageIndex = 0;
  int _currentCharIndex = 0;

  static const int _charsPerTick = 2;
  static const Duration _typingInterval = Duration(milliseconds: 25);
  static const Duration _messageDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void didUpdateWidget(_AIChatDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted && widget.active) {
      _visibleMessages.clear();
      _visibleLengths.clear();
      _currentMessageIndex = 0;
      _currentCharIndex = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    if (!mounted) return;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(_typingInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        final currentMsg = _demoMessages[_currentMessageIndex];
        _currentCharIndex += _charsPerTick;

        if (_currentCharIndex >= currentMsg.text.length) {
          _currentCharIndex = currentMsg.text.length;

          // Message complete, move to next
          if (_currentMessageIndex < _demoMessages.length - 1) {
            _visibleMessages.add(currentMsg);
            _visibleLengths.add(currentMsg.text.length);
            _currentMessageIndex++;
            _currentCharIndex = 0;

            // Delay before next message
            _typingTimer?.cancel();
            timer.cancel();
            Future.delayed(_messageDelay, () {
              if (mounted && widget.active) _startTyping();
            });
          } else {
            // All messages done
            _visibleMessages.add(currentMsg);
            _visibleLengths.add(currentMsg.text.length);
            timer.cancel();
          }
        } else {
          _visibleLengths.add(_currentCharIndex);
        }
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active && _visibleMessages.isEmpty && _currentMessageIndex == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.active && mounted) _startAnimation();
      });
    }

    return Center(
      child: SizedBox(
        width: 280,
        height: 180,
        child: Column(
          children: [
            // Chat messages area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Previous complete messages
                    ..._visibleMessages.asMap().entries.map((e) {
                      final msg = e.value;
                      final isUser = msg.role == 'user';
                      return _buildChatBubble(msg.text, isUser);
                    }),
                    // Current typing message
                    if (_visibleMessages.length < _demoMessages.length)
                      _buildChatBubble(
                        _demoMessages[_currentMessageIndex].text.substring(
                          0,
                          _currentCharIndex.clamp(
                            0,
                            _demoMessages[_currentMessageIndex].text.length,
                          ),
                        ),
                        _demoMessages[_currentMessageIndex].role == 'user',
                        isTyping: true,
                      ),
                  ],
                ),
              ),
            ),
            // Input area (static)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stil hakkında sor...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 16,
                    color: AppColors.textPrimary.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, {bool isTyping = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              isUser ? 'SİZ' : 'VESTİYER ASİSTANI',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: AppColors.textPrimary.withValues(alpha: 0.4),
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: 240,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUser ? AppColors.textPrimary : AppColors.softBackground,
              border: isUser
                  ? null
                  : Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUser ? AppColors.background : AppColors.textPrimary,
                    height: 1.4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (isTyping)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: _TypingCursor(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Typing Cursor — blinking animation ───
class _TypingCursor extends StatefulWidget {
  const _TypingCursor();

  @override
  State<_TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<_TypingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 14,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
