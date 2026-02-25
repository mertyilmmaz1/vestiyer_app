import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/clothing.dart';
import '../models/combination.dart';

/// Maps sample_clothes.json category (Turkish) to app category (top/bottom/outerwear/shoes/accessory).
String mapSampleCategoryToApp(String category) {
  final c = category.toLowerCase();
  if (c.contains('gömlek') || c.contains('tişört') || c.contains('t-shirt') ||
      c.contains('bluz') || c.contains('polo') || c.contains('tunik')) {
    return 'top';
  }
  if (c.contains('pantolon') || c.contains('etek') || c.contains('şort') ||
      c.contains('tayt') || c.contains('şalvar') || c.contains('kargo')) {
    return 'bottom';
  }
  if (c.contains('ceket') || c.contains('mont') || c.contains('kaban') ||
      c.contains('hırka') || c.contains('yelek') || c.contains('blazer') ||
      c.contains('kazak') || c.contains('sweatshirt')) {
    return 'outerwear';
  }
  if (c.contains('ayakkabı') || c.contains('bot') || c.contains('sandalet') ||
      c.contains('spor ayakkabı') || c.contains('topuklu')) {
    return 'shoes';
  }
  if (c.contains('aksesuar') || c.contains('çanta') || c.contains('şapka')) {
    return 'accessory';
  }
  return 'top';
}

/// Builds Clothing from sample_clothes.json item. [id] and [userId] must be provided.
/// [l10n] optional: when provided, default category/color/season use localized strings for display.
Clothing clothingFromSampleJson(
  Map<String, dynamic> json, {
  required String id,
  required String userId,
  AppLocalizations? l10n,
}) {
  final defaultCategory = l10n?.mockDefaultCategory ?? 'Clothing';
  final defaultColor = l10n?.mockDefaultColor ?? 'Unknown';
  final defaultSeason = l10n?.mockDefaultSeason ?? 'All Seasons';
  final category = json['category'] as String? ?? defaultCategory;
  final appCategory = mapSampleCategoryToApp(category);
  final color = json['color'] as String? ?? defaultColor;
  final colors = color.contains(',') ? color.split(',').map((e) => e.trim()).toList() : [color];
  final now = DateTime.now();
  // mainGroup: normalized English key for l10n display via ClothingFormatter
  final mainGroupKey = appCategory;
  return Clothing(
    id: id,
    userId: userId,
    title: category,
    category: appCategory,
    imageUrl: json['image_url'] as String? ?? '',
    imagePath: json['image_url'] as String? ?? '',
    colors: colors,
    advancedAnalysis: AdvancedAnalysis(
      mainGroup: mainGroupKey,
      category: category,
      color: color,
      material: json['material'] as String?,
      style: json['style'] as String?,
      season: json['season'] as String? ?? defaultSeason,
      details: json['description'] as String?,
      rawAnalysis: null,
    ),
    formattedAnalysis: FormattedAnalysis(
      anaGrup: appCategory,
      kategori: category,
      renk: color,
      materyal: json['material'] as String?,
      stil: json['style'] as String?,
      sezon: json['season'] as String? ?? defaultSeason,
      detaylar: json['description'] as String?,
    ),
    apiUsage: null,
    createdAt: now,
    updatedAt: now,
  );
}

/// Loads sample clothing list from assets/data/sample_clothes.json.
/// [userId] is used for each item; [limit] caps the number of items (default 10).
/// [l10n] optional: when provided, default labels use current locale.
Future<List<Clothing>> loadSampleClothingFromAssets({
  required String userId,
  int limit = 10,
  AppLocalizations? l10n,
}) async {
  final str = await rootBundle.loadString('assets/data/sample_clothes.json');
  final data = json.decode(str) as Map<String, dynamic>;
  final list = (data['clothes'] as List<dynamic>?) ?? [];
  return list.take(limit).toList().asMap().entries.map((e) {
    return clothingFromSampleJson(
      Map<String, dynamic>.from(e.value as Map),
      id: 'sample_${e.key}',
      userId: userId,
      l10n: l10n,
    );
  }).toList();
}

/// Builds 2–3 mock combinations for testing (using given [userId] and [clothingIds]).
/// [l10n] optional: when provided, name and description use localized strings.
List<Combination> mockCombinations({
  required String userId,
  required List<String> clothingIds,
  AppLocalizations? l10n,
}) {
  final now = DateTime.now();
  if (clothingIds.length < 3) return [];
  final name1 = l10n?.mockCasualCombo ?? 'Casual Outfit';
  final desc1 = l10n?.mockCasualComboDesc ?? 'Matching pieces for comfortable everyday use.';
  final name2 = l10n?.mockBusinessCombo ?? 'Business Outfit';
  final desc2 = l10n?.mockBusinessComboDesc ?? 'Professional look for office and work settings.';
  final name3 = l10n?.mockSpecialCombo ?? 'Special Outfit';
  final desc3 = l10n?.mockSpecialComboDesc ?? 'Stylishly assembled pieces for special occasions.';
  return [
    Combination(
      id: 'mock_combo_1',
      userId: userId,
      name: name1,
      description: desc1,
      occasion: 'casual',
      season: 'all-season',
      clothingItems: [
        CombinationItem(clothingId: clothingIds[0], category: 'top', isRequired: true),
        CombinationItem(clothingId: clothingIds[1], category: 'bottom', isRequired: true),
      ],
      isAIGenerated: true,
      isFavorite: false,
      rating: null,
      timesWorn: 0,
      lastWorn: null,
      tags: [],
      createdAt: now,
      updatedAt: now,
    ),
    Combination(
      id: 'mock_combo_2',
      userId: userId,
      name: name2,
      description: desc2,
      occasion: 'work',
      season: 'all-season',
      clothingItems: [
        CombinationItem(clothingId: clothingIds[0], category: 'top', isRequired: true),
        CombinationItem(clothingId: clothingIds[2], category: 'bottom', isRequired: true),
      ],
      isAIGenerated: true,
      isFavorite: false,
      rating: null,
      timesWorn: 0,
      lastWorn: null,
      tags: [],
      createdAt: now,
      updatedAt: now,
    ),
    Combination(
      id: 'mock_combo_3',
      userId: userId,
      name: name3,
      description: desc3,
      occasion: 'party',
      season: 'all-season',
      clothingItems: [
        CombinationItem(clothingId: clothingIds[0], category: 'top', isRequired: true),
        CombinationItem(clothingId: clothingIds[1], category: 'bottom', isRequired: true),
      ],
      isAIGenerated: true,
      isFavorite: false,
      rating: null,
      timesWorn: 0,
      lastWorn: null,
      tags: [],
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
