import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_spacing.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_typography.dart';

/// Zara editorial: serif section title, minimal input, square corners.
class AssistantCard extends StatelessWidget {
  const AssistantCard({
    super.key,
    required this.onSend,
    this.showProBadge = false,
    this.hintText,
    this.controller,
  });

  final VoidCallback onSend;
  final bool showProBadge;
  final String? hintText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final effectiveHint = hintText ?? l10n.assistantCardHint;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label — küçük uppercase etiket (Zara menü stili)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedMagicWand01,
                color: AppColors.textPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.assistantCardLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              if (showProBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                  ),
                  child: Text(
                    l10n.assistantCardPro,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Serif başlık
          Text(
            l10n.assistantCardGreeting,
            style: AppTypography.display.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Input + gönder butonu
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: effectiveHint,
                    filled: true,
                    fillColor: AppColors.softBackground,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: AppColors.black,
                        width: 0.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.black,
                child: InkWell(
                  onTap: onSend,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
