import 'dart:async';

import '../../models/clothing.dart';
import '../../models/combination.dart';
import '../../models/outfit_log.dart';
import '../../models/user.dart' as app_user;
import '../../utils/mock_data_helper.dart';
import '../firestore_service_base.dart';

/// In-memory Firestore implementation for testing without Firebase.
class MockFirestoreService extends FirestoreServiceBase {
  static const String mockUserId = 'mock-user-uid';

  List<Clothing> _clothing = [];
  List<Combination> _combinations = [];
  List<OutfitLog> _outfitLogs = [];
  Map<String, Map<String, dynamic>> _wardrobeAnalysis = {};
  app_user.User? _mockUser;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _clothing =
        await loadSampleClothingFromAssets(userId: mockUserId, limit: 10);
    _combinations = mockCombinations(
        userId: mockUserId, clothingIds: _clothing.map((c) => c.id).toList());
    _mockUser = app_user.User(
      id: mockUserId,
      email: 'test@dolap.ai',
      firstName: 'Test',
      lastName: 'User',
      createdAt: DateTime.now(),
      isActive: true,
      isPremium: false,
    );
    _loaded = true;
  }

  @override
  Future<void> setUserProfile(
      String uid, String email, String firstName, String lastName) async {
    await _ensureLoaded();
    _mockUser = app_user.User(
      id: uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      createdAt: DateTime.now(),
      isActive: true,
      isPremium: false,
    );
  }

  @override
  Future<app_user.User?> getUserProfile(String uid) async {
    await _ensureLoaded();
    if (uid == mockUserId) return _mockUser;
    return null;
  }

  @override
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {}

  @override
  Future<Clothing?> addClothing(
      String userId, Map<String, dynamic> data) async {
    await _ensureLoaded();
    final id = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    final c = Clothing(
      id: id,
      userId: userId,
      title: data['title'] as String? ?? 'Kıyafet',
      category: data['category'] as String? ?? 'top',
      imageUrl: data['imageUrl'] as String? ?? '',
      imagePath: data['imagePath'] as String? ?? '',
      colors: List<String>.from(data['colors'] ?? []),
      advancedAnalysis: null,
      formattedAnalysis: null,
      apiUsage: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _clothing.insert(0, c);
    return c;
  }

  @override
  Future<void> setClothing(
      String userId, String clothingId, Map<String, dynamic> data) async {}

  @override
  Future<Clothing?> getClothing(String userId, String clothingId) async {
    await _ensureLoaded();
    try {
      return _clothing.firstWhere((c) => c.id == clothingId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Clothing>> getAllClothing(String userId,
      {String? season, String? category, String? style}) async {
    await _ensureLoaded();
    if (userId != mockUserId) return [];
    var list = List<Clothing>.from(_clothing);
    if (category != null && category != 'all') {
      list = list
          .where((c) => c.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    if (season != null && season != 'all') {
      list = list
          .where((c) =>
              c.advancedAnalysis?.season?.toLowerCase() ==
                  season.toLowerCase() ||
              c.advancedAnalysis?.season?.toLowerCase() == 'all-season')
          .toList();
    }
    if (style != null && style != 'all') {
      list = list
          .where((c) =>
              c.advancedAnalysis?.style?.toLowerCase() == style.toLowerCase())
          .toList();
    }
    return list;
  }

  @override
  Stream<List<Clothing>> clothingStream(String userId) {
    return Stream.fromFuture(_ensureLoaded()).asyncExpand((_) {
      return Stream.periodic(
          const Duration(seconds: 1), (_) => List<Clothing>.from(_clothing));
    });
  }

  @override
  Future<void> updateClothing(
      String userId, String clothingId, Map<String, dynamic> updates) async {}

  @override
  Future<void> deleteClothing(String userId, String clothingId) async {
    _clothing.removeWhere((c) => c.id == clothingId);
  }

  @override
  Future<Combination?> addCombination(
      String userId, Map<String, dynamic> data) async {
    await _ensureLoaded();
    final id = 'mock_combo_${DateTime.now().millisecondsSinceEpoch}';
    final c = Combination(
      id: id,
      userId: userId,
      name: data['name'] as String? ?? 'Kombin',
      description: data['description'] as String?,
      occasion: data['occasion'] as String? ?? 'casual',
      season: data['season'] as String? ?? 'all-season',
      clothingItems: (data['clothingItems'] as List<dynamic>?)
              ?.map((e) =>
                  CombinationItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      isAIGenerated: data['isAIGenerated'] as bool? ?? true,
      isFavorite: false,
      rating: null,
      timesWorn: 0,
      lastWorn: null,
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _combinations.insert(0, c);
    return c;
  }

  @override
  Future<void> setCombination(
      String userId, String combinationId, Map<String, dynamic> data) async {}

  @override
  Future<List<Combination>> getCombinations(String userId,
      {int limit = 50, bool? isFavorite}) async {
    await _ensureLoaded();
    if (userId != mockUserId) return [];
    var list = List<Combination>.from(_combinations);
    if (isFavorite != null)
      list = list.where((c) => c.isFavorite == isFavorite).toList();
    return list.take(limit).toList();
  }

  @override
  Stream<List<Combination>> combinationsStream(String userId) {
    return Stream.fromFuture(_ensureLoaded()).asyncExpand((_) {
      return Stream.periodic(const Duration(seconds: 1),
          (_) => List<Combination>.from(_combinations));
    });
  }

  @override
  Future<void> updateCombination(String userId, String combinationId,
      Map<String, dynamic> updates) async {}

  @override
  Future<void> deleteCombination(String userId, String combinationId) async {
    _combinations.removeWhere((c) => c.id == combinationId);
  }

  @override
  Future<OutfitLog?> addOutfitLog(
      String userId, Map<String, dynamic> data) async {
    await _ensureLoaded();
    final id = 'mock_log_${DateTime.now().millisecondsSinceEpoch}';
    final wornAt = data['wornAt'] is DateTime
        ? (data['wornAt'] as DateTime)
        : DateTime.now();
    final log = OutfitLog(
      id: id,
      userId: userId,
      combinationId: data['combinationId'] as String? ?? '',
      wornAt: wornAt,
      note: data['note'] as String?,
      combinationName: data['combinationName'] as String?,
      occasion: data['occasion'] as String?,
    );
    _outfitLogs.insert(0, log);
    final comboId = data['combinationId'] as String?;
    if (comboId != null && comboId.isNotEmpty) {
      final idx = _combinations.indexWhere((c) => c.id == comboId);
      if (idx >= 0) {
        final c = _combinations[idx];
        _combinations[idx] = Combination(
          id: c.id,
          userId: c.userId,
          name: c.name,
          description: c.description,
          occasion: c.occasion,
          season: c.season,
          clothingItems: c.clothingItems,
          isAIGenerated: c.isAIGenerated,
          isFavorite: c.isFavorite,
          rating: c.rating,
          timesWorn: c.timesWorn + 1,
          lastWorn: wornAt,
          tags: c.tags,
          createdAt: c.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }
    return log;
  }

  @override
  Future<List<OutfitLog>> getOutfitLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    await _ensureLoaded();
    if (userId != mockUserId) return [];
    var list = List<OutfitLog>.from(_outfitLogs);
    if (from != null) {
      list = list.where((log) => !log.wornAt.isBefore(from)).toList();
    }
    if (to != null) {
      list = list.where((log) => !log.wornAt.isAfter(to)).toList();
    }
    return list.take(limit).toList();
  }

  @override
  Future<void> setWardrobeAnalysis(
      String userId, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = DateTime.now().toIso8601String();
    _wardrobeAnalysis[userId] = payload;
  }

  @override
  Future<Map<String, dynamic>?> getWardrobeAnalysis(String userId) async {
    return _wardrobeAnalysis[userId];
  }
}
