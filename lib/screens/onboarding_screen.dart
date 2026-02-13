import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

/// Onboarding ekranı - ilk açılışta özellikler animasyonlu slaytlarla tanıtılır.
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

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  @override
  void dispose() {
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
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Atla',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.1),
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) =>
                                setState(() => _currentPage = index),
                            children: [
                              _OnboardingSlide(
                                title: 'Kıyafet Yükle',
                                description:
                                    'Fotoğraf çekin veya galeriden seçin. Yapay zeka kıyafetinizi analiz edip dolabınıza ekler.',
                                isActive: _currentPage == 0,
                                demo: _UploadDemoWidget(
                                    active: _currentPage == 0),
                              ),
                              _OnboardingSlide(
                                title: 'Dolabımı Gör',
                                description:
                                    'Tüm kıyafetleriniz tek ekranda. Koleksiyonunuzu kategorilere göre keşfedin.',
                                isActive: _currentPage == 1,
                                demo: _WardrobeGridDemoWidget(
                                    active: _currentPage == 1),
                              ),
                              _OnboardingSlide(
                                title: 'AI Stilist',
                                description:
                                    'Yapay zeka dolabınızdaki parçalarla mükemmel kombinler oluşturur.',
                                isActive: _currentPage == 2,
                                demo: _AIStylistDemoWidget(
                                    active: _currentPage == 2),
                              ),
                              _OnboardingSlide(
                                title: 'Gardırop Analizi',
                                description:
                                    'Stil profilinizi ve alışveriş önerilerinizi görün.',
                                isActive: _currentPage == 3,
                                demo: _AnalysisDemoWidget(
                                    active: _currentPage == 3),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _totalPages,
                                  (index) => _DotIndicator(
                                    isActive: index == _currentPage,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_currentPage < _totalPages - 1) {
                                      _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      _completeOnboarding();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    _currentPage < _totalPages - 1
                                        ? 'İleri'
                                        : 'Başla',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.isActive,
    required this.demo,
  });

  final String title;
  final String description;
  final bool isActive;
  final Widget demo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 160, child: demo),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.textSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─── Demo: Kıyafet Yükle (pulse → slide-up+scale → shimmer bar → bounce check) ───
class _UploadDemoWidget extends StatefulWidget {
  const _UploadDemoWidget({required this.active});

  final bool active;

  @override
  State<_UploadDemoWidget> createState() => _UploadDemoWidgetState();
}

class _UploadDemoWidgetState extends State<_UploadDemoWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void didUpdateWidget(_UploadDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.active && mounted) _controller.forward(from: 0);
      });
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _shimmerController]),
      builder: (context, child) {
        final step = _controller.value;
        // 0-0.2: pulse icon, 0.2-0.45: photo slide-up+scale, 0.45-0.75: progress+shimmer, 0.75-1: bounce check
        return Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: step < 0.2
                  ? Center(
                      child: _buildPulseIcon(step / 0.2),
                    )
                  : step < 0.45
                      ? _buildPhotoSlideUp(step, 0.2, 0.45)
                      : step < 0.75
                          ? _buildProgressWithShimmer(step, 0.45, 0.75)
                          : _buildBounceCheck(step, 0.75, 1.0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseIcon(double t) {
    final scale = 1.0 + 0.08 * Curves.easeInOut.transform(t).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 56,
        color: AppColors.primary.withValues(alpha: 0.6 + 0.4 * t),
      ),
    );
  }

  Widget _buildPhotoSlideUp(double step, double start, double end) {
    final t = ((step - start) / (end - start)).clamp(0.0, 1.0);
    final curveT = Curves.easeOutQuint.transform(t);
    final slide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .transform(curveT);
    final scale = Tween<double>(begin: 0.85, end: 1.0).transform(curveT);
    final opacity = curveT;
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: opacity,
          child: SlideTransition(
            position: AlwaysStoppedAnimation(slide),
            child: ScaleTransition(
              scale: AlwaysStoppedAnimation(scale),
              child: Container(
                color: AppColors.secondary.withValues(alpha: 0.5),
                child: Icon(
                  Icons.checkroom,
                  size: 64,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressWithShimmer(double step, double start, double end) {
    final progress = ((step - start) / (end - start)).clamp(0.0, 1.0);
    final shimmerPos = _shimmerController.value;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: AppColors.secondary.withValues(alpha: 0.5),
          child: Icon(
            Icons.checkroom,
            size: 64,
            color: AppColors.textPrimary.withValues(alpha: 0.8),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: w * progress,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (progress > 0.05)
                      Positioned(
                        left: (w * progress * shimmerPos) - 20,
                        top: 0,
                        bottom: 0,
                        width: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.textPrimary.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBounceCheck(double step, double start, double end) {
    final t = ((step - start) / (end - start)).clamp(0.0, 1.0);
    final scaleVal = Curves.easeOutBack.transform(t);
    final s = (scaleVal < 0 ? 0.0 : scaleVal).clamp(0.0, 1.15);
    return Center(
      child: FadeTransition(
        opacity: AlwaysStoppedAnimation(t.clamp(0.0, 1.0)),
        child: ScaleTransition(
          scale: AlwaysStoppedAnimation(s),
          child: Icon(
            Icons.check_circle,
            size: 64,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Demo: Dolabım (yatay kayan marquee) ───
class _WardrobeGridDemoWidget extends StatefulWidget {
  const _WardrobeGridDemoWidget({required this.active});

  final bool active;

  @override
  State<_WardrobeGridDemoWidget> createState() =>
      _WardrobeGridDemoWidgetState();
}

class _WardrobeGridDemoWidgetState extends State<_WardrobeGridDemoWidget>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late Ticker _ticker;
  static const double _scrollSpeed = 24.0;
  Duration _prev = Duration.zero;
  static const List<Color> _colors = [
    Color(0xFF5C6BC0),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFE57373),
    Color(0xFF7986CB),
    Color(0xFF4DB6AC),
  ];
  static const int _cardCount = 6;
  static const double _cardWidth = 44;
  static const double _spacing = 10;
  double _singleSetWidth = 0;

  @override
  void initState() {
    super.initState();
    _singleSetWidth = _cardCount * _cardWidth + (_cardCount - 1) * _spacing;
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (!widget.active || !_scrollController.hasClients) {
      _prev = elapsed;
      return;
    }
    if (_prev == Duration.zero) {
      _prev = elapsed;
      return;
    }
    final dt = (elapsed - _prev).inMicroseconds / 1e6;
    _prev = elapsed;
    var next = _scrollController.offset + _scrollSpeed * dt;
    if (next >= _singleSetWidth) next -= _singleSetWidth;
    _scrollController.jumpTo(next);
  }

  @override
  void didUpdateWidget(_WardrobeGridDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _prev = Duration.zero;
      if (!_ticker.isActive) _ticker.start();
    } else {
      if (_ticker.isActive) _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCard(int index) {
    return Container(
      width: _cardWidth,
      height: 58,
      decoration: BoxDecoration(
        color: _colors[index % _colors.length].withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Icon(
        Icons.checkroom,
        color: AppColors.textPrimary.withValues(alpha: 0.9),
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active && !_ticker.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.active && mounted) _ticker.start();
      });
    }
    return Center(
      child: SizedBox(
        height: 70,
        child: ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _cardCount * 2,
                (i) => Padding(
                  padding: EdgeInsets.only(
                    right: i < _cardCount * 2 - 1 ? _spacing : 0,
                  ),
                  child: _buildCard(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Demo: AI Stilist (daireden satıra yakınsama) ───
class _AIStylistDemoWidget extends StatefulWidget {
  const _AIStylistDemoWidget({required this.active});

  final bool active;

  @override
  State<_AIStylistDemoWidget> createState() => _AIStylistDemoWidgetState();
}

class _AIStylistDemoWidgetState extends State<_AIStylistDemoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<Color> _cardColors = [
    Color(0xFF5C6BC0),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.active && mounted) _controller.forward(from: 0);
      });
    }
    return Center(
      child: SizedBox(
        width: 200,
        height: 120,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(_controller.value);
            return Stack(
              alignment: Alignment.center,
              children: List.generate(3, (index) {
                final start = _circleOffset(index);
                final end = _rowOffset(index);
                final dx = start.dx + (end.dx - start.dx) * t;
                final dy = start.dy + (end.dy - start.dy) * t;
                return Transform.translate(
                  offset: Offset(dx * 70, dy * 40),
                  child: _buildCard(index),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Offset _circleOffset(int index) {
    const radius = 0.85;
    final angleRad = (90 + index * 120) * math.pi / 180;
    return Offset(radius * math.cos(angleRad), -radius * math.sin(angleRad));
  }

  Offset _rowOffset(int index) {
    const spacing = 0.55;
    return Offset((index - 1) * spacing, 0);
  }

  Widget _buildCard(int index) {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: _cardColors[index].withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Icon(
        Icons.checkroom,
        color: AppColors.textPrimary.withValues(alpha: 0.9),
        size: 24,
      ),
    );
  }
}

// ─── Demo: Gardırop Analizi (dairesel dolum) ───
class _AnalysisDemoWidget extends StatefulWidget {
  const _AnalysisDemoWidget({required this.active});

  final bool active;

  @override
  State<_AnalysisDemoWidget> createState() => _AnalysisDemoWidgetState();
}

class _AnalysisDemoWidgetState extends State<_AnalysisDemoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<double> _targetValues = [0.45, 0.72, 0.88];
  static const List<String> _labels = ['Üst', 'Alt', 'Stil'];

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
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.active && mounted) _controller.forward(from: 0);
      });
    }
    return Center(
      child: SizedBox(
        width: 220,
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final delay = index * 0.18;
            final anim = CurvedAnimation(
              parent: _controller,
              curve: Interval(
                delay.clamp(0.0, 0.82),
                (delay + 0.45).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final value =
                          _targetValues[index] * anim.value.clamp(0.0, 1.0);
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withValues(
                            alpha: 0.6 + 0.4 * anim.value.clamp(0.0, 1.0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
