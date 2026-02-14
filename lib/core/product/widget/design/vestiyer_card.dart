import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Editorial section container - kart değil, sade arka plan.
/// Rehber: Card/radius/shadow kullanma.
class VestiyerCard extends StatelessWidget {
  const VestiyerCard({
    super.key,
    required this.child,
    this.hasGlow = false,
    this.padding,
  });

  final Widget child;
  final bool hasGlow;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.softBackground,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
        child: child,
      ),
    );
  }
}
