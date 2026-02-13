import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tertiary background card with 24px radius and subtle border.
/// Optional radial gradient glow in corner.
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
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.loose,
        children: [
          if (hasGlow)
            Align(
              alignment: Alignment.topRight,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.only(topRight: Radius.circular(23)),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      radius: 0.7,
                      center: const Alignment(0.4, -0.4),
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: child,
          ),
        ],
      ),
    );
  }
}
