import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/clothing.dart';
import '../models/combination.dart';
import '../models/user.dart' as app_user;

/// Hive-backed cache for Firestore read-through. Reduces redundant Firebase reads.
/// Box name: [boxName]. Keys: user_uid, clothing_userId, combinations_userId, etc.
class HiveCacheService {
  HiveCacheService(
      {this.boxName = 'firestore_cache', this.userProfileTtlMinutes = 15});

  final String boxName;

  /// TTL for user profile cache (e.g. premium status). Null = no expiry.
  final int userProfileTtlMinutes;

  Box<String>? _box;

  static const _prefixUser = 'user_';
  static const _prefixClothing = 'clothing_';
  static const _prefixClothingItem = 'clothing_item_';
  static const _prefixCombinations = 'combinations_';

  Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<String>(boxName);
  }

  Box<String> get _b {
    final b = _box;
    if (b == null)
      throw StateError('HiveCacheService not initialized. Call init() first.');
    return b;
  }

  // ----- User profile -----

  app_user.User? getUserProfile(String uid) {
    final raw = _b.get('$_prefixUser$uid');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = map['cachedAt'] as String?;
      if (userProfileTtlMinutes > 0 && cachedAt != null) {
        final at = DateTime.tryParse(cachedAt);
        if (at != null &&
            DateTime.now().difference(at).inMinutes > userProfileTtlMinutes) {
          _b.delete('$_prefixUser$uid');
          return null;
        }
      }
      final data = map['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return app_user.User.fromJson(data);
    } catch (_) {
      _b.delete('$_prefixUser$uid');
      return null;
    }
  }

  Future<void> setUserProfile(String uid, app_user.User user) async {
    await _b.put(
        '$_prefixUser$uid',
        jsonEncode({
          'data': user.toJson(),
          'cachedAt': DateTime.now().toIso8601String(),
        }));
  }

  Future<void> invalidateUser(String uid) async {
    await _b.delete('$_prefixUser$uid');
  }

  // ----- Clothing list (full list per user; filtering applied in caller) -----

  List<Clothing>? getClothingList(String userId) {
    final raw = _b.get('$_prefixClothing$userId');
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Clothing.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _b.delete('$_prefixClothing$userId');
      return null;
    }
  }

  Future<void> setClothingList(String userId, List<Clothing> list) async {
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _b.put('$_prefixClothing$userId', encoded);
  }

  Future<void> invalidateClothing(String userId) async {
    await _b.delete('$_prefixClothing$userId');
    final prefix = '$_prefixClothingItem${userId}_';
    final keysToRemove =
        _b.keys.where((k) => k.toString().startsWith(prefix)).toList();
    for (final k in keysToRemove) {
      await _b.delete(k);
    }
  }

  // ----- Single clothing item (optional) -----

  Clothing? getClothing(String userId, String clothingId) {
    final raw = _b.get('$_prefixClothingItem${userId}_$clothingId');
    if (raw == null) return null;
    try {
      return Clothing.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      _b.delete('$_prefixClothingItem${userId}_$clothingId');
      return null;
    }
  }

  Future<void> setClothing(
      String userId, String clothingId, Clothing item) async {
    await _b.put(
        '$_prefixClothingItem${userId}_$clothingId', jsonEncode(item.toJson()));
  }

  Future<void> invalidateClothingItem(String userId, String clothingId) async {
    await _b.delete('$_prefixClothingItem${userId}_$clothingId');
  }

  // ----- Combinations (default params: limit 50, isFavorite null) -----

  List<Combination>? getCombinations(String userId,
      {int limit = 50, bool? isFavorite}) {
    final key = _combinationsKey(userId, limit: limit, isFavorite: isFavorite);
    final raw = _b.get(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Combination.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _b.delete(key);
      return null;
    }
  }

  Future<void> setCombinations(
    String userId,
    List<Combination> list, {
    int limit = 50,
    bool? isFavorite,
  }) async {
    final key = _combinationsKey(userId, limit: limit, isFavorite: isFavorite);
    await _b.put(key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> invalidateCombinations(String userId) async {
    final prefix = '$_prefixCombinations$userId';
    final keysToRemove =
        _b.keys.where((k) => k.toString().startsWith(prefix)).toList();
    for (final k in keysToRemove) {
      await _b.delete(k);
    }
  }

  Future<void> clearAll() async {
    await _b.clear();
  }

  String _combinationsKey(String userId, {int limit = 50, bool? isFavorite}) {
    final fav = isFavorite == null ? 'n' : (isFavorite ? 't' : 'f');
    return '${_prefixCombinations}${userId}_${limit}_$fav';
  }
}
