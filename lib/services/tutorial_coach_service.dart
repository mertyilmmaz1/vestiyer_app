import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../core/product/theme/app_colors.dart';
import '../core/product/theme/app_typography.dart';
import '../providers/tutorial_provider.dart';

/// Builds and shows Zara-styled tutorial coach marks for each tutorial phase.
class TutorialCoachService {
  TutorialCoachMark? _currentTutorial;

  /// Dismiss any active coach mark.
  void dismiss() {
    _currentTutorial?.finish();
    _currentTutorial = null;
  }

  /// Show the coach mark for the given tutorial step.
  /// Returns immediately if the key's context is null (widget not mounted).
  void showForStep({
    required BuildContext context,
    required TutorialStep step,
    required GlobalKey? targetKey,
    required VoidCallback onDismiss,
    required VoidCallback onSkip,
    required VoidCallback onContinue,
  }) {
    dismiss(); // Clear any previous tutorial

    if (targetKey?.currentContext == null) return;

    final target = _buildTarget(
      step,
      targetKey!,
      onContinue: onContinue,
      onSkip: () {
        // Trigger the coach mark's skip, which calls the onSkip callback below
        _currentTutorial?.skip();
      },
      onDismiss: onDismiss,
    );
    if (target == null) return;

    _currentTutorial = TutorialCoachMark(
      targets: [target],
      colorShadow: const Color(0xFF1A1A1A),
      opacityShadow: 0.88,
      hideSkip: true, // We build our own skip inside content
      pulseEnable: false,
      focusAnimationDuration: const Duration(milliseconds: 400),
      unFocusAnimationDuration: const Duration(milliseconds: 300),
      onSkip: () {
        onSkip();
        return true;
      },
      onClickTarget: (_) {
        onDismiss();
      },
      onClickOverlay: (_) {
        onDismiss();
      },
    )..show(context: context);
  }

  TargetFocus? _buildTarget(
    TutorialStep step,
    GlobalKey key, {
    required VoidCallback onContinue,
    required VoidCallback onSkip,
    required VoidCallback onDismiss,
  }) {
    String title;
    String description;
    ContentAlign align;
    String progress;

    switch (step) {
      case TutorialStep.welcome:
        title = 'GARDIROBUNUZU YÜKLEYİN';
        description =
            'Stil yolculuğunuz burada başlıyor. "+" butonuna dokunarak ilk parçanızı ekleyin.';
        align = ContentAlign.bottom;
        progress = '1/4';
        break;
      case TutorialStep.uploading:
        title = 'KOLEKSİYONUNUZU OLUŞTURUN';
        description =
            'Sizin için en iyi kombinleri oluşturabilmemiz için en az 5 parça kıyafete ihtiyacımız var.';
        align = ContentAlign.bottom;
        progress = '2/4';
        break;
      case TutorialStep.reached5Items:
        title = 'AI STİLİSTİNİZ HAZIR';
        description =
            'Yapay zeka asistanınız gardırobunuzu analiz etti. Kombin önerilerini görmek için tıklayın.';
        align = ContentAlign.bottom;
        progress = '3/4';
        break;
      case TutorialStep.aiPreview:
        title = 'İLK KOMBİNİNİZİ OLUŞTURUN';
        description =
            'Premium özelliklerimizi keşfetmeniz için ilk stil analizi ve kombin önerisi bizden.';
        align = ContentAlign.top;
        progress = '4/4';
        break;
      case TutorialStep.completed:
        return null;
    }

    return TargetFocus(
      identify: step.name,
      keyTarget: key,
      shape: ShapeLightFocus.RRect,
      radius: 4,
      paddingFocus: 8,
      enableOverlayTab: true,
      enableTargetTab: true,
      contents: [
        TargetContent(
          align: align,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          builder: (context, controller) {
            return _CoachContent(
              title: title,
              description: description,
              progress: progress,
              onDismiss: onContinue,
              onSkip: onSkip,
            );
          },
        ),
      ],
    );
  }
}

/// Zara-styled content widget for coach mark overlays.
class _CoachContent extends StatelessWidget {
  final String title;
  final String description;
  final String progress;
  final VoidCallback onDismiss;
  final VoidCallback onSkip;

  const _CoachContent({
    required this.title,
    required this.description,
    required this.progress,
    required this.onDismiss,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.textPrimary, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Progress + Skip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress,
                style: AppTypography.label.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: onSkip,
                child: Text(
                  'ATLA',
                  style: AppTypography.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            style: AppTypography.display.copyWith(
              fontSize: 18,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            description,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 28),
          // Dismiss button
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
              ),
              alignment: Alignment.center,
              child: Text(
                'DEVAM ET',
                style: AppTypography.label.copyWith(
                  color: AppColors.background,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
