import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/firestore_service_base.dart';
import '../widgets/paywall_widget.dart';
import '../widgets/vestiyer_page_header.dart';
import 'dart:async';

class WardrobeAnalysisScreen extends StatefulWidget {
  const WardrobeAnalysisScreen({super.key});

  @override
  State<WardrobeAnalysisScreen> createState() => _WardrobeAnalysisScreenState();
}

class _WardrobeAnalysisScreenState extends State<WardrobeAnalysisScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _analysisData;
  Timer? _messageTimer;

  final List<String> _loadingMessages = [
    'Gardırobunuzu analiz ediyoruz...',
    'Stil tercihleriniz inceleniyor...',
    'Renk paleitleri değerlendiriliyor...',
    'Mevsimlik dağılımlar hesaplanıyor...',
    'Kombin fırsatları keşfediliyor...',
    'Öneriler hazırlanıyor...',
    'Stil profili oluşturuluyor...',
    'Alışveriş tavsiyeleri listeliyor...',
    'Son rötuşlar yapılıyor...',
  ];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
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

  void _startAnalysis() async {
    if (!mounted) return;

    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    // Check if user is premium or show paywall
    if (!subscriptionProvider.isPremium) {
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage:
            'Gardırop analizi ve alışveriş önerileri premium bir özelliktir.',
      );
      if (!mounted) return;
      if (!subscriptionProvider.isPremium) {
        Navigator.pop(context);
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _startLoadingAnimation();

    if (!mounted) return;
    try {
      final wardrobeProvider = context.read<WardrobeProvider>();
      final categoryStats = wardrobeProvider.getCategoryStats();
      final seasonStats = wardrobeProvider.getSeasonStats();
      final items = wardrobeProvider.items;
      final styleDistribution = <String, int>{};
      for (final item in items) {
        final style = item.advancedAnalysis?.style ?? 'Belirsiz';
        styleDistribution[style] = (styleDistribution[style] ?? 0) + 1;
      }
      final now = DateTime.now();
      final month = now.month;
      final currentSeason = month >= 3 && month <= 5
          ? 'İlkbahar'
          : month >= 6 && month <= 8
              ? 'Yaz'
              : month >= 9 && month <= 11
                  ? 'Sonbahar'
                  : 'Kış';
      final currentSeasonItems = items
          .where((c) =>
              c.advancedAnalysis?.season?.toLowerCase().contains(currentSeason.toLowerCase()) ==
                  true ||
              c.advancedAnalysis?.season?.toLowerCase() == 'tüm sezon' ||
              c.advancedAnalysis?.season?.toLowerCase() == 'all-season')
          .length;
      final statistics = {
        'totalItems': items.length,
        'currentSeason': currentSeason,
        'categoryCounts': categoryStats,
        'seasonCounts': seasonStats,
        'currentSeasonItems': currentSeasonItems,
        'styleDistribution': styleDistribution,
      };

      if (mounted) {
        final analysisData = _convertStatisticsToAnalysisData(statistics);
        setState(() {
          _analysisData = analysisData;
          _isLoading = false;
        });
        final userId = wardrobeProvider.currentUserId;
        if (userId != null) {
          final firestore = context.read<FirestoreServiceBase>();
          final toSave = Map<String, dynamic>.from(analysisData);
          toSave['updatedAt'] = DateTime.now().toIso8601String();
          await firestore.setWardrobeAnalysis(userId, toSave);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      _stopLoadingAnimation();
    }
  }

  Map<String, dynamic> _convertStatisticsToAnalysisData(
      Map<String, dynamic> stats) {
    return {
      'statistics': {
        'total_items': stats['totalItems'] ?? 0,
        'current_season': stats['currentSeason'] ?? 'unknown',
        'category_counts': stats['categoryCounts'] ?? {},
        'season_counts': stats['seasonCounts'] ?? {},
        'current_season_items': stats['currentSeasonItems'] ?? 0,
        'style_distribution': stats['styleDistribution'] ?? {},
      },
      'recommendations': _generateRecommendations(stats),
      'style_analysis': _generateStyleAnalysis(stats),
      'seasonal_analysis': _generateSeasonalAnalysis(stats),
    };
  }

  List<String> _generateRecommendations(Map<String, dynamic> stats) {
    final recommendations = <String>[];
    final totalItems = stats['totalItems'] ?? 0;
    final categoryCounts = Map<String, int>.from(stats['categoryCounts'] ?? {});
    final seasonCounts = Map<String, int>.from(stats['seasonCounts'] ?? {});

    if (totalItems < 10) {
      recommendations.add(
          'Dolabınızı genişletmek için daha fazla kıyafet eklemeyi düşünün.');
    }

    // Category recommendations
    if (categoryCounts['top'] != null && categoryCounts['bottom'] != null) {
      final topCount = categoryCounts['top']!;
      final bottomCount = categoryCounts['bottom']!;

      if (topCount > bottomCount * 2) {
        recommendations.add(
            'Alt giyim seçeneklerinizi artırarak kombin çeşitliliği yaratabilirsiniz.');
      } else if (bottomCount > topCount * 2) {
        recommendations.add(
            'Üst giyim seçeneklerinizi artırarak daha fazla stil yaratabilirsiniz.');
      }
    }

    // Season recommendations
    final currentSeason = stats['currentSeason'] ?? '';
    if (seasonCounts[currentSeason] != null &&
        seasonCounts[currentSeason]! < 5) {
      recommendations
          .add('Mevcut mevsim için daha fazla kıyafet eklemeyi düşünün.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Dolabınız güzel bir denge içinde görünüyor!');
    }

    return recommendations;
  }

  String _generateStyleAnalysis(Map<String, dynamic> stats) {
    final styleDistribution =
        Map<String, int>.from(stats['styleDistribution'] ?? {});
    final totalItems = stats['totalItems'] ?? 0;

    if (totalItems == 0) {
      return 'Henüz stil analizi için yeterli kıyafet bulunmuyor.';
    }

    final dominantStyle =
        styleDistribution.entries.reduce((a, b) => a.value > b.value ? a : b);

    return 'Dolabınızda ${dominantStyle.key} tarzı hakimdir (${((dominantStyle.value / totalItems) * 100).round()}%). '
        'Bu, ${_getStyleDescription(dominantStyle.key)} kişiliğinizi yansıtıyor.';
  }

  String _generateSeasonalAnalysis(Map<String, dynamic> stats) {
    final currentSeason = stats['currentSeason'] ?? '';
    final currentSeasonItems = stats['currentSeasonItems'] ?? 0;
    final totalItems = stats['totalItems'] ?? 0;

    if (totalItems == 0) {
      return 'Henüz mevsimsel analiz için yeterli kıyafet bulunmuyor.';
    }

    return 'Dolabınızda ${_getSeasonName(currentSeason)} mevsimine uygun $currentSeasonItems kıyafet bulunuyor. '
        'Bu, toplam dolabınızın %${((currentSeasonItems / totalItems) * 100).round()}\'ını oluşturuyor.';
  }

  String _getStyleDescription(String style) {
    switch (style.toLowerCase()) {
      case 'casual':
        return 'rahat ve günlük';
      case 'formal':
        return 'şık ve profesyonel';
      case 'sporty':
        return 'aktif ve dinamik';
      default:
        return 'kendine özgü';
    }
  }

  String _getSeasonName(String season) {
    switch (season.toLowerCase()) {
      case 'spring':
        return 'ilkbahar';
      case 'summer':
        return 'yaz';
      case 'autumn':
      case 'fall':
        return 'sonbahar';
      case 'winter':
        return 'kış';
      default:
        return season;
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
              title: 'Gardırop Analizi',
              subtitle: 'Stil önerileri',
              showBackButton: true,
              onBack: () => Navigator.maybePop(context),
              actions: [
                if (_analysisData != null)
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.textPrimary.withValues(alpha: 0.7)),
                    onPressed: _startAnalysis,
                    tooltip: 'Yeni Analiz',
                  ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _hasError
                      ? _buildErrorScreen()
                      : _analysisData == null
                          ? _buildIntroScreen()
                          : _buildAnalysisResults(),
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
                  Icons.analytics,
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
            'Bu işlem birkaç dakika sürebilir...',
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
              'Analiz Başarısız',
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
                _errorMessage,
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
              onPressed: _startAnalysis,
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

  Widget _buildIntroScreen() {
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
                Icons.analytics_outlined,
                size: 60,
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Gardırop Analizi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dolabınızı analiz ederek kişisel stil önerilerinizi keşfedin',
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
                onPressed: _startAnalysis,
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
                icon: const Icon(Icons.analytics),
                label: const Text(
                  'Analizi Başlat',
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

  Widget _buildAnalysisResults() {
    final statistics = _analysisData!['statistics'] as Map<String, dynamic>;
    final recommendations = _analysisData!['recommendations'] as List<String>;
    final styleAnalysis = _analysisData!['style_analysis'] as String;
    final seasonalAnalysis = _analysisData!['seasonal_analysis'] as String;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiz Sonuçları',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Cards
          _buildStatisticsCard(statistics),
          const SizedBox(height: 24),

          // Style Analysis
          _buildAnalysisCard(
            'Stil Analizi',
            styleAnalysis,
            Icons.style_outlined,
            AppColors.primary,
          ),
          const SizedBox(height: 16),

          // Seasonal Analysis
          _buildAnalysisCard(
            'Mevsimsel Analiz',
            seasonalAnalysis,
            Icons.wb_sunny_outlined,
            AppColors.primary,
          ),
          const SizedBox(height: 24),

          // Recommendations
          _buildRecommendationsCard(recommendations),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> statistics) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Dolap İstatistikleri',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Toplam Kıyafet',
                  '${statistics['total_items']}',
                  Icons.checkroom,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Mevcut Mevsim',
                  '${statistics['current_season_items']}',
                  Icons.wb_sunny,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Kategori Dağılımı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...((statistics['category_counts'] as Map<String, dynamic>?)
                      ?.entries ??
                  [])
              .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getCategoryName(entry.key),
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.textPrimary.withValues(alpha: 0.7),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
      String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Öneriler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'top':
        return 'Üst Giyim';
      case 'bottom':
        return 'Alt Giyim';
      case 'shoes':
        return 'Ayakkabı';
      case 'accessory':
        return 'Aksesuar';
      case 'outerwear':
        return 'Dış Giyim';
      default:
        return category;
    }
  }
}
