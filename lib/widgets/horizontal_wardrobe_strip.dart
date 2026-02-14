import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_spacing.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing.dart';
import '../../widgets/bouncing_widget.dart';

/// Zara editorial: serif başlık, kare görsel, ince uppercase label.
class HorizontalWardrobeStrip extends StatelessWidget {
  const HorizontalWardrobeStrip({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
    required this.onItemTap,
    this.emptyMessage = 'Henüz kıyafet yok',
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final String title;
  final List<Clothing> items;
  final VoidCallback? onSeeAll;
  final void Function(Clothing item) onItemTap;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section başlığı — Zara serif stili
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display.copyWith(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'TÜMÜNÜ GÖR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Ürün listesi — Zara grid stili
        SizedBox(
          height: 190,
          child: items.isEmpty
              ? _EmptyStrip(
                  message: emptyMessage,
                  actionLabel: emptyActionLabel,
                  onAction: onEmptyAction,
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _WardrobeThumbCard(
                      item: item,
                      onTap: () => onItemTap(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _WardrobeThumbCard extends StatelessWidget {
  const _WardrobeThumbCard({
    required this.item,
    required this.onTap,
  });

  final Clothing item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BouncingWidget(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kare görsel — border-radius yok (Zara stili)
                Container(
                  color: AppColors.softBackground,
                  child: AspectRatio(
                    aspectRatio: 0.85,
                    child: CachedNetworkImage(
                      imageUrl: item.displayImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.softBackground,
                        child: const Center(
                          child: Icon(
                            Icons.checkroom_outlined,
                            color: AppColors.border,
                            size: 28,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.softBackground,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.border,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Ürün adı — Zara: küçük uppercase, ince weight
                Text(
                  item.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStrip extends StatelessWidget {
  const _EmptyStrip({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.black,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    actionLabel!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
