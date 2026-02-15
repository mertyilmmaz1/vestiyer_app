import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_typography.dart';
import '../providers/wardrobe_provider.dart';
import '../models/clothing.dart';
import '../widgets/vestiyer_page_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ai_stylist_screen.dart';
import 'clothing_detail_screen.dart';
import 'package:flutter/services.dart';

import 'package:vestiyer_nodejs/utils/clothing_formatter.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/staggered_slide_fade.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({
    super.key,
    this.showBackButton = true,
    this.onKombinPressed,
  });

  /// When false (e.g. when used as bottom nav tab), back button is hidden.
  final bool showBackButton;

  /// Callback to execute when "KOMBİN" FAB is pressed.
  /// If provided, this overrides the default navigation behavior.
  final VoidCallback? onKombinPressed;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeProvider>().loadClothingItems();
    });
  }

  void _showDeleteConfirmation(BuildContext context, Clothing item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.softBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: Text(
          'Kıyafeti Sil',
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Bu kıyafeti silmek istediğinizden emin misiniz?',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Önce UI'dan kaldır
                context.read<WardrobeProvider>().removeItemLocally(item);
                // Sonra backend'den sil
                await context.read<WardrobeProvider>().deleteClothingItem(item);
              } catch (e) {
                if (context.mounted) {
                  // Hata durumunda item'ı geri ekle
                  context.read<WardrobeProvider>().addItemLocally(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: AppColors.tertiary,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Sil',
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetWardrobeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.softBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: Text(
          'Dolabı Sıfırla',
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Tüm kıyafetleriniz silinecek. Bu işlem geri alınamaz. Emin misiniz?',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<WardrobeProvider>().resetWardrobe();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dolap başarıyla sıfırlandı'),
                      backgroundColor: AppColors.tertiary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: AppColors.tertiary,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Sıfırla',
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WardrobeProvider>(
      builder: (context, wardrobeProvider, child) {
        final items = wardrobeProvider.items;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VestiyerPageHeader(
                title: 'Dolabım',
                subtitle: items.isEmpty
                    ? 'Henüz kıyafet yok'
                    : '${items.length} kıyafet',
                showBackButton: widget.showBackButton,
                onBack: () => Navigator.maybePop(context),
                actions: items.isEmpty
                    ? []
                    : [
                        IconButton(
                          icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedTask01,
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.7),
                              size: 26),
                          onPressed: () async {
                            try {
                              final formattedItems =
                                  wardrobeProvider.getFormattedClothingItems();
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.softBackground,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                      side: BorderSide(
                                          color: AppColors.border, width: 0.5),
                                    ),
                                    title: Text(
                                      'Kıyafet Listesi',
                                      style: AppTypography.headline.copyWith(
                                          color: AppColors.textPrimary),
                                    ),
                                    content: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: SelectableText(
                                        formattedItems,
                                        style: AppTypography.body.copyWith(
                                          fontFamily: 'monospace',
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton.icon(
                                        icon: HugeIcon(
                                            icon: HugeIcons.strokeRoundedCopy01,
                                            color: AppColors.textSecondary),
                                        label: Text('Kopyala',
                                            style: AppTypography.body.copyWith(
                                                color: AppColors.textPrimary)),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: formattedItems));
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Kıyafet listesi kopyalandı'),
                                                backgroundColor:
                                                    AppColors.tertiary,
                                              ),
                                            );
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Kapat',
                                          style: AppTypography.body.copyWith(
                                              color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: AppColors.tertiary,
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: 'Kıyafet Listesi',
                        ),
                        IconButton(
                          icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedDelete02,
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.7),
                              size: 26),
                          onPressed: () =>
                              _showResetWardrobeConfirmation(context),
                          tooltip: 'Dolabı Sıfırla',
                        ),
                      ],
              ),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(context)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return StaggeredSlideFade(
                            index: index,
                            child: _buildClothingCard(
                                context, item, wardrobeProvider),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton:
              items.isNotEmpty ? _buildKombinFab(context) : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedClothes,
              size: 70,
              color: AppColors.textPrimary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'HENÜZ KIYAFET EKLENMEMİŞ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.softBackground,
                border: Border.all(
                  style: BorderStyle.solid,
                  strokeAlign: BorderSide.strokeAlignInside,
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Text(
                'Dolabınızı oluşturmak için ana sayfadan kıyafet yükleyin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.45),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClothingCard(
      BuildContext context, Clothing item, WardrobeProvider wardrobeProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ClothingDetailScreen(item: item),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.softBackground,
          border: Border.all(
            style: BorderStyle.solid,
            strokeAlign: BorderSide.strokeAlignInside,
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'clothing_${item.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: item.displayImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.05),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildImageErrorWidget(),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.softBackground,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ClothingFormatter.format(item.category).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: TextStyle(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.45),
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showDeleteConfirmation(context, item),
                    borderRadius: BorderRadius.zero,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 20,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKombinFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          style: BorderStyle.solid,
          strokeAlign: BorderSide.strokeAlignInside,
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: BouncingWidget(
        child: FloatingActionButton.extended(
          onPressed: () {
            if (widget.onKombinPressed != null) {
              widget.onKombinPressed!();
            } else {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const AIStylistScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuint,
                      )),
                      child: child,
                    );
                  },
                ),
              );
            }
          },
          backgroundColor: AppColors.softBackground,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedMagicWand01,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          label: const Text(
            'KOMBİN',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          extendedPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: AppColors.tertiary,
      child: const Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImage01,
          color: AppColors.textSecondary,
          size: 40,
        ),
      ),
    );
  }
}
