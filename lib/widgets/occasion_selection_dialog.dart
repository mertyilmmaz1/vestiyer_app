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
      {'value': 'gundelik', 'label': 'Gündelik', 'icon': Icons.home},
      {'value': 'is', 'label': 'İş', 'icon': Icons.work},
      {'value': 'piknik', 'label': 'Piknik', 'icon': Icons.park},
      {'value': 'spor', 'label': 'Spor', 'icon': Icons.sports},
      {'value': 'gece', 'label': 'Gece', 'icon': Icons.nightlight},
      {'value': 'ozel', 'label': 'Özel Gün', 'icon': Icons.celebration},
      {'value': 'tatil', 'label': 'Tatil', 'icon': Icons.beach_access},
      {'value': 'okul', 'label': 'Okul', 'icon': Icons.school},
    ];

    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Dialog(
      backgroundColor: AppColors.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kombini Nerede Giyeceksiniz?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ortam seçimi kombin önerilerinizi daha uygun hale getirir',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: occasions.length,
                    itemBuilder: (context, index) {
                      final occasion = occasions[index];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).pop(occasion['value']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.tertiary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.textPrimary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                occasion['icon'] as IconData,
                                color: AppColors.textPrimary.withValues(alpha: 0.7),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                occasion['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary.withValues(alpha: 0.6),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop('gundelik'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Varsayılan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
