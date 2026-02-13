import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import '../providers/wardrobe_provider.dart';
import '../models/clothing.dart';
import '../widgets/vestiyer_page_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ai_stylist_screen.dart';
import 'clothing_detail_screen.dart';
import 'package:flutter/services.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key, this.showBackButton = true});

  /// When false (e.g. when used as bottom nav tab), back button is hidden.
  final bool showBackButton;

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
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Kıyafeti Sil',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Bu kıyafeti silmek istediğinizden emin misiniz?',
          style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.7))),
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
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showResetWardrobeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Dolabı Sıfırla',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Tüm kıyafetleriniz silinecek. Bu işlem geri alınamaz. Emin misiniz?',
          style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.7))),
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
            child:
                const Text('Sıfırla', style: TextStyle(color: AppColors.error)),
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
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VestiyerPageHeader(
                  title: 'Dolabım',
                  subtitle: items.isEmpty ? 'Henüz kıyafet yok' : '${items.length} kıyafet',
                  showBackButton: widget.showBackButton,
                  onBack: () => Navigator.maybePop(context),
                  actions: items.isEmpty
                      ? []
                      : [
                          IconButton(
                            icon: Icon(Icons.format_list_bulleted,
                                color: AppColors.textPrimary.withValues(alpha: 0.7),
                                size: 26),
                            onPressed: () async {
                              try {
                                final formattedItems =
                                    wardrobeProvider.getFormattedClothingItems();
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppColors.tertiary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24)),
                                      title: const Text('Kıyafet Listesi',
                                          style: TextStyle(color: AppColors.textPrimary)),
                                      content: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: SelectableText(
                                          formattedItems,
                                          style: TextStyle(
                                              fontFamily: 'monospace',
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.7)),
                                        ),
                                      ),
                                      actions: [
                                        TextButton.icon(
                                          icon: Icon(Icons.copy,
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.7)),
                                          label: const Text('Kopyala',
                                              style: TextStyle(
                                                  color: AppColors.textPrimary)),
                                          onPressed: () {
                                            Clipboard.setData(
                                                ClipboardData(text: formattedItems));
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text('Kıyafet listesi kopyalandı'),
                                                  backgroundColor: AppColors.tertiary,
                                                ),
                                              );
                                              Navigator.pop(context);
                                            }
                                          },
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Kapat',
                                              style: TextStyle(
                                                  color: AppColors.textPrimary
                                                      .withValues(alpha: 0.7))),
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
                            icon: Icon(Icons.delete_sweep_outlined,
                                color: AppColors.textPrimary.withValues(alpha: 0.7),
                                size: 26),
                            onPressed: () => _showResetWardrobeConfirmation(context),
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
                            return _buildClothingCard(
                                context, item, wardrobeProvider);
                          },
                        ),
                ),
              ],
            ),
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
            Icon(
              Icons.checkroom_outlined,
              size: 70,
              color: AppColors.textPrimary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz kıyafet eklenmemiş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  style: BorderStyle.solid,
                  strokeAlign: BorderSide.strokeAlignInside,
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  width: 1,
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
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            style: BorderStyle.solid,
            strokeAlign: BorderSide.strokeAlignInside,
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
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
                          imageUrl: item.imageUrl,
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
                    color: AppColors.tertiary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          style: BorderStyle.solid,
          strokeAlign: BorderSide.strokeAlignInside,
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
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
        },
        backgroundColor: AppColors.tertiary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
        label: const Text(
          'Kombin',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        extendedPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: AppColors.tertiary,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppColors.textSecondary,
          size: 40,
        ),
      ),
    );
  }
}
