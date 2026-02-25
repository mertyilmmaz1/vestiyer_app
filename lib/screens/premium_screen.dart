import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

import 'package:vestiyer_nodejs/core/product/utils/scaffold_messenger_helper.dart';
import '../providers/subscription_provider.dart';
import '../widgets/vestiyer_page_header.dart';
import '../widgets/bouncing_widget.dart';

class PremiumScreen extends StatefulWidget {
  final bool showCloseButton;

  const PremiumScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  /// Selected plan: monthly, yearly, or lifetime.
  SubscriptionType _selectedPlan = SubscriptionType.monthly;
  Offerings? _offerings;
  String? _offeringsError;
  bool _purchaseInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    final offerings = await sub.getOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      _offeringsError =
          offerings?.current == null ? AppLocalizations.of(context).premiumOfferingsError : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            VestiyerPageHeader(
              title: l10n.premiumTitle,
              subtitle: l10n.premiumSubtitle,
              showBackButton: widget.showCloseButton,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: subscriptionProvider.isLoading && !_purchaseInProgress
                  ? Center(
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textPrimary),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            _buildFeatureItem(l10n.premiumFeatureAnalysis,
                                l10n.premiumFeatureAnalysisDesc),
                            const SizedBox(height: 24),
                            _buildFeatureItem(l10n.premiumFeatureAssistant,
                                l10n.premiumFeatureAssistantDesc),
                            const SizedBox(height: 24),
                            _buildFeatureItem(l10n.premiumFeatureUnlimited,
                                l10n.premiumFeatureUnlimitedDesc),
                            const SizedBox(height: 48),

                            // Plan selector: Monthly | Yearly | Lifetime
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.textPrimary,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildPlanChip(
                                    l10n.premiumMonthly,
                                    SubscriptionType.monthly,
                                  ),
                                  _buildPlanChip(
                                    l10n.premiumYearly,
                                    SubscriptionType.yearly,
                                  ),
                                  _buildPlanChip(
                                    l10n.premiumLifetime,
                                    SubscriptionType.lifetime,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Price Card content inline
                            Column(
                              children: [
                                const SizedBox(height: 12),
                                _buildPriceRow(context, subscriptionProvider),
                                if (_offeringsError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _offeringsError!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _purchaseInProgress
                                        ? null
                                        : () => _loadOfferings(),
                                    child: Text(
                                      l10n.premiumRetry,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
                                BouncingWidget(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _purchaseInProgress
                                          ? null
                                          : () => _purchase(subscriptionProvider),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.textPrimary,
                                        foregroundColor: AppColors.background,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 18),
                                        elevation: 0,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                      child: _purchaseInProgress
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        AppColors.background),
                                              ),
                                            )
                                          : Text(
                                              l10n.premiumPurchaseButton,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 2.0,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            // Restore purchases button
                            Center(
                              child: TextButton(
                                onPressed: _purchaseInProgress
                                    ? null
                                    : () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        await subscriptionProvider
                                            .restorePurchases();
                                        if (!mounted) return;
                                        if (subscriptionProvider.isPremium) {
                                          messenger.showSuccess(
                                              l10n.premiumRestoreSuccess);
                                        }
                                      },
                                child: Text(
                                  l10n.premiumRestorePurchases,
                                  style: TextStyle(
                                    color: AppColors.textPrimary
                                        .withValues(alpha: 0.6),
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Terms
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                l10n.premiumSubscriptionTerms,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.4),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanChip(String label, SubscriptionType plan) {
    final selected = _selectedPlan == plan;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = plan),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: selected ? AppColors.textPrimary : Colors.transparent,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.background : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  /// Kendi paywall ekranımızla satın alma. RevenueCat sadece fiyat + satın alma motoru.
  Future<void> _purchase(SubscriptionProvider subscriptionProvider) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _purchaseInProgress = true);
    final success = await subscriptionProvider.purchaseSubscription(_selectedPlan);
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);
    final l10n = AppLocalizations.of(context);
    if (success) {
      messenger.showSuccess(l10n.premiumPurchaseSuccess);
      navigator.pop();
    } else {
      final msg = subscriptionProvider.lastPurchaseErrorMessage.isNotEmpty
          ? subscriptionProvider.lastPurchaseErrorMessage
          : l10n.premiumPurchaseError;
      messenger.showError(msg);
    }
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textPrimary, width: 1),
          ),
          child: const Icon(
            Icons.check,
            size: 12,
            color: AppColors.textPrimary,
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
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, SubscriptionProvider provider) {
    if (_offerings?.current == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    Package? package;
    switch (_selectedPlan) {
      case SubscriptionType.monthly:
        package = _offerings!.current!.monthly;
        break;
      case SubscriptionType.yearly:
        package = _offerings!.current!.annual;
        break;
      case SubscriptionType.lifetime:
        package = _offerings!.current!.lifetime;
        break;
      case SubscriptionType.none:
        return const SizedBox.shrink();
    }

    if (package == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          package.storeProduct.priceString,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        if (_selectedPlan == SubscriptionType.yearly) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: AppColors.textPrimary,
            child: Text(
              l10n.premiumYearlySavings,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.background,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
