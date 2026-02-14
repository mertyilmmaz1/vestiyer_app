import 'package:cloud_functions/cloud_functions.dart';

/// Calls Firebase callable functions for AI (analyzeClothing, generateCombinations, getStyleAdvice).
/// Auth context is sent automatically by the SDK.
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Analyze clothing image at [imageUrl] and save result to Firestore.
  /// Returns the created clothing document id or throws.
  Future<Map<String, dynamic>> analyzeClothing(
      String userId, String imageUrl, {String? title}) async {
    final callable = _functions.httpsCallable('analyzeClothing');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'imageUrl': imageUrl,
      if (title != null && title.isNotEmpty) 'title': title,
    });
    return result.data;
  }

  /// Generate outfit combinations. Optional [occasion] and [forceGenerate].
  Future<Map<String, dynamic>> generateCombinations(
    String userId, {
    bool forceGenerate = false,
    String? occasion,
  }) async {
    final callable = _functions.httpsCallable('generateCombinations');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'forceGenerate': forceGenerate,
      if (occasion != null && occasion.isNotEmpty) 'occasion': occasion,
    });
    return result.data;
  }

  /// Get style advice from AI stylist (chat).
  /// Uses [wardrobeSummary] (compact JSON) instead of raw wardrobe list.
  Future<Map<String, dynamic>> getStyleAdvice(
    String message, {
    List<Map<String, dynamic>>? conversationHistory,
    Map<String, dynamic>? wardrobeSummary,
  }) async {
    final callable = _functions.httpsCallable('getStyleAdvice');
    final result = await callable.call<Map<String, dynamic>>({
      'message': message,
      if (conversationHistory != null) 'conversationHistory': conversationHistory,
      if (wardrobeSummary != null) 'wardrobeSummary': wardrobeSummary,
    });
    return result.data;
  }

  /// Manage premium status (optional, for subscription flow).
  Future<Map<String, dynamic>> managePremiumStatus(
      String userId, Map<String, dynamic> payload) async {
    final callable = _functions.httpsCallable('managePremiumStatus');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      ...payload,
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
}
