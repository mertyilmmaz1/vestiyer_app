import 'package:flutter/material.dart';

import '../../extensions/context_extension.dart';
import '../../theme/app_colors.dart';

/// Editorial CTA - filled siyah veya outline.
/// Rehber: Uppercase, letterSpacing 1.1, padding 18-22.
class VestiyerPrimaryButton extends StatelessWidget {
  const VestiyerPrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
    this.outline = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                outline ? AppColors.black : Colors.white,
              ),
            ),
          )
        : Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.1,
            ),
          );

    if (outline) {
      return SizedBox(
        width: double.infinity,
        height: context.dynamicHeight(0.065),
        child: OutlinedButton(
          onPressed: enabled && !isLoading ? onTap : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            side: BorderSide(color: AppColors.black, width: 0.8),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: const RoundedRectangleBorder(),
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: context.dynamicHeight(0.065),
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.greyText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const RoundedRectangleBorder(),
        ),
        child: content,
      ),
    );
  }
}
