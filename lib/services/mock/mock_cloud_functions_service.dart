import '../cloud_functions_service.dart';

/// Localized mock messages by locale (tr, en). Used when [locale] is passed to mock callables.
const Map<String, Map<String, String>> _mockMessages = {
  'tr': {
    'analysisDone': 'Mock analiz tamamlandı.',
    'combinationsDone': 'Mock kombinler oluşturuldu.',
    'styleAdvice':
        'Mock stil önerisi: Bu kombinasyon günlük kullanım için uygundur.',
    'vpsNotConfigured': 'Mock modda VPS yapılandırılmadı',
  },
  'en': {
    'analysisDone': 'Mock analysis complete.',
    'combinationsDone': 'Mock combinations created.',
    'styleAdvice':
        'Mock style advice: This combination is suitable for casual wear.',
    'vpsNotConfigured': 'VPS not configured in mock mode',
  },
};

String _msg(String? locale, String key) {
  final lang = (locale == 'tr' || locale == 'en') ? locale! : 'en';
  return _mockMessages[lang]?[key] ?? _mockMessages['en']![key]!;
}

/// Mock Cloud Functions: returns fake data without calling Firebase.
/// Accepts [locale] for localized response messages.
class MockCloudFunctionsService extends CloudFunctionsService {
  @override
  Future<Map<String, dynamic>> analyzeClothing(String userId, String imageUrl,
      {String? title, String? locale}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'success': true,
      'clothingId': 'mock_${DateTime.now().millisecondsSinceEpoch}',
      'message': _msg(locale, 'analysisDone'),
    };
  }

  @override
  Future<Map<String, dynamic>> generateCombinations(
    String userId, {
    bool forceGenerate = false,
    String? occasion,
    String? locale,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'success': true,
      'message': _msg(locale, 'combinationsDone'),
      'savedCombinations': [
        {'id': 'mock_1', 'name': 'Casual'},
        {'id': 'mock_2', 'name': 'Work'},
        {'id': 'mock_3', 'name': 'Special'},
      ],
      'totalItems': 5,
      'usedItems': 5,
    };
  }

  @override
  Future<Map<String, dynamic>> getStyleAdvice(
    String message, {
    List<Map<String, dynamic>>? conversationHistory,
    Map<String, dynamic>? wardrobeSummary,
    String? locale,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'success': true,
      'response': _msg(locale, 'styleAdvice'),
    };
  }

  @override
  Future<Map<String, dynamic>> managePremiumStatus(
      String userId, Map<String, dynamic> payload,
      {String? locale}) async {
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> checkSegmentServiceHealth() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'ok': false,
      'configured': false,
      'error': _msg(null, 'vpsNotConfigured'),
    };
  }
}
