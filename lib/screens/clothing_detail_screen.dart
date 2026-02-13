import 'package:flutter/material.dart';
import '../models/clothing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

class ClothingDetailScreen extends StatefulWidget {
  final Clothing item;

  const ClothingDetailScreen({super.key, required this.item});

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
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
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 450,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'clothing_${widget.item.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white60,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.item.category,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Temel bilgiler
                        _buildInfoSection(
                          title: 'Kategori',
                          content: widget.item.category,
                          icon: Icons.category_outlined,
                        ),
                        const SizedBox(height: 16),

                        // Renk bilgisi - önce colors array'inden, sonra advancedAnalysis'ten
                        if (widget.item.colors.isNotEmpty)
                          _buildInfoSection(
                            title: 'Renkler',
                            content: widget.item.colors.join(', '),
                            icon: Icons.palette_outlined,
                          )
                        else if (widget.item.advancedAnalysis?.color != null)
                          _buildInfoSection(
                            title: 'Renk',
                            content: widget.item.advancedAnalysis!.color ?? 'Belirtilmemiş',
                            icon: Icons.palette_outlined,
                          ),
                        if (widget.item.colors.isNotEmpty ||
                            widget.item.advancedAnalysis?.color != null)
                          const SizedBox(height: 16),

                        // Ana Grup bilgisi
                        if (widget.item.advancedAnalysis?.mainGroup !=
                            null) ...[
                          _buildInfoSection(
                            title: 'Ana Grup',
                            content: widget.item.advancedAnalysis!.mainGroup ?? 'Belirtilmemiş',
                            icon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Materyal bilgisi
                        if (widget.item.advancedAnalysis?.material != null) ...[
                          _buildInfoSection(
                            title: 'Materyal',
                            content: widget.item.advancedAnalysis!.material ?? 'Belirtilmemiş',
                            icon: Icons.texture_outlined,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Stil bilgisi
                        if (widget.item.advancedAnalysis?.style != null) ...[
                          _buildInfoSection(
                            title: 'Stil',
                            content: widget.item.advancedAnalysis!.style ?? 'Belirtilmemiş',
                            icon: Icons.style_outlined,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Sezon bilgisi
                        if (widget.item.advancedAnalysis?.season != null) ...[
                          _buildInfoSection(
                            title: 'Sezon',
                            content: widget.item.advancedAnalysis!.season ?? 'Belirtilmemiş',
                            icon: Icons.wb_sunny_outlined,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Detaylar bölümü
                        if (widget.item.advancedAnalysis?.details != null &&
                            (widget.item.advancedAnalysis!.details ?? '').isNotEmpty) ...[
                          _buildDetailsSection(),
                          const SizedBox(height: 16),
                        ],

                        // API Kullanım Bilgileri
                        if (widget.item.apiUsage != null) ...[
                          _buildApiUsageSection(),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final details = widget.item.advancedAnalysis?.details ?? '';
    final lines =
        details.split('\n').where((line) => line.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Detaylı Analiz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lines
              .map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (line.startsWith('-'))
                          Container(
                            margin: const EdgeInsets.only(top: 8, right: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            line.startsWith('-')
                                ? line.substring(1).trim()
                                : line,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildApiUsageSection() {
    final apiUsage = widget.item.apiUsage;
    if (apiUsage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.api_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'AI Analiz Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildApiUsageItem(
                  'Model',
                  apiUsage.model,
                  Icons.smart_toy_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildApiUsageItem(
                  'Maliyet',
                  '\$${apiUsage.totalCost.toStringAsFixed(4)}',
                  Icons.attach_money_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildApiUsageItem(
                  'Prompt Tokens',
                  apiUsage.promptTokens.toString(),
                  Icons.input_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildApiUsageItem(
                  'Completion Tokens',
                  apiUsage.completionTokens.toString(),
                  Icons.output_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildApiUsageItem(
                  'Analiz Tarihi',
                  _formatDate(apiUsage.analyzedAt),
                  Icons.schedule_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildApiUsageItem(
                  'Toplam Tokens',
                  (apiUsage.promptTokens + apiUsage.completionTokens)
                      .toString(),
                  Icons.numbers_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiUsageItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
