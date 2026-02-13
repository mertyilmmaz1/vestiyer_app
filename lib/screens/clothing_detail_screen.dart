import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import '../models/clothing.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClothingDetailScreen extends StatefulWidget {
  final Clothing item;

  const ClothingDetailScreen({super.key, required this.item});

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
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
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                        color: AppColors.textPrimary, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
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
                          color: AppColors.tertiary,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.tertiary,
                          child: const Icon(
                            Icons.error_outline,
                            color: AppColors.textSecondary,
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
                    color: AppColors.tertiary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      right: BorderSide(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        width: 1,
                      ),
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
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.item.category,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary.withValues(alpha: 0.7),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
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
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Detaylı Analiz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
                              color: AppColors.textPrimary.withValues(alpha: 0.6),
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
                              color: AppColors.textPrimary.withValues(alpha: 0.9),
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
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.api_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'AI Analiz Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
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
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
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
              color: AppColors.textPrimary,
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

