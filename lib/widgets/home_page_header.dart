import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_spacing.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_typography.dart';

/// Zara editöryal header: serif VESTIYER logo + minimal ikon navigasyonu.
class HomePageHeader extends StatelessWidget {
  const HomePageHeader({
    super.key,
    required this.firstName,
    required this.subtitle,
    this.avatarUrl,
    this.onProfileTap,
  });

  final String? firstName;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (firstName != null && firstName!.isNotEmpty) ...[
            Text(
              l10n.greetingUser(firstName!.toUpperCase()),
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Subtitle — küçük uppercase label
          Text(
            subtitle.toUpperCase(),
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
