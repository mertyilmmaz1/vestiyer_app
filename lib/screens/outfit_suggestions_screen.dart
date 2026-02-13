import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    'Stil analizi yapılıyor...',
    'En iyi kombinler seçiliyor...',
    'Renk uyumları kontrol ediliyor...',
    'Mevsim koşulları değerlendiriliyor...',
    'Kumaş uyumları analiz ediliyor...',
    'Stil önerileri hazırlanıyor...',
    'Kombinleriniz hazırlanıyor...',
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

  Future<void> _showMarkAsWornDialog(BuildContext context, Combination combination) async {
    DateTime selected = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Kombini ne zaman giydiniz?',
    );
    if (picked == null || !context.mounted) return;
    selected = picked;
    await _markCombinationAsWorn(combination, selected);
  }

  Future<void> _markCombinationAsWorn(Combination combination, DateTime wornAt) async {
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
                  icon: Icon(Icons.history, color: AppColors.textPrimary.withValues(alpha: 0.7)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OutfitHistoryScreen()),
                    );
                  },
                  tooltip: 'Giyim geçmişi',
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.textPrimary.withValues(alpha: 0.7)),
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
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loadingMessages[_currentMessageIndex],
              key: ValueKey<int>(_currentMessageIndex),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 80,
              color: AppColors.textPrimary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Kombin Yok',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI Stilist\'ten yeni kombinler oluşturarak başlayın',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary.withValues(alpha: 0.1),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinationsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _combinations.length,
      itemBuilder: (context, index) {
        final combination = _combinations[index];
        final outfitClothing = _outfitItems[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: clothing.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
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
                                      color: AppColors.textPrimary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: Text(
                                  clothing.category,
                                  style: const TextStyle(
                                    fontSize: 10,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            combination.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (combination.isFavorite)
                          Icon(
                            Icons.favorite,
                            color: AppColors.primary,
                            size: 18,
                          ),
                      ],
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
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
                        if (combination.isAIGenerated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 11,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showMarkAsWornDialog(context, combination),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Bugün giydim'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary.withValues(alpha: 0.9),
                        side: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
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
