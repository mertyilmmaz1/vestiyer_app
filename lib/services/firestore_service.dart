import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vestiyer_nodejs/core/product/constants/firestore_collections.dart';
import '../models/clothing.dart';
import '../models/combination.dart';
import '../models/outfit_log.dart';
import '../models/user.dart' as app_user;
import 'firestore_service_base.dart';

/// Firestore collections:
/// - users/{uid} - user profile
/// - users/{uid}/clothing/{clothingId}
/// - users/{uid}/combinations/{combinationId}
class FirestoreService extends FirestoreServiceBase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- User profile ----------

  @override
  Future<void> setUserProfile(String uid, String email, String firstName,
      String lastName) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'isPremium': false,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<app_user.User?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['_id'] = doc.id;
    return app_user.User.fromJson(data);
  }

  Stream<app_user.User?> userProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = Map<String, dynamic>.from(snap.data()!);
      data['_id'] = snap.id;
      return app_user.User.fromJson(data);
    });
  }

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(uid).update(updates);
  }

  // ---------- Clothing ----------

  @override
  Future<Clothing?> addClothing(String userId, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing')
        .add(data);
    final doc = await ref.get();
    if (doc.data() == null) return null;
    final out = Map<String, dynamic>.from(doc.data()!);
    out['_id'] = doc.id;
    out['userId'] = userId;
    _convertTimestamps(out, ['createdAt', 'updatedAt']);
    return Clothing.fromJson(out);
  }

  @override
  Future<void> setClothing(
      String userId, String clothingId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (data.containsKey('createdAt') == false) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing')
        .doc(clothingId)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<Clothing?> getClothing(String userId, String clothingId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing')
        .doc(clothingId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['_id'] = doc.id;
    data['userId'] = userId;
    _convertTimestamps(data, ['createdAt', 'updatedAt']);
    return Clothing.fromJson(data);
  }

  @override
  Future<List<Clothing>> getAllClothing(
    String userId, {
    String? season,
    String? category,
    String? style,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing')
        .orderBy('createdAt', descending: true);

    final snapshot = await q.get();
    final list = <Clothing>[];
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['_id'] = doc.id;
      data['userId'] = userId;
      _convertTimestamps(data, ['createdAt', 'updatedAt']);
      final item = Clothing.fromJson(data);
      if (season != null &&
          season != 'all' &&
          item.advancedAnalysis?.season?.toLowerCase() != season.toLowerCase() &&
          item.advancedAnalysis?.season?.toLowerCase() != 'all-season') {
        continue;
      }
      if (category != null &&
          category != 'all' &&
          item.category.toLowerCase() != category.toLowerCase()) {
        continue;
      }
      if (style != null &&
          style != 'all' &&
          item.advancedAnalysis?.style?.toLowerCase() != style.toLowerCase()) {
        continue;
      }
      list.add(item);
    }
    return list;
  }

  @override
  Stream<List<Clothing>> clothingStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['_id'] = doc.id;
        data['userId'] = userId;
        _convertTimestamps(data, ['createdAt', 'updatedAt']);
        return Clothing.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> updateClothing(
      String userId, String clothingId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing')
        .doc(clothingId)
        .update(updates);
  }

  @override
  Future<void> deleteClothing(String userId, String clothingId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('clothing')
        .doc(clothingId)
        .delete();
  }

  // ---------- Combinations ----------

  @override
  Future<Combination?> addCombination(
      String userId, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore
        .collection('users')
        .doc(userId)
        .collection('combinations')
        .add(data);
    final doc = await ref.get();
    if (doc.data() == null) return null;
    final out = Map<String, dynamic>.from(doc.data()!);
    out['_id'] = doc.id;
    out['userId'] = userId;
    _convertTimestamps(out, ['createdAt', 'updatedAt', 'lastWorn']);
    if (out['clothingItems'] != null) {
      for (var i = 0; i < (out['clothingItems'] as List).length; i++) {
        final item = (out['clothingItems'] as List)[i];
        if (item is Map) {
          (out['clothingItems'] as List)[i] =
              Map<String, dynamic>.from(item);
        }
      }
    }
    return Combination.fromJson(out);
  }

  @override
  Future<void> setCombination(
      String userId, String combinationId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('combinations')
        .doc(combinationId)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<List<Combination>> getCombinations(
    String userId, {
    int limit = 50,
    bool? isFavorite,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .doc(userId)
        .collection('combinations')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (isFavorite != null) {
      q = q.where('isFavorite', isEqualTo: isFavorite);
    }
    final snapshot = await q.get();
    final list = <Combination>[];
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['_id'] = doc.id;
      data['userId'] = userId;
      _convertTimestamps(data, ['createdAt', 'updatedAt', 'lastWorn']);
      if (data['clothingItems'] != null) {
        data['clothingItems'] = (data['clothingItems'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      list.add(Combination.fromJson(data));
    }
    return list;
  }

  @override
  Stream<List<Combination>> combinationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('combinations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['_id'] = doc.id;
        data['userId'] = userId;
        _convertTimestamps(data, ['createdAt', 'updatedAt', 'lastWorn']);
        if (data['clothingItems'] != null) {
          data['clothingItems'] = (data['clothingItems'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        return Combination.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> updateCombination(
      String userId, String combinationId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('combinations')
        .doc(combinationId)
        .update(updates);
  }

  @override
  Future<void> deleteCombination(String userId, String combinationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('combinations')
        .doc(combinationId)
        .delete();
  }

  // ---------- Outfit logs (giyim geçmişi) ----------

  @override
  Future<OutfitLog?> addOutfitLog(
      String userId, Map<String, dynamic> data) async {
    final wornAt = data['wornAt'] is DateTime
        ? (data['wornAt'] as DateTime)
        : DateTime.now();
    final logData = {
      'combinationId': data['combinationId'] as String,
      'wornAt': Timestamp.fromDate(wornAt),
      if (data['note'] != null) 'note': data['note'] as String?,
      if (data['combinationName'] != null)
        'combinationName': data['combinationName'] as String?,
      if (data['occasion'] != null) 'occasion': data['occasion'] as String?,
    };
    final ref = await _firestore
        .collection('users')
        .doc(userId)
        .collection(FirestoreCollections.outfitLogs)
        .add(logData);
    final doc = await ref.get();
    if (doc.data() == null) return null;
    final out = Map<String, dynamic>.from(doc.data()!);
    out['_id'] = doc.id;
    out['userId'] = userId;
    _convertTimestamps(out, ['wornAt']);
    final log = OutfitLog.fromJson(out);
    // Update combination: increment timesWorn, set lastWorn
    final combinationId = data['combinationId'] as String?;
    if (combinationId != null && combinationId.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('combinations')
          .doc(combinationId)
          .update({
        'timesWorn': FieldValue.increment(1),
        'lastWorn': Timestamp.fromDate(wornAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .doc(userId)
        .collection(FirestoreCollections.outfitLogs)
        .orderBy('wornAt', descending: true)
        .limit(limit);
    if (from != null) {
      q = q.where('wornAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('wornAt', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final snapshot = await q.get();
    final list = <OutfitLog>[];
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['_id'] = doc.id;
      data['userId'] = userId;
      _convertTimestamps(data, ['wornAt']);
      list.add(OutfitLog.fromJson(data));
    }
    return list;
  }

  // ---------- Wardrobe analysis ----------

  static const String _wardrobeAnalysisDocId = 'current';

  @override
  Future<void> setWardrobeAnalysis(
      String userId, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.wardrobeAnalysis)
        .doc(_wardrobeAnalysisDocId)
        .set(payload, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>?> getWardrobeAnalysis(String userId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.wardrobeAnalysis)
        .doc(_wardrobeAnalysisDocId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    _convertTimestamps(data, ['updatedAt']);
    return data;
  }

  void _convertTimestamps(
      Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      if (data[k] == null) continue;
      final v = data[k];
      if (v is Timestamp) {
        data[k] = v.toDate().toIso8601String();
      }
    }
  }
}
