import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'upload_screen.dart';
import 'wardrobe_screen.dart';
import 'profile_screen.dart';
import 'premium_screen.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/paywall_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wardrobe_analysis_screen.dart';
import 'ai_stylist_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasSeenIntro = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Load intro flag from shared preferences
    _loadIntroFlag();

    // Check if we should show the paywall
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShowPaywall();
    });
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
    setState(() {
      _hasSeenIntro = true;
    });
  }

  Future<void> _checkShowPaywall() async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    // Don't show paywall if user is premium
    if (subscriptionProvider.isPremium) return;

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

  Future<void> _logout() async {
    try {
      await context.read<FirebaseAuthService>().signOut();
      if (!mounted) return;

      // Clear providers
      final wardrobeProvider = context.read<WardrobeProvider>();
      final subscriptionProvider = context.read<SubscriptionProvider>();

      wardrobeProvider.setCurrentUserId(null);
      subscriptionProvider.setCurrentUser(null);

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılırken hata oluştu: $e')),
      );
    }
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
    final user = subscriptionProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Text(
              'vestiyer',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            if (user != null) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subscriptionProvider.isPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.diamond_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Test Premium Mode toggle (only in debug mode)
          // if (kDebugMode)
          //   IconButton(
          //     icon: Icon(
          //       Icons.workspace_premium,
          //       color: _testPremiumMode ? Colors.amber : Colors.white38,
          //       size: 26,
          //     ),
          //     onPressed: _toggleTestPremium,
          //     tooltip: 'Toggle Test Premium',
          //   ),
          IconButton(
            icon: const Icon(Icons.person_outline,
                color: Colors.white70, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ProfileScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            tooltip: 'Profili Düzenle',
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user != null ? Colors.white : Colors.grey.shade600,
                boxShadow: [
                  BoxShadow(
                    color: user != null
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.transparent,
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: Colors.white70, size: 26),
            onPressed: _logout,
            tooltip: 'Çıkış Yap',
          ),
          const SizedBox(width: 6),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Hoş Geldiniz',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kıyafet dolabınızı yapay zeka ile yönetin',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildIntroductionCard(context),
                    _buildModernFeatureCard(
                      context,
                      icon: Icons.add_photo_alternate_outlined,
                      iconColor: Colors.white,
                      iconBgColor: Colors.grey.shade800,
                      title: 'Kıyafet Yükle',
                      subtitle: subscriptionProvider.isPremium
                          ? 'Yeni kıyafetlerini dolabına ekle'
                          : 'Yeni kıyafetlerini dolabına ekle (${subscriptionProvider.remainingFreeItems} ücretsiz hakkın kaldı)',
                      cardColor: const Color(0xFF2A2A2A),
                      onTap: () {
                        if (!subscriptionProvider.canAddClothing()) {
                          PaywallWidget.showPaywall(
                            context,
                            type: PaywallType.featureGated,
                            customMessage:
                                'Ücretsiz kıyafet ekleme hakkınız doldu. Premium üyelik ile sınırsız kıyafet ekleyebilirsiniz.',
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const UploadScreen(),
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
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      icon: Icons.checkroom_outlined,
                      iconColor: Colors.white,
                      iconBgColor: Colors.grey.shade800,
                      title: 'Dolabımı Gör',
                      subtitle: 'Kıyafet koleksiyonunu keşfet',
                      cardColor: const Color(0xFF2A2A2A),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const WardrobeScreen(),
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
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      icon: Icons.auto_awesome_outlined,
                      iconColor: Colors.white,
                      iconBgColor: Colors.purple.shade900,
                      title: 'AI Stilist',
                      subtitle:
                          'Yapay zeka ile kıyafetlerinizi eşleştirin ve mükemmel kombinler yaratın.',
                      cardColor: const Color(0xFF3A1F5D),
                      actionButtonText: 'Kombin Oluştur',
                      actionButtonColor: Colors.purple.shade600,
                      onTap: () {
                        if (!subscriptionProvider.isPremium) {
                          PaywallWidget.showPaywall(
                            context,
                            type: PaywallType.featureGated,
                            customMessage:
                                'AI Stilist özelliği premium üyeler için kullanılabilir. Premium üyelik ile sınırsız kombin önerileri alabilirsiniz.',
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const AIStylistScreen(),
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
                      },
                    ),
                    _buildModernFeatureCard(
                      context,
                      icon: Icons.analytics_outlined,
                      iconColor: Colors.white,
                      iconBgColor: Colors.teal.shade900,
                      title: 'Gardırop Analizi',
                      subtitle:
                          'Stil profilinizi ve alışveriş önerilerinizi görün',
                      cardColor: const Color(0xFF0B5D62),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const WardrobeAnalysisScreen(),
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
                      },
                    ),
                    if (!subscriptionProvider.isPremium) ...[
                      _buildModernFeatureCard(
                        context,
                        icon: Icons.diamond_outlined,
                        iconColor: Colors.white,
                        iconBgColor: Colors.amber.shade800,
                        title: 'Premium',
                        subtitle:
                            'Sınırsız kıyafet ve özel özellikler için premium üyelik alın',
                        cardColor: const Color(0xFF8B6000),
                        actionButtonText: 'Premium\'a Yükselt',
                        actionButtonColor: Colors.amber.shade600,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const PremiumScreen(),
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
                        },
                      ),
                    ],
                    const SizedBox(height: 30),
                    _buildModernTipCard(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardColor,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    Color iconBgColor = Colors.black,
    String? actionButtonText,
    Color? actionButtonColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: iconColor,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ],
                ),
                if (actionButtonText != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionButtonColor ?? Colors.white,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          actionButtonText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTipCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade800.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: Colors.amber.shade300,
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tüm kıyafetlerinizi sisteme ekleyerek daha doğru kombin önerileri alabilirsiniz.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
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
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade700.withValues(alpha: 0.15),
            Colors.amber.shade900.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.shade700.withValues(alpha: 0.3),
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
                  color: Colors.amber.shade700.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: Colors.amber,
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
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
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
              color: Colors.white.withValues(alpha: 0.7),
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
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
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
