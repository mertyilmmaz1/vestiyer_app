import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      final l10n = AppLocalizations.of(context);
      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: l10n.introBarrierLabel,
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

  static const List<Widget> _stepCards = [
    IntroUploadCard(),
    IntroCombineCard(),
    IntroAnalysisCard(),
  ];

  void _nextPage() {
    if (_currentPage < _stepCards.length - 1) {
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
                  children: List.generate(_stepCards.length, (index) {
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
                    itemCount: _stepCards.length,
                    itemBuilder: (context, index) {
                      final l10n = AppLocalizations.of(context);
                      final titles = [
                        l10n.introStep1Title,
                        l10n.introStep2Title,
                        l10n.introStep3Title,
                      ];
                      final descriptions = [
                        l10n.introStep1Description,
                        l10n.introStep2Description,
                        l10n.introStep3Description,
                      ];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              titles[index],
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
                              descriptions[index],
                              style: AppTypography.body.copyWith(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Expanded(child: _stepCards[index]),
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
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(
                              l10n.introSkip,
                              style: AppTypography.label.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.5,
                              ),
                            );
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: _nextPage,
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: const BoxDecoration(
                                color: AppColors.textPrimary,
                              ),
                              child: Text(
                                _currentPage == _stepCards.length - 1
                                    ? l10n.introStart
                                    : l10n.introContinue,
                                style: AppTypography.label.copyWith(
                                  color: AppColors.background,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            );
                          },
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
