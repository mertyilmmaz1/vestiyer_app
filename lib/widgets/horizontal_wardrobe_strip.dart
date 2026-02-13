import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing.dart';

/// Bölüm başlığı + isteğe bağlı "Tümünü Gör" + yatay kıyafet listesi.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: items.isEmpty
              ? _EmptyStrip(
                  message: emptyMessage,
                  actionLabel: emptyActionLabel,
                  onAction: onEmptyAction,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.tertiary,
                      child: Icon(
                        Icons.checkroom_outlined,
                        color: AppColors.textPrimary.withValues(alpha: 0.3),
                        size: 32,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.tertiary,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textPrimary.withValues(alpha: 0.3),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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
