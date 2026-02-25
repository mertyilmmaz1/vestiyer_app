import 'package:cloud_functions/cloud_functions.dart';
import '../models/combination.dart';

/// Calls Firebase callable functions for AI (analyzeClothing, generateCombinations, getStyleAdvice).
/// Auth context is sent automatically by the SDK.
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Map<String, dynamic> _normalizeWardrobeSummaryForAi(
      Map<String, dynamic> raw) {
    final categories = Map<String, dynamic>.from(raw['categories'] ?? {});
    final styles = Map<String, dynamic>.from(raw['styles'] ?? {});
    final colors = Map<String, dynamic>.from(raw['colors'] ?? {});
    final seasons = Map<String, dynamic>.from(raw['seasons'] ?? {});

    List<String> topKeys(Map<String, dynamic> map, {int take = 5}) {
      final entries = map.entries.toList()
        ..sort((a, b) =>
            ((b.value as num?) ?? 0).compareTo((a.value as num?) ?? 0));
      return entries.take(take).map((e) => e.key).toList();
    }

    bool containsAnyKey(List<String> aliases) {
      for (final entry in categories.entries) {
        final key = entry.key.toLowerCase();
        final value = (entry.value as num?)?.toInt() ?? 0;
        if (value <= 0) continue;
        if (aliases.any((a) => key.contains(a))) return true;
      }
      return false;
    }

    final missingCategories = <String>[];
    if (!containsAnyKey(['top', 'ust', 'üst', 'gomlek', 'gömlek'])) {
      missingCategories.add('ust');
    }
    if (!containsAnyKey(['bottom', 'alt', 'pantolon', 'etek'])) {
      missingCategories.add('alt');
    }
    if (!containsAnyKey(['shoe', 'ayakk'])) {
      missingCategories.add('ayakkabi');
    }

    return {
      'total_items': (raw['totalItems'] as num?)?.toInt() ?? 0,
      'counts': categories,
      'dominant_styles': topKeys(styles),
      'dominant_colors': topKeys(colors),
      'seasons': topKeys(seasons),
      'missing_categories': missingCategories,
      'confidence_level': 'medium',
    };
  }

  /// Analyze clothing image at [imageUrl] and save result to Firestore.
  /// [locale] optional language code (e.g. 'tr', 'en') for localized API responses.
  Future<Map<String, dynamic>> analyzeClothing(String userId, String imageUrl,
      {String? title, String? locale}) async {
    final callable = _functions.httpsCallable('analyzeClothing');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'imageUrl': imageUrl,
      if (title != null && title.isNotEmpty) 'title': title,
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    });
    return result.data;
  }

  /// Generate outfit combinations. Optional [occasion], [forceGenerate], [locale].
  Future<Map<String, dynamic>> generateCombinations(
    String userId, {
    bool forceGenerate = false,
    String? occasion,
    String? locale,
  }) async {
    final callable = _functions.httpsCallable('generateCombinations');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'forceGenerate': forceGenerate,
      if (occasion != null && occasion.isNotEmpty) 'occasion': occasion,
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    });
    return result.data;
  }

  /// Get style advice from AI stylist (chat). Optional [locale] for response language.
  Future<Map<String, dynamic>> getStyleAdvice(
    String message, {
    List<Map<String, dynamic>>? conversationHistory,
    Map<String, dynamic>? wardrobeSummary,
    String? locale,
  }) async {
    final callable = _functions.httpsCallable('getStyleAdvice');
    final result = await callable.call<Map<String, dynamic>>({
      'message': message,
      if (conversationHistory != null)
        'conversationHistory': conversationHistory,
      if (wardrobeSummary != null) 'wardrobeSummary': wardrobeSummary,
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    });
    return result.data;
  }

  /// Save a combination manually to Firestore. Optional [locale].
  Future<Map<String, dynamic>> saveCombination(
      String userId, Combination combination,
      {String? locale}) async {
    final callable = _functions.httpsCallable('saveCombination');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'combination': {
        'name': combination.name,
        'description': combination.description,
        'occasion': combination.occasion,
        'season': combination.season,
        'items': combination.clothingItems.map((e) => e.clothingId).toList(),
      },
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    });
    return result.data;
  }

  /// Manage premium status (optional, for subscription flow).
  /// [locale] optional; when provided, backend uses it for localized error messages.
  Future<Map<String, dynamic>> managePremiumStatus(
      String userId, Map<String, dynamic> payload,
      {String? locale}) async {
    final callable = _functions.httpsCallable('managePremiumStatus');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      ...payload,
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    });
    return result.data;
  }

  /// VPS segment servisinin sağlık kontrolü. Giriş yapmış kullanıcı gerekir.
  /// Returns: { ok: bool, configured: bool, latencyMs?: int, error?: string, statusCode?: int }
  Future<Map<String, dynamic>> checkSegmentServiceHealth() async {
    final callable = _functions.httpsCallable('checkSegmentServiceHealth');
    final result = await callable.call<Map<String, dynamic>>({});
    return result.data;
  }

  /// Get shopping suggestions from AI. Optional [locale].
  Future<Map<String, dynamic>> getShoppingSuggestions(
    String userId, {
    Map<String, dynamic>? wardrobeSummary,
    String? locale,
  }) async {
    final callable = _functions.httpsCallable('getShoppingSuggestions');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      if (wardrobeSummary != null)
        'wardrobeSummary': _normalizeWardrobeSummaryForAi(wardrobeSummary),
      if (locale != null && locale.isNotEmpty) 'locale': locale,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
