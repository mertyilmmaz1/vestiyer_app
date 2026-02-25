import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing.dart';
import '../models/combination.dart';
import '../models/outfit_log.dart';
import '../providers/wardrobe_provider.dart';
import '../services/firestore_service_base.dart';
import '../widgets/vestiyer_page_header.dart';
import 'clothing_detail_screen.dart';

class OutfitHistoryScreen extends StatefulWidget {
  const OutfitHistoryScreen({super.key});

  @override
  State<OutfitHistoryScreen> createState() => _OutfitHistoryScreenState();
}

class _OutfitHistoryScreenState extends State<OutfitHistoryScreen> {
  List<OutfitLog> _logs = [];
  List<Combination> _combinations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firestore = context.read<FirestoreServiceBase>();
    final wardrobeProvider = context.read<WardrobeProvider>();
    final userId = wardrobeProvider.currentUserId;
    if (userId == null) {
      setState(() {
        _error = AppLocalizations.of(context)!.outfitHistoryNotSignedIn;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final logs = await firestore.getOutfitLogs(userId, limit: 100);
      final combinations = await firestore.getCombinations(userId, limit: 200);
      setState(() {
        _logs = logs;
        _combinations = combinations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.outfitHistoryLoadError(e.toString());
        _isLoading = false;
      });
    }
  }

  Combination? _combinationForLog(OutfitLog log) {
    try {
      return _combinations.firstWhere((c) => c.id == log.combinationId);
    } catch (_) {
      return null;
    }
  }

  List<Clothing> _clothingForCombination(Combination combo) {
    final wardrobeItems = context.read<WardrobeProvider>().items;
    final list = <Clothing>[];
    for (final item in combo.clothingItems) {
      try {
        final c = wardrobeItems.firstWhere((w) => w.id == item.clothingId);
        list.add(c);
      } catch (_) {
        list.add(Clothing(
          colors: [],
          id: item.clothingId,
          userId: '',
          title: AppLocalizations.of(context)!.outfitSuggestionsNotFound,
          category: item.category ?? 'unknown',
          imageUrl: '',
          imagePath: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VestiyerPageHeader(
              title: AppLocalizations.of(context)!.outfitHistoryTitle,
              showBackButton: true,
              onBack: () => Navigator.maybePop(context),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                  onPressed: _isLoading ? null : _load,
                  tooltip: AppLocalizations.of(context)!.outfitHistoryRefreshTooltip,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _load,
                                  child: Text(AppLocalizations.of(context)!.outfitHistoryRetry),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _logs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: AppColors.textPrimary.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!.outfitHistoryEmpty,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color:
                                          AppColors.textPrimary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.outfitHistoryEmptyDescription,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          AppColors.textPrimary.withValues(alpha: 0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : _buildLogList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final combo = _combinationForLog(log);
        final l10n = AppLocalizations.of(context)!;
        final name = log.combinationName ?? combo?.name ?? l10n.outfitHistoryDefaultName;
        final clothing =
            combo != null ? _clothingForCombination(combo) : <Clothing>[];
        final locale = Localizations.localeOf(context).toString();
        final dateStr = DateFormat('d MMMM', locale).format(log.wornAt);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.softBackground,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.zero,
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        if (log.occasion != null &&
                            log.occasion!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Text(
                              log.occasion!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (clothing.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: clothing.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final c = clothing[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  EditorialPageRoute(
                                    page: ClothingDetailScreen(item: c),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.zero,
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: c.displayImageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: c.displayImageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: AppColors.textPrimary
                                                .withValues(alpha: 0.05),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              _placeholderTile(),
                                        )
                                      : _placeholderTile(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderTile() {
    return Container(
      color: AppColors.textPrimary.withValues(alpha: 0.08),
      child: Icon(
        Icons.checkroom,
        color: AppColors.textPrimary.withValues(alpha: 0.3),
        size: 28,
      ),
    );
  }
}
