import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/clothing.dart';
import '../models/combination.dart';
import '../services/cloud_functions_service.dart';
import '../services/firestore_service_base.dart';
import '../widgets/vestiyer_page_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';
import 'clothing_detail_screen.dart';
import '../widgets/paywall_widget.dart';
import '../widgets/occasion_selection_dialog.dart';

class AIStylistScreen extends StatefulWidget {
  const AIStylistScreen({super.key});

  @override
  State<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends State<AIStylistScreen>
{
  bool _isLoading = false;
  String _error = '';
  List<Combination> _combinations = [];
  final List<List<Clothing>> _outfitItems = [];
  int _currentOutfitIndex = 0;

  final List<String> _loadingMessages = [
    'Stil analizi yapılıyor...',
    'Kıyafetlerinizi detaylı inceliyoruz...',
    'Sezonun trendlerine göre kombinler oluşturuluyor...',
    'Renk uyumları ve desen analizleri yapılıyor...',
    'Özel stil önerileri hazırlanıyor...',
    'Profesyonel moda danışmanı önerileri derleniyor...',
    'Kişisel stil profiliniz oluşturuluyor...',
    'En trend kombinler seçiliyor...',
    'Son moda detaylar ekleniyor...',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startLoadingAnimation() {
    _currentMessageIndex = 0;
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  void _stopLoadingAnimation() {
    _messageTimer?.cancel();
  }

  Future<void> _generateOutfitSuggestion() async {
    // Check premium access
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscriptionProvider.isPremium) {
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage:
            'AI Stilist özelliği premium üyeler için kullanılabilir.',
      );
      return;
    }

    // Check if there are any clothing items
    final wardrobeItems = context.read<WardrobeProvider>().items;

    if (wardrobeItems.isEmpty) {
      setState(() {
        _error =
            'Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet eklemelisiniz.';
      });
      return;
    }

    // Show occasion selection dialog
    final selectedOccasion = await OccasionSelectionDialog.show(context);

    // If user cancelled, return
    if (selectedOccasion == null) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _combinations.clear();
      _outfitItems.clear();
    });

    _startLoadingAnimation();

    if (!mounted) return;
    final functions = context.read<CloudFunctionsService>();
    final firestore = context.read<FirestoreServiceBase>();
    final wardrobeProvider = context.read<WardrobeProvider>();
    final userId = wardrobeProvider.currentUserId;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    try {
      await functions.generateCombinations(userId, occasion: selectedOccasion);
      final combinations = await firestore.getCombinations(userId);
      if (!mounted) return;

      if (combinations.isNotEmpty) {
        setState(() {
          _combinations = combinations;
          _organizeOutfitItems();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              'Kombin oluşturmak için yeterli kıyafet bulunamadı. Daha fazla kıyafet eklemeyi deneyin.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Kombin oluşturulurken hata oluştu: $e';
          _isLoading = false;
        });
      }
    } finally {
      _stopLoadingAnimation();
    }
  }

  void _organizeOutfitItems() {
    _outfitItems.clear();
    final wardrobeItems = context.read<WardrobeProvider>().items;

    for (final combination in _combinations) {
      final outfitClothing = <Clothing>[];

      for (final item in combination.clothingItems) {
        final clothing = wardrobeItems.firstWhere(
          (c) => c.id == item.clothingId,
          orElse: () => Clothing(
            colors: [],
            id: item.clothingId,
            userId: '',
            title: 'Bulunamadı',
            category: item.category ?? 'unknown',
            imageUrl: '',
            imagePath: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        outfitClothing.add(clothing);
      }

      _outfitItems.add(outfitClothing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VestiyerPageHeader(
              title: 'AI Stilist',
              subtitle: 'Yapay zeka ile kombinler',
              showBackButton: true,
              onBack: () => Navigator.maybePop(context),
              actions: [
                if (_combinations.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.textPrimary.withValues(alpha: 0.7)),
                    onPressed: _generateOutfitSuggestion,
                    tooltip: 'Yeni Kombinler Oluştur',
                  ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _error.isNotEmpty
                      ? _buildErrorScreen()
                      : _combinations.isEmpty
                          ? _buildInitialScreen()
                          : _buildOutfitSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loadingMessages[_currentMessageIndex],
              key: ValueKey<int>(_currentMessageIndex),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lütfen bekleyin...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.textPrimary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Hata Oluştu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _error,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary.withValues(alpha: 0.1),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 60,
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'AI Stilist',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Yapay zeka ile mükemmel kombinler oluşturun',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generateOutfitSuggestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'Kombin Önerileri Oluştur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Kombin Önerileri',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
              ),
              Text(
                '${_combinations.length} özel kombin oluşturuldu',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CarouselSlider.builder(
            itemCount: _combinations.length,
            itemBuilder: (context, index, realIndex) {
              final combination = _combinations[index];
              final outfitClothing = _outfitItems[index];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: outfitClothing.length,
                        itemBuilder: (context, itemIndex) {
                          final clothing = outfitClothing[itemIndex];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClothingDetailScreen(item: clothing),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: CachedNetworkImage(
                                        imageUrl: clothing.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: AppColors.textPrimary.withValues(alpha: 0.05),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.textPrimary.withValues(alpha: 0.7),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: AppColors.textPrimary.withValues(alpha: 0.05),
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color:
                                                AppColors.textPrimary.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      child: Text(
                                        clothing.category,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            combination.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (combination.description != null &&
                              combination.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              combination.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary.withValues(alpha: 0.7),
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  combination.occasion,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  combination.season,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            options: CarouselOptions(
              height: double.infinity,
              viewportFraction: 0.85,
              enableInfiniteScroll: false,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentOutfitIndex = index;
                });
              },
            ),
          ),
        ),

        // Page indicators
        if (_combinations.length > 1)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _combinations.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentOutfitIndex == entry.key
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
