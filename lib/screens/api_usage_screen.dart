import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import '../models/api_usage.dart';
import '../widgets/vestiyer_page_header.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class ApiUsageScreen extends StatefulWidget {
  const ApiUsageScreen({super.key});

  @override
  State<ApiUsageScreen> createState() => _ApiUsageScreenState();
}

class _ApiUsageScreenState extends State<ApiUsageScreen>
    with SingleTickerProviderStateMixin {
  final List<ApiUsage> _usageHistory = [];
  final double _totalCost = 0;
  double _exchangeRate = 0;
  final bool _isLoading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
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

  Future<void> _getExchangeRate() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _exchangeRate = data['rates']['TRY'];
        });
      }
    } catch (e) {
      debugPrint('Döviz kuru alınırken hata: $e');
    }
  }

  Future<void> _loadUsageData() async {
    await _getExchangeRate();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                  title: 'API Kullanımı',
                  showBackButton: true,
                  onBack: () => Navigator.maybePop(context),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.delete_sweep_outlined, size: 26, color: AppColors.textPrimary.withValues(alpha: 0.7)),
                      onPressed: () => _showResetConfirmation(context),
                      tooltip: 'API Kullanımını Sıfırla',
                    ),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(AppColors.textPrimary.withValues(alpha: 0.7)),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Veriler yükleniyor...',
                                style: TextStyle(
                                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.tertiary,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Toplam Maliyet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '\$${_totalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (_exchangeRate > 0) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '₺${(_totalCost * _exchangeRate).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _usageHistory.length,
                                itemBuilder: (context, index) {
                                  final usage = _usageHistory[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiary,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: ExpansionTile(
                                      collapsedIconColor: AppColors.textPrimary.withValues(alpha: 0.7),
                                      iconColor: AppColors.textPrimary,
                                      collapsedBackgroundColor: Colors.transparent,
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      title: Text(
                                        'Model: ${usage.model}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(usage.timestamp),
                                        style: TextStyle(
                                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildUsageDetail(
                                          'Prompt Tokens',
                                          usage.promptTokens.toString(),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildUsageDetail(
                                          'Completion Tokens',
                                          usage.completionTokens.toString(),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildUsageDetail(
                                          'Maliyet',
                                          '\$${usage.cost.toStringAsFixed(4)}',
                                        ),
                                        if (_exchangeRate > 0) ...[
                                          const SizedBox(height: 12),
                                          _buildUsageDetail(
                                            'Maliyet (TL)',
                                            '₺${(usage.cost * _exchangeRate).toStringAsFixed(4)}',
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildUsageDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'API Kullanımını Sıfırla',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'API kullanım geçmişini sıfırlamak istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sıfırla',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {}
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw dark background
    final backgroundGradient = LinearGradient(
      colors: [
        AppColors.background,
        AppColors.tertiary,
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
