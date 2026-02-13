import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'dart:math' as math;
import '../providers/subscription_provider.dart';
import '../widgets/vestiyer_page_header.dart';

class PremiumScreen extends StatefulWidget {
  final bool showCloseButton;

  const PremiumScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showMonthly = true;
  Offerings? _offerings;
  String? _offeringsError;
  bool _purchaseInProgress = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VestiyerPageHeader(
                  title: 'Premium Abonelik',
                  subtitle: 'Dolabınızı sınırsız kıyafetle zenginleştirin',
                  showBackButton: widget.showCloseButton,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: subscriptionProvider.isLoading && !_purchaseInProgress
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textPrimary.withValues(alpha: 0.7)),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                // Features
                                _buildFeatureItem('Sınırsız Kıyafet Ekleyin',
                                    'Premium üyelikle dolabınıza istediğiniz kadar kıyafet ekleyin'),
                                const SizedBox(height: 16),
                                _buildFeatureItem('Gelişmiş Kombin Önerileri',
                                    'Özel AI algoritmalarıyla daha iyi kombinler alın'),
                                const SizedBox(height: 16),
                                _buildFeatureItem('Öncelikli Erişim',
                                    'Yeni özelliklere ilk siz erişin'),
                                const SizedBox(height: 40),
                                // Subscription Toggle
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary
                                        .withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _showMonthly = true;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _showMonthly
                                                  ? AppColors.textPrimary
                                                      .withValues(alpha: 0.1)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Aylık',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _showMonthly
                                                    ? AppColors.textPrimary
                                                    : AppColors.textPrimary
                                                        .withValues(alpha: 0.6),
                                                fontWeight: _showMonthly
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _showMonthly = false;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              color: !_showMonthly
                                                  ? AppColors.textPrimary
                                                      .withValues(alpha: 0.1)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Text(
                                                  'Yıllık',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: !_showMonthly
                                                        ? AppColors.textPrimary
                                                        : AppColors.textPrimary
                                                            .withValues(
                                                                alpha: 0.6),
                                                    fontWeight: !_showMonthly
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 4,
                                                  top: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Text(
                                                      '25% İndirim',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
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
                                // Price Card
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiary,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _showMonthly
                                            ? 'Aylık Abonelik'
                                            : 'Yıllık Abonelik',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
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
                                          child: Text(
                                            'Yeniden dene',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _purchaseInProgress
                                              ? null
                                              : () => _purchase(
                                                  subscriptionProvider),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor:
                                                AppColors.textPrimary,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: _purchaseInProgress
                                              ? SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            AppColors
                                                                .textPrimary),
                                                  ),
                                                )
                                              : const Text(
                                                  'Şimdi Abone Ol',
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
                                const SizedBox(height: 20),
                                // Restore purchases button
                                TextButton(
                                  onPressed: _purchaseInProgress
                                      ? null
                                      : () async {
                                          await subscriptionProvider
                                              .restorePurchases();
                                          if (!mounted) return;
                                          if (subscriptionProvider.isPremium) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
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
                                          .withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Terms
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                    'Aboneliğiniz, iptal edilmediği sürece seçilen dönem sonunda otomatik olarak yenilenir. Ödeme, dönem bitiminden 24 saat önce hesabınızdan tahsil edilir. Aboneliğinizi Apple ID ayarlarınızdan yönetebilirsiniz.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.5),
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
        ],
      ),
    );
  }

  Widget _buildPriceRow(SubscriptionProvider subscriptionProvider) {
    final current = _offerings?.current;
    String monthlyPrice = '59.99';
    String annualPrice = '449.99';
    String? annualSuffix;
    if (current != null) {
      final monthly = current.monthly ??
          current.availablePackages
              .where((p) => p.packageType == PackageType.monthly)
              .firstOrNull;
      final annual = current.annual ??
          current.availablePackages
              .where((p) => p.packageType == PackageType.annual)
              .firstOrNull;
      if (monthly != null) monthlyPrice = monthly.storeProduct.priceString;
      if (annual != null) {
        annualPrice = annual.storeProduct.priceString;
        annualSuffix = '(Yıllık abonelik)';
      }
    }
    final price = _showMonthly ? monthlyPrice : annualPrice;
    final suffix = _showMonthly ? '/ay' : '/yıl';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              price,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                suffix,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        if (!_showMonthly && annualSuffix != null) ...[
          const SizedBox(height: 8),
          Text(
            annualSuffix,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _purchase(SubscriptionProvider subscriptionProvider) async {
    setState(() => _purchaseInProgress = true);
    final success = await subscriptionProvider.purchaseSubscription(
      _showMonthly ? SubscriptionType.monthly : SubscriptionType.yearly,
    );
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Premium abonelik başarıyla aktif edildi')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
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

  Widget _buildFeatureItem(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.textPrimary,
              size: 22,
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    shapePaint.color = AppColors.textPrimary.withValues(alpha: 0.03);
    final path1 = Path();
    final centerX1 = size.width * 0.2 + math.sin(animationValue * math.pi) * 40;
    final centerY1 =
        size.height * 0.2 + math.cos(animationValue * math.pi) * 40;
    final radius1 = size.width * 0.5;
    path1.addOval(
        Rect.fromCircle(center: Offset(centerX1, centerY1), radius: radius1));
    canvas.drawPath(path1, shapePaint);

    // Second blob
    shapePaint.color = AppColors.textPrimary.withValues(alpha: 0.02);
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
    shapePaint.color = AppColors.textPrimary.withValues(alpha: 0.01);
    final path3 = Path();
    final centerX3 =
        size.width * 0.5 + math.sin(animationValue * 2 * math.pi + 2) * 20;
    final centerY3 =
        size.height * 0.8 + math.cos(animationValue * 2 * math.pi + 2) * 20;
    final radius3 = size.width * 0.6;
    path3.addOval(
        Rect.fromCircle(center: Offset(centerX3, centerY3), radius: radius3));
    canvas.drawPath(path3, shapePaint);

    // Draw subtle grid pattern
    final gridPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
