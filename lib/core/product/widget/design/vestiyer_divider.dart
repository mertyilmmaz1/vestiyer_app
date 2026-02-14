import 'package:flutter/material.dart';

import '../../extensions/context_extension.dart';
import '../../theme/app_colors.dart';

/// Editorial divider - thickness 0.5, AppColors.border.
/// Opsiyonel label ile "veya" stili.
class VestiyerDivider extends StatelessWidget {
  const VestiyerDivider({
    super.key,
    this.label,
  });

  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null || label!.isEmpty) {
      return Divider(
        color: AppColors.border,
        thickness: 0.5,
        height: 1,
      );
    }
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.border,
            thickness: 0.5,
            height: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dynamicWidth(0.04)),
          child: Text(
            label!,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: AppColors.greyText,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.border,
            thickness: 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}
