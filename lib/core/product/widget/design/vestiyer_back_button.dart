import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 40x40 tertiary back button with arrow icon.
class VestiyerBackButton extends StatelessWidget {
  const VestiyerBackButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
