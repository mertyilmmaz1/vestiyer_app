import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_spacing.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_typography.dart';
import 'upload_screen.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/paywall_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wardrobe_analysis_screen.dart';
import 'assistant_chat_screen.dart';
import '../models/clothing.dart';
import '../widgets/home_page_header.dart';
import '../widgets/assistant_card.dart';
import '../widgets/circle_feature_grid.dart';
import '../widgets/horizontal_wardrobe_strip.dart';

import '../constants/style_dna_constants.dart';
import 'clothing_detail_screen.dart';
import 'outfit_suggestions_screen.dart';
import 'premium_screen.dart';
import 'ai_stylist_screen.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/staggered_slide_fade.dart';
import 'shopping_suggestions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onSelectTab,
  });

  /// When provided (e.g. from bottom nav shell), use to switch tab instead of push.
  final void Function(int index)? onSelectTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasSeenIntro = false;
  final _assistantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIntroFlag();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShowPaywall();
    });
  }

  @override
  void dispose() {
    _assistantController.dispose();
    super.dispose();
  }

  Future<void> _loadIntroFlag() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;
    });
  }

  Future<void> _setIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);
    setState(() => _hasSeenIntro = true);
  }

  Future<void> _checkShowPaywall() async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    if (subscriptionProvider.isPremium) return;
    if (!subscriptionProvider.canShowPaywallAgain) return;
    final shouldShow = subscriptionProvider.shouldShowPaywall();
    if (shouldShow && mounted) {
      final l10n = AppLocalizations.of(context);
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage: l10n.homePaywallOptimize,
      );
    }
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      EditorialPageRoute(page: screen),
    );
  }

  void _openUpload() {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    if (!subscriptionProvider.canAddClothing()) {
      final l10n = AppLocalizations.of(context);
      PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage: l10n.homePaywallLimit,
      );
      return;
    }
    _push(const UploadScreen());
  }

  void _openAssistantChat() async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    if (!subscriptionProvider.isPremium) {
      final l10n = AppLocalizations.of(context);
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage: l10n.homePaywallAssistant,
      );
      return;
    }

    final text = _assistantController.text.trim();
    _push(AssistantChatScreen(
      initialMessage: text.isEmpty ? null : text,
    ));
  }

  Future<void> _openShoppingSuggestions() async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    if (!subscriptionProvider.isPremium) {
      final l10n = AppLocalizations.of(context);
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage: l10n.homePaywallShopping,
      );
      return;
    }
    _push(const ShoppingSuggestionsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final user = subscriptionProvider.currentUser;
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final items = wardrobeProvider.items;
    final count = items.length;
    final canShowDailyOutfitSuggestion = subscriptionProvider.isPremium &&
        _hasEnoughClothesForDailyOutfit(items);

    final l10n = AppLocalizations.of(context);
    final subtitle = count == 0
        ? l10n.homeSubtitleEmpty
        : l10n.homeSubtitleCount(count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── HEADER (Greeting + Subtitle) ───
        HomePageHeader(
          firstName: user?.firstName,
          subtitle: subtitle,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── DOLAP DURUMU (Zara editöryal minimal bar) ───
                const SizedBox(height: AppSpacing.lg),
                StaggeredSlideFade(
                  index: 1,
                  child:
                      _buildWardrobeCompletionCard(count, subscriptionProvider),
                ),

                if (canShowDailyOutfitSuggestion) ...[
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredSlideFade(
                    index: 2,
                    child: _buildDailyOutfitSuggestionCard(),
                  ),
                ],

                // ─── STİL ASİSTANI ───
                const SizedBox(height: AppSpacing.lg),
                StaggeredSlideFade(
                  index: 3,
                  child: AssistantCard(
                    showProBadge: subscriptionProvider.isPremium,
                    controller: _assistantController,
                    onSend: _openAssistantChat,
                  ),
                ),

                // ─── ÖZELLİK GRID (Zara: kare ikonlar) ───
                const SizedBox(height: AppSpacing.lg),
                StaggeredSlideFade(
                  index: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(l10n.homeExplore),
                      const SizedBox(height: AppSpacing.lg),
                      CircleFeatureGrid(
                        items: [
                          CircleFeatureItem(
                            icon: HugeIcons.strokeRoundedMagicWand01,
                            label: l10n.homeFeatureAiStylist,
                            onTap: () {
                              if (widget.onSelectTab != null) {
                                widget.onSelectTab!(2);
                                return;
                              }
                              _push(const AIStylistScreen());
                            },
                          ),
                          CircleFeatureItem(
                            icon: HugeIcons.strokeRoundedAnalytics01,
                            label: l10n.homeFeatureWardrobeAnalysis,
                            onTap: () => _push(const WardrobeAnalysisScreen()),
                          ),
                          CircleFeatureItem(
                            icon: HugeIcons.strokeRoundedClothes,
                            label: l10n.homeFeatureCombinations,
                            onTap: () => _push(const OutfitSuggestionsScreen()),
                          ),
                          CircleFeatureItem(
                            icon: HugeIcons.strokeRoundedTask01,
                            label: l10n.homeFeatureStyleAssistant,
                            onTap: _openAssistantChat,
                          ),
                          CircleFeatureItem(
                            icon: HugeIcons.strokeRoundedImage01,
                            label: l10n.homeFeatureShoppingSuggestions,
                            onTap: _openShoppingSuggestions,
                          ),
                          CircleFeatureItem(
                            icon: HugeIcons.strokeRoundedCamera01,
                            label: l10n.homeFeatureAddClothing,
                            onTap: _openUpload,
                          ),
                          CircleFeatureItem(
                            icon: HugeIcons.strokeRoundedDiamond,
                            label: l10n.homeFeaturePremium,
                            isHighlight: true,
                            onTap: () => _push(const PremiumScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── GİRİŞ KARTI ───
                StaggeredSlideFade(
                  index: 5,
                  child: _buildIntroductionCard(context),
                ),

                // ─── GARDROP ŞERİDİ (Zara ürün grid stili) ───
                const SizedBox(height: AppSpacing.lg),
                StaggeredSlideFade(
                  index: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Container(
                          height: 0.5,
                          color: AppColors.border,
                        ),
                      ),
                      HorizontalWardrobeStrip(
                        title: l10n.homePicksTitle,
                        items: items,
                        onItemTap: (item) {
                          _push(ClothingDetailScreen(item: item));
                        },
                        emptyMessage: l10n.homeNoClothingYet,
                        emptyActionLabel: l10n.homeAddClothing,
                        onEmptyAction: _openUpload,
                      ),
                    ],
                  ),
                ),

                // ─── İPUCU ───
                const SizedBox(height: AppSpacing.lg),
                StaggeredSlideFade(
                  index: 7,
                  child: _buildModernTipCard(context),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Zara tarzı bölüm etiketi: ince uppercase.
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 2.5,
          fontSize: 11,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildWardrobeCompletionCard(int itemCount, SubscriptionProvider sub) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final percent = computeWardrobeCompletionPercent(itemCount);
    return GestureDetector(
      onTap: () {
        if (!sub.isPremium) {
          _push(const PremiumScreen());
        } else {
          _push(const WardrobeAnalysisScreen());
        }
      },
      child: BouncingWidget(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg + 4,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Minimal yüzde göstergesi — Zara tarzı düz metin
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '%$percent',
                    style: AppTypography.display.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeWardrobeTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      percent >= 100
                          ? l10n.homeWardrobeComplete
                          : l10n.homeWardrobeRemaining((kExpectedWardrobeSize - itemCount).clamp(0, kExpectedWardrobeSize)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyOutfitSuggestionCard() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Text(
            l10n.homeDailyOutfitTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.homeDailyOutfitDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (widget.onSelectTab != null) {
                  widget.onSelectTab!(2);
                  return;
                }
                _push(const AIStylistScreen());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side:
                    const BorderSide(color: AppColors.textPrimary, width: 0.5),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                l10n.homeDailyOutfitButton,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasEnoughClothesForDailyOutfit(List<Clothing> items) {
    if (items.length < 3) return false;

    bool hasTop = false;
    bool hasBottom = false;
    bool hasShoes = false;
    bool hasDress = false;

    for (final item in items) {
      final category = item.category.toLowerCase().trim();
      final mainGroup = (item.advancedAnalysis?.mainGroup ?? '')
          .toLowerCase()
          .replaceAll(' ', '_');

      if (category == 'top' ||
          category == 'ust' ||
          category == 'üst' ||
          category == 'tişört' ||
          category == 'tisort' ||
          category == 'gömlek' ||
          category == 'gomlek' ||
          category == 'kazak' ||
          mainGroup.contains('ust_giyim') ||
          mainGroup.contains('ustgiyim')) {
        hasTop = true;
      }
      if (category == 'bottom' ||
          category == 'alt' ||
          category == 'pantolon' ||
          category == 'etek' ||
          mainGroup.contains('alt_giyim') ||
          mainGroup.contains('altgiyim')) {
        hasBottom = true;
      }
      if (category == 'shoes' ||
          category == 'ayakkabı' ||
          category == 'ayakkabi' ||
          mainGroup.contains('ayakkabi')) {
        hasShoes = true;
      }
      if (category == 'dress' ||
          category == 'elbise' ||
          mainGroup.contains('elbise')) {
        hasDress = true;
      }
    }

    return (hasTop && hasBottom && hasShoes) || (hasDress && hasShoes);
  }

  Widget _buildModernTipCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Text(
            l10n.homeTipTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.homeTipContent,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductionCard(BuildContext context) {
    if (_hasSeenIntro) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeWelcomeTitle,
                    style: AppTypography.display.copyWith(
                      fontSize: 22,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.0,
                      height: 1.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _setIntroSeen,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.homeWelcomeDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildIntroFeatureItem(
              title: l10n.homeIntroFreeTitle,
              description: l10n.homeIntroFreeDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildIntroFeatureItem(
              title: l10n.homeIntroAiTitle,
              description: l10n.homeIntroAiDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildIntroFeatureItem(
              title: l10n.homeIntroPremiumTitle,
              description: l10n.homeIntroPremiumDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroFeatureItem({
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zara ince dash
        Container(
          margin: const EdgeInsets.only(top: 7),
          width: 12,
          height: 0.5,
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
