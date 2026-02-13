import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/paywall_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wardrobe_analysis_screen.dart';
import 'assistant_chat_screen.dart';
import '../widgets/home_page_header.dart';
import '../widgets/assistant_card.dart';
import '../widgets/circle_feature_grid.dart';
import '../widgets/horizontal_wardrobe_strip.dart';
import 'clothing_detail_screen.dart';
import 'outfit_suggestions_screen.dart';
import 'premium_screen.dart';

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
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage:
            'Premium üye olarak dolabınızı sınırsız kıyafetle zenginleştirin ve AI destekli kombin önerilerini kullanın.',
      );
    }
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
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
  }

  void _openUpload() {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    if (!subscriptionProvider.canAddClothing()) {
      PaywallWidget.showPaywall(
        context,
        type: PaywallType.featureGated,
        customMessage:
            'Ücretsiz kıyafet ekleme hakkınız doldu. Premium üyelik ile sınırsız kıyafet ekleyebilirsiniz.',
      );
      return;
    }
    _push(const UploadScreen());
  }

  void _openAssistantChat() {
    final text = _assistantController.text.trim();
    _push(AssistantChatScreen(
      initialMessage: text.isEmpty ? null : text,
    ));
  }

  void _openProfile() {
    if (widget.onSelectTab != null) {
      widget.onSelectTab!(4);
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ProfileScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final user = subscriptionProvider.currentUser;
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final items = wardrobeProvider.items;
    final count = items.length;
    final subtitle = count == 0
        ? 'Kıyafet dolabınızı yapay zeka ile yönetin'
        : '$count kıyafet dolabında';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomePageHeader(
              firstName: user?.firstName,
              subtitle: subtitle,
              onNotificationTap: () {},
              onProfileTap: _openProfile,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    AssistantCard(
                      showProBadge: subscriptionProvider.isPremium,
                      controller: _assistantController,
                      onSend: _openAssistantChat,
                    ),
                    const SizedBox(height: 24),
                    CircleFeatureGrid(
                      items: [
                        CircleFeatureItem(
                          icon: Icons.analytics_outlined,
                          label: 'Gardırop Analizi',
                          onTap: () => _push(const WardrobeAnalysisScreen()),
                        ),
                        CircleFeatureItem(
                          icon: Icons.style_outlined,
                          label: 'Kombinler',
                          onTap: () => _push(const OutfitSuggestionsScreen()),
                        ),
                        CircleFeatureItem(
                          icon: Icons.diamond_outlined,
                          label: 'Premium',
                          onTap: () => _push(const PremiumScreen()),
                        ),
                      ],
                    ),
                    _buildIntroductionCard(context),
                    HorizontalWardrobeStrip(
                      title: 'Dolabındakiler',
                      items: items,
                      onItemTap: (item) {
                        _push(ClothingDetailScreen(item: item));
                      },
                      emptyMessage: 'Henüz kıyafet yok',
                      emptyActionLabel: 'Kıyafet ekle',
                      onEmptyAction: _openUpload,
                    ),
                    const SizedBox(height: 24),
                    _buildModernTipCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTipCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İpucu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tüm kıyafetlerinizi sisteme ekleyerek daha doğru kombin önerileri alabilirsiniz.',
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

  Widget _buildIntroductionCard(BuildContext context) {
    if (_hasSeenIntro) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tips_and_updates_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Vestiyer\'e Hoş Geldiniz!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  onPressed: _setIntroSeen,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Vestiyer, yapay zeka destekli kişisel gardrop asistanınızdır. Başlamadan önce bilmeniz gerekenler:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildIntroFeatureItem(
              icon: Icons.checkroom_outlined,
              title: 'Ücretsiz 10 Kıyafet',
              description:
                  'Ücretsiz sürümde dolabınıza 10 kıyafet ekleyebilirsiniz.',
            ),
            const SizedBox(height: 12),
            _buildIntroFeatureItem(
              icon: Icons.auto_awesome_outlined,
              title: 'AI Kombin Önerileri',
              description:
                  'Premium üyelikle yapay zeka destekli kombin önerileri alın.',
            ),
            const SizedBox(height: 12),
            _buildIntroFeatureItem(
              icon: Icons.diamond_outlined,
              title: 'Premium Özellikler',
              description:
                  'Premium üyelikle sınırsız kıyafet ve tüm özelliklere erişin.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
