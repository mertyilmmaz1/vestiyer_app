import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

/// Tek hücre: yuvarlak arka plan + ikon + etiket.
class CircleFeatureItem {
  const CircleFeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  /// true = vurgulu (primary) arka plan.
  final bool isHighlight;
}

/// Yuvarlak ikon grid; satır sayısı öğe sayısına göre dinamik (4 sütun).
class CircleFeatureGrid extends StatelessWidget {
  const CircleFeatureGrid({
    super.key,
    required this.items,
  });

  /// Herhangi sayıda öğe; grid 4 sütun üzerinden satırlara böler.
  final List<CircleFeatureItem> items;

  @override
  Widget build(BuildContext context) {
    const columns = 4;
    final rows = (items.length / columns).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row < rows - 1 ? 20 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(columns, (col) {
                final i = row * columns + col;
                if (i >= items.length) return const Expanded(child: SizedBox());
                final item = items[i];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: col < columns - 1 ? 12 : 0,
                    ),
                    child: _CircleFeatureCell(item: item),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _CircleFeatureCell extends StatelessWidget {
  const _CircleFeatureCell({required this.item});

  final CircleFeatureItem item;

  @override
  Widget build(BuildContext context) {
    final bgColor = item.isHighlight
        ? AppColors.primary
        : AppColors.cardBackground;
    final iconColor = item.isHighlight
        ? AppColors.textPrimary
        : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(999),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 28,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
