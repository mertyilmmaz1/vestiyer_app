import 'package:flutter/material.dart';

import '../../extensions/context_extension.dart';
import '../../theme/app_colors.dart';

/// Primary CTA button with loading state.
class VestiyerPrimaryButton extends StatelessWidget {
  const VestiyerPrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.dynamicHeight(0.065),
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
