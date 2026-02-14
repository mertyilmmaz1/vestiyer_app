import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Editorial divider - ince çizgi (0.5), Zara stili.
class AppDividers {
  static Widget thin() => Divider(
        thickness: 0.5,
        color: AppColors.border,
      );

  static Widget thinWithHeight(double height) => Divider(
        thickness: 0.5,
        height: height,
        color: AppColors.border,
      );
}
