import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_typography.dart';
import '../providers/locale_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../services/cloud_functions_service.dart';
import '../widgets/vestiyer_page_header.dart';
import '../widgets/staggered_slide_fade.dart';

class ShoppingSuggestionsScreen extends StatefulWidget {
  const ShoppingSuggestionsScreen({super.key});

  @override
  State<ShoppingSuggestionsScreen> createState() =>
      _ShoppingSuggestionsScreenState();
}

class _ShoppingSuggestionsScreenState extends State<ShoppingSuggestionsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _suggestions;

  static const int _loadingMessagesCount = 6;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startLoadingAnimation() {
    _currentMessageIndex = 0;
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessagesCount;
        });
      }
    });
  }

  Future<void> _fetchSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _startLoadingAnimation();

    try {
      final functions = context.read<CloudFunctionsService>();
      final wardrobeProvider = context.read<WardrobeProvider>();
      final locale = context.read<LocaleProvider>().languageCode;
      final userId = wardrobeProvider.currentUserId;
      if (userId == null) throw Exception(AppLocalizations.of(context)!.shoppingLoginRequired);

      final summary = wardrobeProvider.getWardrobeSummary();
      final result = await functions.getShoppingSuggestions(userId,
          wardrobeSummary: summary, locale: locale);

      final rawSuggestions = result['suggestions'];
      if (rawSuggestions is! Map) {
        throw Exception(AppLocalizations.of(context)!.shoppingInvalidFormat);
      }

      if (mounted) {
        setState(() {
          _suggestions = Map<String, dynamic>.from(rawSuggestions);
          _isLoading = false;
        });
      }
    } catch (e) {
      final fallback = _buildFallbackSuggestions();
      if (mounted) {
        setState(() {
          _suggestions = fallback;
          _error = null;
          _isLoading = false;
        });
      }
    } finally {
      _messageTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            VestiyerPageHeader(
              title: AppLocalizations.of(context)!.shoppingTitle,
              subtitle: AppLocalizations.of(context)!.shoppingSubtitle,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
              actions: [
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: _fetchSuggestions,
                  ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _error != null
                      ? _buildErrorScreen()
                      : _buildSuggestionsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final l10n = AppLocalizations.of(context)!;
    final messages = [
      l10n.shoppingLoading1,
      l10n.shoppingLoading2,
      l10n.shoppingLoading3,
      l10n.shoppingLoading4,
      l10n.shoppingLoading5,
      l10n.shoppingLoading6,
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LinearProgressIndicator(
              color: AppColors.textPrimary,
              backgroundColor: AppColors.softBackground,
              minHeight: 1,
            ),
            const SizedBox(height: 48),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                messages[_currentMessageIndex % messages.length],
                key: ValueKey<int>(_currentMessageIndex),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _fetchSuggestions,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(
                      color: AppColors.textPrimary, width: 0.5),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(AppLocalizations.of(context)!.shoppingRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsContent() {
    if (_suggestions == null) return const SizedBox();

    final missing = (_suggestions!['missingEssensials'] ??
            _suggestions!['missingEssentials']) as List? ??
        [];
    final complementary =
        _suggestions!['complementarySuggestions'] as List? ?? [];
    final seasonal = _suggestions!['seasonalEssentials'] as List? ?? [];
    final isFallback = _suggestions!['_isFallback'] == true;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        if (isFallback) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softBackground,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.shoppingFallbackNotice,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (missing.isNotEmpty) ...[
          _buildSectionHeader(
              AppLocalizations.of(context)!.shoppingEssentials, Icons.inventory_2_outlined),
          ...missing.asMap().entries.map((e) => StaggeredSlideFade(
                index: e.key,
                child: _buildSuggestionCard(
                  title: e.value['item'],
                  subtitle: e.value['reason'],
                  detail: 'Uyum: ${e.value['compatibility']}',
                  icon: Icons.check_circle_outline,
                ),
              )),
          const SizedBox(height: 32),
        ],
        if (complementary.isNotEmpty) ...[
          _buildSectionHeader(AppLocalizations.of(context)!.shoppingComplementary, Icons.add_circle_outline),
          ...complementary.asMap().entries.map((e) => StaggeredSlideFade(
                index: e.key + missing.length,
                child: _buildSuggestionCard(
                  title: e.value['item'],
                  subtitle:
                      'Dolabındaki "${e.value['completes']}" ile harika durur.',
                  detail: e.value['styleTip'],
                  icon: Icons.auto_awesome_outlined,
                ),
              )),
          const SizedBox(height: 32),
        ],
        if (seasonal.isNotEmpty) ...[
          _buildSectionHeader(
              AppLocalizations.of(context)!.shoppingSeasonal, Icons.calendar_today_outlined),
          ...seasonal.asMap().entries.map((e) => StaggeredSlideFade(
                index: e.key + missing.length + complementary.length,
                child: _buildSuggestionCard(
                  title: e.value['item'],
                  subtitle: e.value['reason'],
                  icon: Icons.star_border,
                ),
              )),
        ],
      ],
    );
  }

  Map<String, dynamic> _buildFallbackSuggestions() {
    final summary = context.read<WardrobeProvider>().getWardrobeSummary();
    final categories = Map<String, dynamic>.from(summary['categories'] ?? {});

    int countFor(List<String> aliases) {
      var total = 0;
      for (final entry in categories.entries) {
        final key = entry.key.toLowerCase();
        if (aliases.any((a) => key.contains(a))) {
          total += (entry.value as num?)?.toInt() ?? 0;
        }
      }
      return total;
    }

    final hasTop = countFor(['top', 'ust', 'üst', 'gomlek', 'gömlek']) > 0;
    final hasBottom = countFor(['bottom', 'alt', 'pantolon', 'etek']) > 0;
    final hasShoes = countFor(['shoe', 'ayakk']) > 0;
    final hasOuterwear = countFor(['ceket', 'mont', 'dis', 'dış', 'outer']) > 0;

    final missing = <Map<String, dynamic>>[];
    if (!hasTop) {
      missing.add({
        'item': 'Nötr Renk Basic Üst',
        'reason':
            'Alt giyim parçalarını daha çok kombinleyebilmek için temel bir üst gerekli.',
        'compatibility': 'Pantolon ve eteklerle kolayca eşleşir',
      });
    }
    if (!hasBottom) {
      missing.add({
        'item': 'Düz Kesim Pantolon',
        'reason':
            'Üst parçaları dengelemek için çok amaçlı bir alt giyim parçası eksik.',
        'compatibility': 'Gömlek, tişört ve triko ile uyumlu',
      });
    }
    if (!hasShoes) {
      missing.add({
        'item': 'Minimal Sneaker veya Loafer',
        'reason': 'Kombinleri tamamlayacak temel ayakkabı eksik görünüyor.',
        'compatibility': 'Günlük ve smart-casual kombinlere uyum sağlar',
      });
    }
    if (!hasOuterwear) {
      missing.add({
        'item': 'Hafif Ceket/Blazer',
        'reason': 'Katmanlı görünüm için dış giyim alternatifi gerekli.',
        'compatibility': 'Üst ve alt kombinleri daha şık hale getirir',
      });
    }

    return {
      '_isFallback': true,
      'missingEssensials': missing,
      'complementarySuggestions': [
        {
          'item': 'Tek renk kemer/çanta',
          'completes': 'Mevcut günlük kombinler',
          'styleTip':
              'Aksesuar rengini ayakkabı tonuna yaklaştırarak daha derli toplu bir görünüm elde edebilirsiniz.',
        },
        {
          'item': 'Doku kontrastlı üst parça',
          'completes': 'Temel alt giyim parçaları',
          'styleTip':
              'Pamuk-triko veya denim-gömlek gibi doku farkları kombin derinliğini artırır.',
        },
      ],
      'seasonalEssentials': [
        {
          'item': 'Mevsime uygun ince katman parçası',
          'reason':
              'Sıcaklık geçişlerinde konforu korurken aynı kombinleri farklı havalarda kullanmanızı sağlar.',
        },
      ],
    };
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({
    required String title,
    required String subtitle,
    String? detail,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.softBackground,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 22, color: AppColors.textPrimary.withValues(alpha: 0.8)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
