import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/product/theme/app_colors.dart';
import '../core/product/theme/app_typography.dart';
import '../core/product/theme/app_spacing.dart';

class UploadGuideCard extends StatelessWidget {
  const UploadGuideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.softBackground,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
                color: AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppLocalizations.of(context).uploadGuideTitle,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGuideItem(
            context,
            HugeIcons.strokeRoundedCircle,
            AppLocalizations.of(context).uploadGuideTip1,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGuideItem(
            context,
            HugeIcons.strokeRoundedSun03,
            AppLocalizations.of(context).uploadGuideTip2,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGuideItem(
            context,
            HugeIcons.strokeRoundedSquare,
            AppLocalizations.of(context).uploadGuideTip3,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(BuildContext context, dynamic icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(
          icon: icon,
          color: AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
