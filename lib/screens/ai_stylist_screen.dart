import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/clothing.dart';
import '../models/combination.dart';
import '../services/cloud_functions_service.dart';
import '../services/firestore_service_base.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'clothing_detail_screen.dart';
import '../widgets/paywall_widget.dart';
import '../widgets/occasion_selection_dialog.dart';

class AIStylistScreen extends StatefulWidget {
  const AIStylistScreen({super.key});

  @override
  State<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends State<AIStylistScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String _error = '';
  List<Combination> _combinations = [];
  final List<List<Clothing>> _outfitItems = [];
  int _currentOutfitIndex = 0;
  late AnimationController _controller;

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
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _controller.dispose();
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'AI Stilist',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_combinations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _generateOutfitSuggestion,
              tooltip: 'Yeni Kombinler Oluştur',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: BackgroundPainter(_controller.value),
              );
            },
          ),

          // Content
          SafeArea(
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
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
                      Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.6),
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
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lütfen bekleyin...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
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
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Hata Oluştu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
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
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 60,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'AI Stilist',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Yapay zeka ile mükemmel kombinler oluşturun',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
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
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Text(
                '${_combinations.length} özel kombin oluşturuldu',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
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
                          Text(
                            combination.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
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
                                        placeholder: (context, url) =>
                                            Container(
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
                                            color:
                                                Colors.white.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        clothing.category,
                                        style: const TextStyle(
                                          fontSize: 12,
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
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw dark background
    final backgroundGradient = const LinearGradient(
      colors: [
        Color(0xFF121212),
        Color(0xFF1A1A1A),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    paint.shader = backgroundGradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw animated gradient shapes
    final shapePaint = Paint()..style = PaintingStyle.fill;

    // First blob
    shapePaint.color = Colors.white.withValues(alpha: 0.03);
    final path1 = Path();
    final centerX1 = size.width * 0.2 + math.sin(animationValue * math.pi) * 40;
    final centerY1 =
        size.height * 0.2 + math.cos(animationValue * math.pi) * 40;
    final radius1 = size.width * 0.5;
    path1.addOval(
        Rect.fromCircle(center: Offset(centerX1, centerY1), radius: radius1));
    canvas.drawPath(path1, shapePaint);

    // Second blob
    shapePaint.color = Colors.white.withValues(alpha: 0.02);
    final path2 = Path();
    final centerX2 =
        size.width * 0.8 + math.cos(animationValue * 1.5 * math.pi) * 30;
    final centerY2 =
        size.height * 0.5 + math.sin(animationValue * 1.5 * math.pi) * 30;
    final radius2 = size.width * 0.4;
    path2.addOval(
        Rect.fromCircle(center: Offset(centerX2, centerY2), radius: radius2));
    canvas.drawPath(path2, shapePaint);

    // Third blob
    shapePaint.color = Colors.white.withValues(alpha: 0.01);
    final path3 = Path();
    final centerX3 =
        size.width * 0.5 + math.sin(animationValue * 2 * math.pi + 2) * 20;
    final centerY3 =
        size.height * 0.8 + math.cos(animationValue * 2 * math.pi + 2) * 20;
    final radius3 = size.width * 0.6;
    path3.addOval(
        Rect.fromCircle(center: Offset(centerX3, centerY3), radius: radius3));
    canvas.drawPath(path3, shapePaint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
