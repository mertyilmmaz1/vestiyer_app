import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import '../models/clothing.dart';
import '../models/combination.dart';
import '../services/firestore_service_base.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'clothing_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Kombin Önerileri',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadSuggestions,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _combinations.isEmpty
              ? _buildEmptyState()
              : _buildCombinationsList(),
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
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                color: Colors.white,
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
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Kombin Yok',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI Stilist\'ten yeni kombinler oluşturarak başlayın',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(16),
      itemCount: _combinations.length,
      itemBuilder: (context, index) {
        final combination = _combinations[index];
        final outfitClothing = _outfitItems[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            combination.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (combination.isFavorite)
                          Icon(
                            Icons.favorite,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      combination.description ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            combination.occasion,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            combination.season,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (combination.isAIGenerated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: Colors.purple.shade300,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade300,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 140,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
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
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: clothing.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white70,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  clothing.category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
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
            ],
          ),
        );
      },
    );
  }
}
