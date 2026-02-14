import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

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
  bool _showMonthly = true;
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
          offerings?.current == null ? 'Ürünler yüklenemedi' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            VestiyerPageHeader(
              title: 'PREMIUM',
              subtitle: 'DOLABINI OPTİMİZE ET',
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
                            _buildFeatureItem('DOLABINI ANALİZ ET',
                                'Eksik parça tespiti ve akıllı alışveriş önerileri'),
                            const SizedBox(height: 24),
                            _buildFeatureItem('STİL ASİSTANI',
                                'Kişisel stil raporu ve hava durumuna göre öneriler'),
                            const SizedBox(height: 24),
                            _buildFeatureItem('SINIRSIZ KOMBİN',
                                'Dolabını sınırsız büyüt, sınırsız kombin üret'),
                            const SizedBox(height: 48),

                            // Toggle
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
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _showMonthly = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        color: _showMonthly
                                            ? AppColors.textPrimary
                                            : Colors.transparent,
                                        child: Text(
                                          'AYLIK',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _showMonthly
                                                ? AppColors.background
                                                : AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _showMonthly = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        color: !_showMonthly
                                            ? AppColors.textPrimary
                                            : Colors.transparent,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Text(
                                              'YILLIK',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: !_showMonthly
                                                    ? AppColors.background
                                                    : AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.5,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Price Card content inline
                            Column(
                              children: [
                                const SizedBox(height: 12),
                                _buildPriceRow(subscriptionProvider),
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
                                    child: const Text(
                                      'Yeniden dene',
                                      style: TextStyle(
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
                                          : () =>
                                              _purchase(subscriptionProvider),
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
                                          : const Text(
                                              'PREMIUM\'A GEÇ',
                                              style: TextStyle(
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
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Satın alımlar geri yüklendi'),
                                            ),
                                          );
                                        }
                                      },
                                child: Text(
                                  'Satın alımları geri yükle',
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
                                'Aboneliğiniz, iptal edilmediği sürece seçilen dönem sonunda otomatik olarak yenilenir. Ödeme, dönem bitiminden 24 saat önce hesabınızdan tahsil edilir.',
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

  Future<void> _purchase(SubscriptionProvider subscriptionProvider) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _purchaseInProgress = true);
    final success = await subscriptionProvider.purchaseSubscription(
      _showMonthly ? SubscriptionType.monthly : SubscriptionType.yearly,
    );
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);
    if (success) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Premium abonelik başarıyla aktif edildi')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Satın alma tamamlanamadı veya iptal edildi'),
          action: SnackBarAction(
            label: 'Tamam',
            onPressed: () {},
          ),
        ),
      );
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

  Widget _buildPriceRow(SubscriptionProvider provider) {
    if (_offerings?.current == null) return const SizedBox.shrink();

    final package = _showMonthly
        ? _offerings!.current!.monthly
        : _offerings!.current!.annual;

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
        if (!_showMonthly) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: AppColors.textPrimary,
            child: const Text(
              '%25 TASARRUF',
              style: TextStyle(
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
