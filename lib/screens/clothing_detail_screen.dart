import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/utils/clothing_formatter.dart';
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
            expandedHeight: 550,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.zero,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'clothing_${widget.item.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.item.displayImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.softBackground,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textPrimary),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.softBackground,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      color: AppColors.textSecondary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.title.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.0,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ClothingFormatter.format(widget.item.category),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Grid of key attributes
                    _buildAttributeGrid(),

                    const SizedBox(height: 48),

                    // Detailed List Sections
                    _buildDivider(),
                    _buildRowItem(
                        'RENK',
                        ClothingFormatter.format(widget.item.colors.isNotEmpty
                            ? widget.item.colors.join(',')
                            : widget.item.advancedAnalysis?.color)),
                    _buildDivider(),
                    _buildRowItem(
                        'MATERYAL',
                        ClothingFormatter.format(
                            widget.item.advancedAnalysis?.material)),
                    _buildDivider(),
                    _buildRowItem(
                        'STİL',
                        ClothingFormatter.format(
                            widget.item.advancedAnalysis?.style)),
                    _buildDivider(),
                    _buildRowItem(
                        'SEZON',
                        ClothingFormatter.format(
                            widget.item.advancedAnalysis?.season)),
                    _buildDivider(),

                    const SizedBox(height: 48),

                    // Advanced Analysis (Expandable or just text)
                    if (widget.item.advancedAnalysis?.details != null &&
                        (widget.item.advancedAnalysis!.details ?? '')
                            .isNotEmpty) ...[
                      const Text(
                        'DETAYLI ANALİZ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (widget.item.advancedAnalysis!.details ?? '').trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          height: 1.8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],

                    // API Usage (Subtle)
                    if (widget.item.apiUsage != null) ...[
                      _buildApiUsageSection(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeGrid() {
    // Collect key attributes for a quick glance grid
    final attributes = [
      {
        'label': 'ANA GRUP',
        'value':
            ClothingFormatter.format(widget.item.advancedAnalysis?.mainGroup)
      },
      {
        'label': 'KATEGORİ',
        'value': ClothingFormatter.format(widget.item.category)
      },
      // Add more if needed, but let's keep it minimal
    ];

    return Row(
      children: attributes
          .map((attr) => Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attr['label']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      attr['value']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: AppColors.border,
    );
  }

  Widget _buildRowItem(String label, String value) {
    if (value == 'Belirtilmemiş') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiUsageSection() {
    final apiUsage = widget.item.apiUsage;
    if (apiUsage == null) return const SizedBox.shrink();

    return ExpansionTile(
      title: const Text(
        'AI ANALİZ BİLGİLERİ',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
          color: AppColors.textSecondary,
        ),
      ),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              _buildApiRow('MODEL', apiUsage.model),
              _buildApiRow(
                  'MALİYET', '\$${apiUsage.totalCost.toStringAsFixed(4)}'),
              _buildApiRow('TOKENS',
                  '${apiUsage.promptTokens + apiUsage.completionTokens}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApiRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary.withValues(alpha: 0.5),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
