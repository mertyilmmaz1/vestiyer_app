import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

/// Referans tasarım: sayfa başlığı — geri butonu (opsiyonel) + büyük başlık + sağ aksiyonlar.
class VestiyerPageHeader extends StatelessWidget {
  const VestiyerPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    size: 26,
                  ),
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
