import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

class OccasionSelectionDialog extends StatelessWidget {
  const OccasionSelectionDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const OccasionSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final occasions = [
      {'value': 'gundelik', 'label': 'GÜNDELİK', 'icon': Icons.circle_outlined},
      {'value': 'is', 'label': 'İŞ', 'icon': Icons.circle_outlined},
      {'value': 'piknik', 'label': 'PİKNİK', 'icon': Icons.circle_outlined},
      {'value': 'spor', 'label': 'SPOR', 'icon': Icons.circle_outlined},
      {'value': 'gece', 'label': 'GECE', 'icon': Icons.circle_outlined},
      {'value': 'ozel', 'label': 'ÖZEL GÜN', 'icon': Icons.circle_outlined},
      {'value': 'tatil', 'label': 'TATİL', 'icon': Icons.circle_outlined},
      {'value': 'okul', 'label': 'OKUL', 'icon': Icons.circle_outlined},
    ];

    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.all(20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'KOMBİNİ NEREDE GİYECEKSİNİZ?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Size en uygun önerileri sunabilmemiz için bir ortam seçin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: occasions.map((occasion) {
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(occasion['value']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              occasion['label'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1.0,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text(
                    'VAZGEÇ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
