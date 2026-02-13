import 'package:flutter/material.dart';

import '../../extensions/context_extension.dart';
import '../../theme/app_colors.dart';

/// "veya" style divider.
class VestiyerDivider extends StatelessWidget {
  const VestiyerDivider({
    super.key,
    this.label = 'veya',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            thickness: 0.5,
            height: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dynamicWidth(0.04)),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary.withValues(alpha: 0.35),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            thickness: 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}
