import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/subscription_provider.dart';

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Premium Abonelik',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        leading: widget.showCloseButton
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 26),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
            child: subscriptionProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Diamond Icon
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.diamond_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          const Text(
                            'Premium Özellikler',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            'Dolabınızı sınırsız kıyafetle zenginleştirin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 40),
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
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
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
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Aylık',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _showMonthly
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.6),
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
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            'Yıllık',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: !_showMonthly
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withValues(alpha: 0.6),
                                              fontWeight: !_showMonthly
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade700,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                '25% İndirim',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
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
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade800,
                                  Colors.grey.shade900,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
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
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '₺',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _showMonthly ? '59.99' : '449.99',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _showMonthly ? '/ay' : '/yıl',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_showMonthly) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    '(Aylık sadece ₺37.50)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      subscriptionProvider.purchaseSubscription(
                                        _showMonthly
                                            ? SubscriptionType.monthly
                                            : SubscriptionType.yearly,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
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
                            onPressed: () {
                              subscriptionProvider.restorePurchases();
                            },
                            child: Text(
                              'Satın alımları geri yükle',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Terms
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Aboneliğiniz, iptal edilmediği sürece seçilen dönem sonunda otomatik olarak yenilenir. Ödeme, dönem bitiminden 24 saat önce hesabınızdan tahsil edilir. Aboneliğinizi Apple ID ayarlarınızdan yönetebilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
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
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
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

    // Draw subtle grid pattern
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
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
