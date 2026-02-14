import 'dart:math' as math;

import 'package:flutter/material.dart';
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

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;
  static const _prefsKey = 'onboarding_completed';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
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
    _fadeController.forward();
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
    _fadeController.forward(from: 0);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — minimal skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VESTIYER',
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
                      'ATLA',
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
                    fadeAnim: _fadeAnim,
                    slideAnim: _slideAnim,
                    number: '01',
                    title: 'KIYAFET\nYÜKLE',
                    subtitle:
                        'Fotoğraf çekin veya galeriden seçin.\nYapay zeka kıyafetinizi analiz edip\ndolabınıza ekler.',
                    demo: _UploadDemoWidget(active: _currentPage == 0),
                  ),
                  _EditorialSlide(
                    fadeAnim: _fadeAnim,
                    slideAnim: _slideAnim,
                    number: '02',
                    title: 'DİJİTAL\nDOLABIN',
                    subtitle:
                        'Tüm kıyafetleriniz tek ekranda.\nKoleksiyonunuzu kategorilere göre\nkeşfedin.',
                    demo: _WardrobeGridDemoWidget(active: _currentPage == 1),
                  ),
                  _EditorialSlide(
                    fadeAnim: _fadeAnim,
                    slideAnim: _slideAnim,
                    number: '03',
                    title: 'AI\nSTİLİST',
                    subtitle:
                        'Yapay zeka dolabınızdaki parçalarla\nmükemmel kombinler oluşturur.',
                    demo: _AIStylistDemoWidget(active: _currentPage == 2),
                  ),
                  _EditorialSlide(
                    fadeAnim: _fadeAnim,
                    slideAnim: _slideAnim,
                    number: '04',
                    title: 'GARDROP\nANALİZİ',
                    subtitle:
                        'Stil profilinizi keşfedin.\nAkıllı alışveriş önerileriyle\ndolabınızı optimize edin.',
                    demo: _AnalysisDemoWidget(active: _currentPage == 3),
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
                        _currentPage < _totalPages - 1 ? 'İLERİ' : 'BAŞLA',
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
class _EditorialSlide extends StatelessWidget {
  const _EditorialSlide({
    required this.fadeAnim,
    required this.slideAnim,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.demo,
  });

  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final String number;
  final String title;
  final String subtitle;
  final Widget demo;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Number
              Text(
                number,
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
                title,
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
                subtitle,
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
                child: Center(child: demo),
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
    if (widget.active && !_mainController.isAnimating) {
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
        if (widget.active && mounted) _mainController.forward(from: 0);
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
    if (widget.active && !_fadeController.isAnimating) {
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
        if (widget.active && mounted) _fadeController.forward(from: 0);
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

// ─── Demo: AI Stilist — convergence animation ───
class _AIStylistDemoWidget extends StatefulWidget {
  const _AIStylistDemoWidget({required this.active});
  final bool active;
  @override
  State<_AIStylistDemoWidget> createState() => _AIStylistDemoWidgetState();
}

class _AIStylistDemoWidgetState extends State<_AIStylistDemoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didUpdateWidget(_AIStylistDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
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
        if (widget.active && mounted) _controller.forward(from: 0);
      });
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Center(
          child: SizedBox(
            width: 260,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Three cards converging from scattered to aligned
                ...List.generate(3, (index) {
                  final startX = (index - 1) * 90.0;
                  final startY = [20.0, -25.0, 15.0][index];
                  final startRot = [-0.08, 0.05, -0.03][index];
                  final endX = (index - 1) * 60.0;

                  final dx = startX + (endX - startX) * t;
                  final dy = startY * (1 - t);
                  final rot = startRot * (1 - t);

                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Transform.rotate(
                      angle: rot,
                      child: Opacity(
                        opacity: (t * 3).clamp(0.0, 1.0),
                        child: Container(
                          width: 52,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary
                                .withValues(alpha: 0.04 + index * 0.02),
                            border: Border.all(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                [
                                  Icons.checkroom_outlined,
                                  Icons.dry_cleaning_outlined,
                                  Icons.shopping_bag_outlined,
                                ][index],
                                size: 22,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 24,
                                height: 2,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // AI sparkle icon appears after convergence
                if (t > 0.7)
                  Positioned(
                    bottom: 15,
                    child: Opacity(
                      opacity: ((t - 0.7) / 0.3).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: Curves.easeOutBack
                            .transform(((t - 0.7) / 0.3).clamp(0.0, 1.0)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'KOMBİN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.5),
                                  letterSpacing: 2.0,
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
}

// ─── Demo: Gardırop Analizi — animated bar chart ───
class _AnalysisDemoWidget extends StatefulWidget {
  const _AnalysisDemoWidget({required this.active});
  final bool active;
  @override
  State<_AnalysisDemoWidget> createState() => _AnalysisDemoWidgetState();
}

class _AnalysisDemoWidgetState extends State<_AnalysisDemoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<double> _targetHeights = [0.45, 0.72, 0.88, 0.56, 0.34];
  static const List<String> _labels = ['ÜST', 'ALT', 'DIŞ', 'AYAK', 'AKSES'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didUpdateWidget(_AnalysisDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
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
        if (widget.active && mounted) _controller.forward(from: 0);
      });
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: SizedBox(
            width: 240,
            height: 180,
            child: Column(
              children: [
                // Bar chart
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final delay = index * 0.1;
                      final barT =
                          ((_controller.value - delay) / 0.5).clamp(0.0, 1.0);
                      final curveT = Curves.easeOutCubic.transform(barT);
                      final height = _targetHeights[index] * curveT * 110;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 28,
                            height: height,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary
                                  .withValues(alpha: 0.08 + index * 0.03),
                              border: Border.all(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.12),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                // Baseline
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.textPrimary.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
                // Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _labels
                      .map((label) => SizedBox(
                            width: 36,
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.4),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
