import '../models/clothing.dart';
import '../models/combination.dart';
import '../models/outfit_log.dart';
import '../models/user.dart' as app_user;
import 'firestore_service_base.dart';
import 'hive_cache_service.dart';

/// Read-through cache over Firestore: reduces redundant Firebase reads by using Hive.
/// Streams are passed through to the delegate (no cache). Writes invalidate cache.
class CachedFirestoreService extends FirestoreServiceBase {
  CachedFirestoreService(this._delegate, this._cache);

  final FirestoreServiceBase _delegate;
  final HiveCacheService _cache;

  @override
  Future<void> setUserProfile(
      String uid, String email, String firstName, String lastName) async {
    await _delegate.setUserProfile(uid, email, firstName, lastName);
    await _cache.invalidateUser(uid);
  }

  @override
  Future<app_user.User?> getUserProfile(String uid) async {
    final cached = _cache.getUserProfile(uid);
    if (cached != null) return cached;
    final user = await _delegate.getUserProfile(uid);
    if (user != null) await _cache.setUserProfile(uid, user);
    return user;
  }

  @override
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    await _delegate.updateUserProfile(uid, updates);
    await _cache.invalidateUser(uid);
  }

  @override
  Future<void> setUserStyleProfile(
      String uid, Map<String, dynamic> styleProfile) async {
    await _delegate.setUserStyleProfile(uid, styleProfile);
    await _cache.invalidateUser(uid);
  }

  @override
  Future<Clothing?> addClothing(
      String userId, Map<String, dynamic> data) async {
    final result = await _delegate.addClothing(userId, data);
    await _cache.invalidateClothing(userId);
    if (result != null) _cache.setClothing(userId, result.id, result);
    return result;
  }

  @override
  Future<void> setClothing(
      String userId, String clothingId, Map<String, dynamic> data) async {
    await _delegate.setClothing(userId, clothingId, data);
    await _cache.invalidateClothing(userId);
    await _cache.invalidateClothingItem(userId, clothingId);
  }

  @override
  Future<Clothing?> getClothing(String userId, String clothingId) async {
    final cached = _cache.getClothing(userId, clothingId);
    if (cached != null) return cached;
    final item = await _delegate.getClothing(userId, clothingId);
    if (item != null) await _cache.setClothing(userId, clothingId, item);
    return item;
  }

  @override
  Future<List<Clothing>> getAllClothing(
    String userId, {
    String? season,
    String? category,
    String? style,
  }) async {
    final cached = _cache.getClothingList(userId);
    if (cached != null) {
      return _filterClothingList(cached,
          season: season, category: category, style: style);
    }
    final list = await _delegate.getAllClothing(userId);
    await _cache.setClothingList(userId, list);
    return _filterClothingList(list,
        season: season, category: category, style: style);
  }

  static List<Clothing> _filterClothingList(
    List<Clothing> list, {
    String? season,
    String? category,
    String? style,
  }) {
    if (season == null && category == null && style == null) return list;
    return list.where((item) {
      if (season != null &&
          season != 'all' &&
          item.advancedAnalysis?.season?.toLowerCase() !=
              season.toLowerCase() &&
          item.advancedAnalysis?.season?.toLowerCase() != 'all-season') {
        return false;
      }
      if (category != null &&
          category != 'all' &&
          item.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (style != null &&
          style != 'all' &&
          item.advancedAnalysis?.style?.toLowerCase() != style.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Stream<List<Clothing>> clothingStream(String userId) =>
      _delegate.clothingStream(userId);

  @override
  Future<void> updateClothing(
      String userId, String clothingId, Map<String, dynamic> updates) async {
    await _delegate.updateClothing(userId, clothingId, updates);
    await _cache.invalidateClothing(userId);
    await _cache.invalidateClothingItem(userId, clothingId);
  }

  @override
  Future<void> deleteClothing(String userId, String clothingId) async {
    await _delegate.deleteClothing(userId, clothingId);
    await _cache.invalidateClothing(userId);
    await _cache.invalidateClothingItem(userId, clothingId);
  }

  @override
  Future<Combination?> addCombination(
      String userId, Map<String, dynamic> data) async {
    final result = await _delegate.addCombination(userId, data);
    await _cache.invalidateCombinations(userId);
    return result;
  }

  @override
  Future<void> setCombination(
      String userId, String combinationId, Map<String, dynamic> data) async {
    await _delegate.setCombination(userId, combinationId, data);
    await _cache.invalidateCombinations(userId);
  }

  @override
  Future<List<Combination>> getCombinations(
    String userId, {
    int limit = 50,
    bool? isFavorite,
  }) async {
    final cached =
        _cache.getCombinations(userId, limit: limit, isFavorite: isFavorite);
    if (cached != null) return cached;
    final list = await _delegate.getCombinations(userId,
        limit: limit, isFavorite: isFavorite);
    await _cache.setCombinations(userId, list,
        limit: limit, isFavorite: isFavorite);
    return list;
  }

  @override
  Stream<List<Combination>> combinationsStream(String userId) =>
      _delegate.combinationsStream(userId);

  @override
  Future<void> updateCombination(
      String userId, String combinationId, Map<String, dynamic> updates) async {
    await _delegate.updateCombination(userId, combinationId, updates);
    await _cache.invalidateCombinations(userId);
  }

  @override
  Future<void> deleteCombination(String userId, String combinationId) async {
    await _delegate.deleteCombination(userId, combinationId);
    await _cache.invalidateCombinations(userId);
  }

  @override
  Future<OutfitLog?> addOutfitLog(
      String userId, Map<String, dynamic> data) async {
    final result = await _delegate.addOutfitLog(userId, data);
    await _cache.invalidateCombinations(userId);
    return result;
  }

  @override
  Future<List<OutfitLog>> getOutfitLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    return _delegate.getOutfitLogs(userId, from: from, to: to, limit: limit);
  }

  @override
  Future<void> setWardrobeAnalysis(
      String userId, Map<String, dynamic> data) async {
    await _delegate.setWardrobeAnalysis(userId, data);
  }

  @override
  Future<Map<String, dynamic>?> getWardrobeAnalysis(String userId) async {
    return _delegate.getWardrobeAnalysis(userId);
  }
}
