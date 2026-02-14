import 'dart:io';

import '../firebase_storage_service.dart';

/// Mock storage: returns a fake URL without uploading.
class MockFirebaseStorageService extends FirebaseStorageService {
  @override
  Future<String> uploadClothingImage(String userId, File file, {String? customFileName}) async {
    return 'https://mock-storage.example.com/clothing_images/$userId/${customFileName ?? 'mock_${DateTime.now().millisecondsSinceEpoch}.jpg'}';
  }

  @override
  Future<String> uploadClothingImageBytes(String userId, List<int> bytes, String filename) async {
    return 'https://mock-storage.example.com/clothing_images/$userId/$filename';
  }

  @override
  Future<String> uploadProfileImage(String userId, File file) async {
    return 'https://mock-storage.example.com/profile_images/$userId/avatar.jpg';
  }

  @override
  Future<String> uploadProfileImageBytes(
      String userId, List<int> bytes, String filename) async {
    return 'https://mock-storage.example.com/profile_images/$userId/$filename';
  }

  @override
  Future<void> deleteByUrl(String url) async {}
}
