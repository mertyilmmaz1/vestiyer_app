import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/product/theme/app_colors.dart';
import '../core/product/theme/app_typography.dart';
import 'intro_cards.dart';

class IntroDialog extends StatefulWidget {
  const IntroDialog({super.key});

  @override
  State<IntroDialog> createState() => _IntroDialogState();

  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_new_intro') ?? false;
    if (hasSeen) return;

    if (context.mounted) {
      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Intro',
        barrierColor: Colors.black.withValues(alpha: 0.8),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const IntroDialog(),
        transitionBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      );
      await prefs.setBool('has_seen_new_intro', true);
    }
  }
}

class _IntroDialogState extends State<IntroDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'GARDIROBUNUZU\nDİJİTALLEŞTİRİN',
      'description':
          'Kıyafetlerinizi fotoğrafını çekerek veya galeriden yükleyerek sanal gardırobunuza ekleyin.',
      'card': const IntroUploadCard(),
    },
    {
      'title': 'SINIRSIZ\nKOMBİNLER',
      'description':
          'Parçalarınızı eşleştirin ve yapay zeka desteğiyle saniyeler içinde yeni stiller keşfedin.',
      'card': const IntroCombineCard(),
    },
    {
      'title': 'KİŞİSEL\nSTİL ANALİZİ',
      'description':
          'Dolabınızdaki renk, tarz ve sezon dağılımını analiz ederek size özel alışveriş tavsiyeleri alın.',
      'card': const IntroAnalysisCard(),
    },
  ];

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight * 0.85).clamp(500.0, 700.0);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
            width: double.infinity,
            height: dialogHeight,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.background,
            child: Column(
              children: [
                // Top Progress Bar
                Row(
                  children: List.generate(_steps.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: index <= _currentPage
                            ? AppColors.textPrimary
                            : AppColors.border,
                      ),
                    );
                  }),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              step['title'],
                              style: AppTypography.display.copyWith(
                                fontSize: 24,
                                height: 1.2,
                                letterSpacing: 2.0,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step['description'],
                              style: AppTypography.body.copyWith(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Expanded(child: step['card'] as Widget),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Action Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'ATLA',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          decoration: const BoxDecoration(
                            color: AppColors.textPrimary,
                          ),
                          child: Text(
                            _currentPage == _steps.length - 1
                                ? 'BAŞLA'
                                : 'DEVAM ET',
                            style: AppTypography.label.copyWith(
                              color: AppColors.background,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
