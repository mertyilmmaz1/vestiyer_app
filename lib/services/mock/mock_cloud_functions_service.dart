import '../cloud_functions_service.dart';

/// Mock Cloud Functions: returns fake data without calling Firebase.
class MockCloudFunctionsService extends CloudFunctionsService {
  @override
  Future<Map<String, dynamic>> analyzeClothing(String userId, String imageUrl, {String? title}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'success': true,
      'clothingId': 'mock_${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Mock analiz tamamlandı.',
    };
  }

  @override
  Future<Map<String, dynamic>> generateCombinations(
    String userId, {
    bool forceGenerate = false,
    String? occasion,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'success': true,
      'message': 'Mock kombinler oluşturuldu.',
      'savedCombinations': [
        {'id': 'mock_1', 'name': 'Günlük Kombin'},
        {'id': 'mock_2', 'name': 'İş Kombini'},
        {'id': 'mock_3', 'name': 'Özel Kombin'},
      ],
      'totalItems': 5,
      'usedItems': 5,
    };
  }

  @override
  Future<Map<String, dynamic>> getStyleAdvice(
    String message, {
    List<Map<String, dynamic>>? conversationHistory,
    String? wardrobeContext,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'success': true,
      'response': 'Mock stil önerisi: Bu kombinasyon günlük kullanım için uygundur.',
    };
  }

  @override
  Future<Map<String, dynamic>> managePremiumStatus(String userId, Map<String, dynamic> payload) async {
    return {'success': true};
  }
}
