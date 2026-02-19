import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_spacing.dart';
import '../../../../widgets/bouncing_widget.dart';

/// Zara editorial: kare ikon grid, border-radius yok, uppercase label.
class CircleFeatureItem {
  const CircleFeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlight = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  /// true = vurgulu (primary) arka plan.
  final bool isHighlight;
}

/// Kare ikon grid (Zara: border-radius 0, ince kenarlık).
class CircleFeatureGrid extends StatelessWidget {
  const CircleFeatureGrid({
    super.key,
    required this.items,
    this.maxColumns = 3,
  });

  final List<CircleFeatureItem> items;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final rows = <List<CircleFeatureItem>>[];
    for (var i = 0; i < items.length; i += maxColumns) {
      final end =
          (i + maxColumns > items.length) ? items.length : i + maxColumns;
      rows.add(items.sublist(i, end));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: rows.map((rowItems) {
          final children = <Widget>[];
          for (var i = 0; i < maxColumns; i++) {
            if (i < rowItems.length) {
              children.add(
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i != maxColumns - 1 ? 16 : 0,
                    ),
                    child: _SquareFeatureCell(item: rowItems[i]),
                  ),
                ),
              );
            } else {
              children.add(
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i != maxColumns - 1 ? 16 : 0,
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ),
              );
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SquareFeatureCell extends StatelessWidget {
  const _SquareFeatureCell({required this.item});

  final CircleFeatureItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = item.isHighlight ? AppColors.primary : AppColors.background;
    final iconColor = item.isHighlight ? Colors.white : AppColors.textPrimary;

    return BouncingWidget(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: item.icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.label.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
