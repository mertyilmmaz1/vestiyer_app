import '../models/clothing.dart';

/// Inventory categories matching [combinationEngine.js] - top, bottom, outerwear,
/// shoes, dress, accessory.
const List<String> kInventoryCategories = [
  'top',
  'bottom',
  'outerwear',
  'shoes',
  'dress',
  'accessory',
];

/// Categories that are typically expected for outfit building.
/// Missing these affects combination quality.
const List<String> kExpectedCategories = ['top', 'bottom', 'shoes'];

/// Maps a single [Clothing] item to inventory category (same logic as combinationEngine.js).
String _mapToInventoryCategory(Clothing item) {
  final cat = (item.category).toLowerCase().trim();
  final adv = item.advancedAnalysis;
  final mainGroup = (adv?.mainGroup ?? '').toLowerCase().replaceAll(' ', '_');

  if (cat == 'dress' || mainGroup.contains('elbise')) return 'dress';
  if (cat == 'top' ||
      mainGroup.contains('ust_giyim') ||
      mainGroup.contains('ustgiyim')) {
    return 'top';
  }
  if (cat == 'bottom' ||
      mainGroup.contains('alt_giyim') ||
      mainGroup.contains('altgiyim')) {
    return 'bottom';
  }
  if (cat == 'outerwear' ||
      mainGroup.contains('dis_giyim') ||
      mainGroup.contains('disgiyim')) {
    return 'outerwear';
  }
  if (cat == 'shoes' || mainGroup.contains('ayakkabi')) return 'shoes';
  if (cat == 'accessory' || mainGroup.contains('aksesuar')) return 'accessory';
  return 'top'; // default
}

/// Season names in Turkish for AI context.
const Map<String, String> _seasonMap = {
  'ilkbahar': 'ilkbahar',
  'yaz': 'yaz',
  'sonbahar': 'sonbahar',
  'kis': 'kış',
  'kış': 'kış',
  'tum_yil': 'tüm yıl',
  'tüm yıl': 'tüm yıl',
  'all-season': 'tüm yıl',
};

/// Normalizes season string to Turkish key.
String _normalizeSeason(String? s) {
  if (s == null || s.isEmpty) return 'tüm yıl';
  final t = s.toLowerCase().trim();
  if (_seasonMap.containsKey(t)) return _seasonMap[t]!;
  if (t.contains('ilkbahar') || t.contains('spring')) return 'ilkbahar';
  if (t.contains('yaz') || t.contains('summer')) return 'yaz';
  if (t.contains('sonbahar') || t.contains('fall')) return 'sonbahar';
  if (t.contains('kis') || t.contains('kış') || t.contains('winter')) return 'kış';
  return t;
}

/// Builds a compact wardrobe summary for AI chat context.
/// Reduces token usage by ~90% vs raw clothing list.
Map<String, dynamic> buildWardrobeSummary(List<Clothing> items) {
  final counts = <String, int>{
    for (final c in kInventoryCategories) c: 0,
  };

  final styleCounts = <String, int>{};
  final colorCounts = <String, int>{};
  final seasonSet = <String>{};

  for (final item in items) {
    final inv = _mapToInventoryCategory(item);
    counts[inv] = (counts[inv] ?? 0) + 1;

    // Styles (can be comma-separated)
    final styleStr = item.advancedAnalysis?.style ?? item.formattedAnalysis?.stil;
    if (styleStr != null && styleStr.isNotEmpty) {
      for (final s in styleStr.split(',')) {
        final t = s.trim().toLowerCase();
        if (t.isNotEmpty) {
          styleCounts[t] = (styleCounts[t] ?? 0) + 1;
        }
      }
    }

    // Colors
    if (item.colors.isNotEmpty) {
      for (final c in item.colors) {
        final t = c.trim().toLowerCase();
        if (t.isNotEmpty) {
          colorCounts[t] = (colorCounts[t] ?? 0) + 1;
        }
      }
    } else {
      final c = item.advancedAnalysis?.color ?? item.formattedAnalysis?.renk;
      if (c != null && c.isNotEmpty) {
        for (final part in c.split(',')) {
          final t = part.trim().toLowerCase();
          if (t.isNotEmpty) {
            colorCounts[t] = (colorCounts[t] ?? 0) + 1;
          }
        }
      }
    }

    // Seasons
    final seasonStr = item.advancedAnalysis?.season ?? item.formattedAnalysis?.sezon;
    if (seasonStr != null && seasonStr.isNotEmpty) {
      for (final part in seasonStr.split(',')) {
        seasonSet.add(_normalizeSeason(part.trim()));
      }
    } else {
      seasonSet.add('tüm yıl');
    }
  }

  // Dominant styles (top 3)
  final dominantStyles = styleCounts.entries
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final styles = dominantStyles.take(5).map((e) => e.key).toList();

  // Dominant colors (top 5)
  final dominantColors = colorCounts.entries
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final colors = dominantColors.take(5).map((e) => e.key).toList();

  // Missing categories (expected but 0 count)
  final missingCategories = kExpectedCategories
      .where((c) => (counts[c] ?? 0) == 0)
      .toList();

  // Confidence: low (<5), medium (5-15), high (>15)
  String confidenceLevel;
  if (items.length < 5) {
    confidenceLevel = 'low';
  } else if (items.length <= 15) {
    confidenceLevel = 'medium';
  } else {
    confidenceLevel = 'high';
  }

  return {
    'counts': counts,
    'dominant_styles': styles,
    'dominant_colors': colors,
    'seasons': seasonSet.toList(),
    'missing_categories': missingCategories,
    'confidence_level': confidenceLevel,
    'total_items': items.length,
  };
}
