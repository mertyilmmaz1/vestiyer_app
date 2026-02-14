import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_spacing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vestiyer_nodejs/utils/clothing_formatter.dart';

import '../models/clothing.dart';
import '../models/combination.dart';
import '../providers/wardrobe_provider.dart';
import '../services/firestore_service_base.dart';
import '../widgets/vestiyer_page_header.dart';
import 'clothing_detail_screen.dart';
import 'outfit_history_screen.dart';

class OutfitSuggestionsScreen extends StatefulWidget {
  const OutfitSuggestionsScreen({super.key});

  @override
  State<OutfitSuggestionsScreen> createState() =>
      _OutfitSuggestionsScreenState();
}

class _OutfitSuggestionsScreenState extends State<OutfitSuggestionsScreen> {
  List<Combination> _combinations = [];
  final List<List<Clothing>> _outfitItems = [];
  bool _isLoading = false;

  final List<String> _loadingMessages = [
    'STİL ANALİZİ YAPILIYOR...',
    'EN İYİ KOMBİNLER SEÇİLİYOR...',
    'RENK UYUMLARI KONTROL EDİLİYOR...',
    'MEVSİM KOŞULLARI DEĞERLENDİRİLİYOR...',
    'KUMAŞ UYUMLARI ANALİZ EDİLİYOR...',
    'STİL ÖNERİLERİ HAZIRLANIYOR...',
    'KOMBİNLERİNİZ HAZIRLANIYOR...',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
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

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });
    _startLoadingAnimation();

    try {
      final firestore = context.read<FirestoreServiceBase>();
      final wardrobeProvider = context.read<WardrobeProvider>();

      final userId = wardrobeProvider.currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

      final userCombinations = await firestore.getCombinations(userId);

      setState(() {
        _combinations = userCombinations;
        _organizeOutfitItems();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kombinler yüklenirken hata oluştu: $e')),
        );
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

  Future<void> _showMarkAsWornDialog(
      BuildContext context, Combination combination) async {
    DateTime selected = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.black,
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
      helpText: 'KOMBİNİ NE ZAMAN GİYDİNİZ?',
    );
    if (picked == null || !context.mounted) return;
    selected = picked;
    await _markCombinationAsWorn(combination, selected);
  }

  Future<void> _markCombinationAsWorn(
      Combination combination, DateTime wornAt) async {
    final firestore = context.read<FirestoreServiceBase>();
    final userId = context.read<WardrobeProvider>().currentUserId;
    if (userId == null) return;
    try {
      await firestore.addOutfitLog(userId, {
        'combinationId': combination.id,
        'wornAt': wornAt,
        'combinationName': combination.name,
        'occasion': combination.occasion,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giyim kaydı eklendi')),
        );
        _loadSuggestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt eklenirken hata: $e')),
        );
      }
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
              title: 'Kombin Önerileri',
              subtitle: 'Kayıtlı kombinleriniz',
              showBackButton: true,
              onBack: () => Navigator.maybePop(context),
              actions: [
                IconButton(
                  icon: Icon(Icons.history, color: AppColors.textPrimary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      EditorialPageRoute(page: const OutfitHistoryScreen()),
                    );
                  },
                  tooltip: 'Giyim Geçmişi',
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.textPrimary),
                  onPressed: _loadSuggestions,
                  tooltip: 'Yenile',
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _combinations.isEmpty
                      ? _buildEmptyState()
                      : _buildCombinationsList(),
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
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.softBackground,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
                bottom: BorderSide(color: AppColors.border, width: 0.5),
                left: BorderSide(color: AppColors.border, width: 0.5),
                right: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                strokeWidth: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _loadingMessages[_currentMessageIndex],
                key: ValueKey<int>(_currentMessageIndex),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  letterSpacing: 2.0,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'HENÜZ KOMBİN YOK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary,
                letterSpacing: 2.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'AI Stilist\'ten yeni kombinler oluşturarak başlayın.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side:
                    const BorderSide(color: AppColors.textPrimary, width: 0.5),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'GERİ DÖN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinationsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _combinations.length,
      itemBuilder: (context, index) {
        final combination = _combinations[index];
        final outfitClothing = _outfitItems[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grid of items
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                ),
                itemCount: outfitClothing.length,
                itemBuilder: (context, itemIndex) {
                  final clothing = outfitClothing[itemIndex];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        EditorialPageRoute(
                          page: ClothingDetailScreen(item: clothing),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: clothing.displayImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.softBackground,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.softBackground,
                              child: const Icon(Icons.image_not_supported,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color:
                                  AppColors.background.withValues(alpha: 0.8),
                              child: Text(
                                ClothingFormatter.format(clothing.category)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1.0,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ClothingFormatter.format(combination.name)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2.0,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (combination.description != null &&
                                  combination.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  combination.description!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Text(
                            ClothingFormatter.format(combination.occasion)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            _showMarkAsWornDialog(context, combination),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(
                              color: AppColors.textPrimary, width: 0.5),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'BUGÜN GİYDİM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
