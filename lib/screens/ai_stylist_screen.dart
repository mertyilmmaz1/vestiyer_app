import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vestiyer_nodejs/utils/clothing_formatter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/clothing.dart';
import '../models/combination.dart';
import '../providers/locale_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/cloud_functions_service.dart';
import '../widgets/vestiyer_page_header.dart';
import 'clothing_detail_screen.dart';
import '../widgets/paywall_widget.dart';
import '../widgets/occasion_selection_dialog.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/staggered_slide_fade.dart';

class AIStylistScreen extends StatefulWidget {
  const AIStylistScreen({super.key});

  /// GlobalKey for the "KOMBİN OLUŞTUR" button.
  static final GlobalKey generateButtonKey = GlobalKey();

  @override
  State<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends State<AIStylistScreen> {
  static const String _cacheKeyPrefix = 'ai_stylist_state_v1_';

  bool _isLoading = false;
  String _error = '';
  List<Combination> _combinations = [];
  final List<List<Clothing>> _outfitItems = [];
  final Set<String> _savingCombinationIds = <String>{};
  final Set<String> _savedCombinationIds = <String>{};
  int _currentOutfitIndex = 0;
  String? _stylingAdvice;
  String? _stylingModeItemId;

  static const int _loadingMessagesCount = 9;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _loadCachedSuggestions();
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

  void _stopLoadingAnimation() {
    _messageTimer?.cancel();
  }

  Future<void> _loadCachedSuggestions() async {
    final userId = context.read<WardrobeProvider>().currentUserId;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cacheKeyPrefix$userId');
    if (raw == null || raw.isEmpty || !mounted) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final combinationsData = decoded['combinations'] as List<dynamic>? ?? [];
      final cachedCombinations = combinationsData
          .whereType<Map<String, dynamic>>()
          .map(Combination.fromJson)
          .toList();

      setState(() {
        _combinations = cachedCombinations;
        _stylingAdvice = decoded['stylingAdvice'] as String?;
        _stylingModeItemId = decoded['stylingModeItemId'] as String?;
        _currentOutfitIndex = 0;
        _organizeOutfitItems();
      });
    } catch (_) {
      // Ignore malformed cache.
    }
  }

  Future<void> _persistCurrentSuggestions() async {
    final userId = context.read<WardrobeProvider>().currentUserId;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'combinations': _combinations.map((e) => e.toJson()).toList(),
      'stylingAdvice': _stylingAdvice,
      'stylingModeItemId': _stylingModeItemId,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$_cacheKeyPrefix$userId', jsonEncode(payload));
  }

  Future<void> _generateOutfitSuggestion() async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    if (!subscriptionProvider.isPremium &&
        !subscriptionProvider.hasDailyFreeCombinationLeft) {
      final l10n = AppLocalizations.of(context);
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage: l10n.aiStylistPaywall,
      );
      return;
    }

    final wardrobeItems = context.read<WardrobeProvider>().items;

    if (wardrobeItems.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context).aiStylistEmptyWardrobe;
      });
      return;
    }

    final selectedOccasion = await OccasionSelectionDialog.show(context);
    if (selectedOccasion == null) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    _startLoadingAnimation();

    if (!mounted) return;
    final functions = context.read<CloudFunctionsService>();
    final wardrobeProvider = context.read<WardrobeProvider>();
    final locale = context.read<LocaleProvider>().languageCode;
    final userId = wardrobeProvider.currentUserId;
    if (userId == null)
      throw Exception(AppLocalizations.of(context).outfitHistoryNotSignedIn);

    try {
      final result = await functions.generateCombinations(
        userId,
        occasion: selectedOccasion,
        locale: locale,
      );

      if (!mounted) return;

      final mode = result['mode'] as String?;

      if (mode == 'styling') {
        if (!subscriptionProvider.isPremium) {
          await subscriptionProvider.useDailyFreeCombination();
        }
        if (!mounted) return;
        final adviceData = result['stylingAdvice'] as Map<String, dynamic>?;
        final advice = adviceData?['advice'] as String?;
        final itemId = adviceData?['itemId'] as String?;
        setState(() {
          _combinations = [];
          _outfitItems.clear();
          _savingCombinationIds.clear();
          _savedCombinationIds.clear();
          _stylingAdvice = advice ?? '';
          _stylingModeItemId = itemId;
          _currentOutfitIndex = 0;
          _isLoading = false;
        });
        await _persistCurrentSuggestions();
        return;
      }

      final combinationsData = result['combinations'] as List<dynamic>?;

      if (combinationsData != null && combinationsData.isNotEmpty) {
        final List<Combination> newCombinations =
            combinationsData.map((comboJson) {
          final items = (comboJson['items'] as List<dynamic>? ?? [])
              .map((id) => {'clothingId': id, 'isRequired': true})
              .toList();

          return Combination.fromJson({
            ...Map<String, dynamic>.from(comboJson as Map),
            'id':
                'temp_${DateTime.now().millisecondsSinceEpoch}_${combinationsData.indexOf(comboJson)}',
            'userId': userId,
            'clothingItems': items,
            'isAIGenerated': true,
            'isFavorite': false,
            'timesWorn': 0,
            'tags': [],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }).toList();

        if (!subscriptionProvider.isPremium) {
          await subscriptionProvider.useDailyFreeCombination();
        }
        if (!mounted) return;
        setState(() {
          _combinations = newCombinations;
          _savingCombinationIds.clear();
          _savedCombinationIds.clear();
          _stylingAdvice = null;
          _stylingModeItemId = null;
          _currentOutfitIndex = 0;
          _organizeOutfitItems();
          _isLoading = false;
        });
        await _persistCurrentSuggestions();
      } else {
        setState(() {
          _error = AppLocalizations.of(context).aiStylistInsufficientItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).aiStylistError;
          _isLoading = false;
        });
      }
    } finally {
      _stopLoadingAnimation();
    }
  }

  Future<void> _saveCombination(Combination combination) async {
    final userId = context.read<WardrobeProvider>().currentUserId;
    if (userId == null) return;
    if (_savingCombinationIds.contains(combination.id)) return;
    if (_savedCombinationIds.contains(combination.id)) return;

    setState(() {
      _savingCombinationIds.add(combination.id);
    });

    try {
      final functions = context.read<CloudFunctionsService>();
      final locale = context.read<LocaleProvider>().languageCode;
      final result = await functions.saveCombination(userId, combination,
          locale: locale);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).aiStylistSaveSuccess),
              backgroundColor: AppColors.textPrimary,
            ),
          );
          setState(() {
            _savedCombinationIds.add(combination.id);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).aiStylistSaveError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingCombinationIds.remove(combination.id);
        });
      }
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
            title: AppLocalizations.of(context).aiStylistNotFound,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VestiyerPageHeader(
          title: AppLocalizations.of(context).aiStylistTitle,
          subtitle: AppLocalizations.of(context).aiStylistSubtitle,
          showBackButton: false,
          actions: [
            if (_combinations.isNotEmpty || _stylingAdvice != null)
              IconButton(
                icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedRefresh,
                    color: AppColors.textPrimary),
                onPressed: _generateOutfitSuggestion,
                tooltip: AppLocalizations.of(context).aiStylistRefresh,
              ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? _buildLoadingScreen()
              : _error.isNotEmpty
                  ? _buildErrorScreen()
                  : _stylingAdvice != null
                      ? _buildStylingAdviceScreen()
                      : _combinations.isEmpty
                          ? _buildInitialScreen()
                          : _buildOutfitSuggestions(),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    final l10n = AppLocalizations.of(context);
    final messages = [
      l10n.aiStylistLoading1,
      l10n.aiStylistLoading2,
      l10n.aiStylistLoading3,
      l10n.aiStylistLoading4,
      l10n.aiStylistLoading5,
      l10n.aiStylistLoading6,
      l10n.aiStylistLoading7,
      l10n.aiStylistLoading8,
      l10n.aiStylistLoading9,
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
                  fontSize: 14,
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
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              _error,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _error = '';
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side:
                    const BorderSide(color: AppColors.textPrimary, width: 0.5),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(AppLocalizations.of(context).aiStylistRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedMagicWand01,
                size: 48,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              AppLocalizations.of(context).aiStylistInitialTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary,
                letterSpacing: 2.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).aiStylistInitialDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary.withValues(alpha: 0.6),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            SizedBox(
              key: AIStylistScreen.generateButtonKey,
              width: double.infinity,
              height: 56,
              child: BouncingWidget(
                child: ElevatedButton(
                  onPressed: _generateOutfitSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).aiStylistGenerate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                    ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.aiStylistSuggestionsHeader(
                    _currentOutfitIndex + 1, _combinations.length),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              // Indicators
              if (_combinations.length > 1)
                Row(
                  children: _combinations.asMap().entries.map((entry) {
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: _currentOutfitIndex == entry.key
                            ? AppColors.textPrimary
                            : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        Expanded(
          child: CarouselSlider.builder(
            itemCount: _combinations.length,
            options: CarouselOptions(
              height: double.infinity,
              viewportFraction: 0.85,
              enableInfiniteScroll: false,
              enlargeCenterPage: true,
              scrollPhysics: const BouncingScrollPhysics(),
              onPageChanged: (index, reason) {
                setState(() {
                  _currentOutfitIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final combination = _combinations[index];
              final outfitClothing = _outfitItems[index];
              final isSaving = _savingCombinationIds.contains(combination.id);
              final isSaved = _savedCombinationIds.contains(combination.id);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    // Grid of items
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        physics: const NeverScrollableScrollPhysics(),
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
                          return StaggeredSlideFade(
                            index: itemIndex,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  EditorialPageRoute(
                                    page: ClothingDetailScreen(item: clothing),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.border,
                                            width: 0.5),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: clothing.displayImageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: AppColors.softBackground,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ClothingFormatter.format(
                                            context, clothing.category)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Info Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border, width: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ClothingFormatter.format(
                                          context, combination.name)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.5,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.border, width: 0.5),
                                ),
                                child: Text(
                                  ClothingFormatter.format(
                                          context, combination.occasion)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (combination.description != null &&
                              combination.description!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: AppColors.background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                      side: BorderSide(
                                          color: AppColors.border, width: 0.5),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)
                                                .aiStylistDetailTitle,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: 1.5,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            combination.description!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w300,
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.9),
                                              height: 1.6,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              AppLocalizations.of(context)
                                                  .aiStylistClose,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                combination.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: (isSaving || isSaved)
                                  ? null
                                  : () => _saveCombination(combination),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(
                                    color: AppColors.textPrimary, width: 0.5),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.textPrimary),
                                      ),
                                    )
                                  : Text(
                                      isSaved
                                          ? l10n.aiStylistSaved
                                          : l10n.aiStylistSave,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 1.5,
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
          ),
        ),
      ],
    );
  }

  Widget _buildStylingAdviceScreen() {
    final l10n = AppLocalizations.of(context);
    final wardrobeItems = context.read<WardrobeProvider>().items;
    Clothing? styledItem;
    if (_stylingModeItemId != null) {
      try {
        styledItem =
            wardrobeItems.firstWhere((c) => c.id == _stylingModeItemId);
      } catch (_) {}
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (styledItem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      EditorialPageRoute(
                        page: ClothingDetailScreen(item: styledItem!),
                      ),
                    );
                  },
                  child: Container(
                    width: 150,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: styledItem.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            Text(
              l10n.aiStylistAdviceTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 3.0,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.aiStylistAdviceDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary.withValues(alpha: 0.6),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.softBackground,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                _stylingAdvice ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.aiStylistAdviceTip,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
