import '../models/clothing.dart';
import '../models/combination.dart';
import '../models/user.dart' as app_user;

/// Base type for Firestore access so real and mock implementations can be swapped.
abstract class FirestoreServiceBase {
  Future<void> setUserProfile(String uid, String email, String firstName, String lastName);
  Future<app_user.User?> getUserProfile(String uid);
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates);

  Future<Clothing?> addClothing(String userId, Map<String, dynamic> data);
  Future<void> setClothing(String userId, String clothingId, Map<String, dynamic> data);
  Future<Clothing?> getClothing(String userId, String clothingId);
  Future<List<Clothing>> getAllClothing(String userId, {String? season, String? category, String? style});
  Stream<List<Clothing>> clothingStream(String userId);
  Future<void> updateClothing(String userId, String clothingId, Map<String, dynamic> updates);
  Future<void> deleteClothing(String userId, String clothingId);

  Future<Combination?> addCombination(String userId, Map<String, dynamic> data);
  Future<void> setCombination(String userId, String combinationId, Map<String, dynamic> data);
  Future<List<Combination>> getCombinations(String userId, {int limit = 50, bool? isFavorite});
  Stream<List<Combination>> combinationsStream(String userId);
  Future<void> updateCombination(String userId, String combinationId, Map<String, dynamic> updates);
  Future<void> deleteCombination(String userId, String combinationId);
}
