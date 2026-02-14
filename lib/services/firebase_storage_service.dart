import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Upload clothing images to Firebase Storage at clothing_images/{userId}/{filename}.
/// Profile avatars at profile_images/{userId}/avatar.{ext}.
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _prefix = 'clothing_images';
  static const String _profilePrefix = 'profile_images';

  /// Upload a file; returns the download URL.
  Future<String> uploadClothingImage(String userId, File file,
      {String? customFileName}) async {
    final name =
        customFileName ?? '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(RegExp(r'[/\\]')).last}';
    final ref = _storage.ref().child(_prefix).child(userId).child(name);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Upload from bytes (e.g. after compression).
  Future<String> uploadClothingImageBytes(
      String userId, List<int> bytes, String filename) async {
    final ref = _storage.ref().child(_prefix).child(userId).child(filename);
    await ref.putData(Uint8List.fromList(bytes));
    return ref.getDownloadURL();
  }

  /// Delete file by full path (e.g. path from Storage ref) or by URL.
  Future<void> deleteByUrl(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }

  /// Get reference for a path under user's folder (for rules).
  Reference refForUser(String userId) {
    return _storage.ref().child(_prefix).child(userId);
  }

  /// Upload profile avatar; stored at profile_images/{userId}/avatar.{ext}. Overwrites existing.
  /// Returns the download URL.
  Future<String> uploadProfileImage(String userId, File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext) ? ext : 'jpg';
    final name = 'avatar.$safeExt';
    final ref = _storage.ref().child(_profilePrefix).child(userId).child(name);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Upload profile avatar from bytes (e.g. after compression).
  Future<String> uploadProfileImageBytes(
      String userId, List<int> bytes, String filename) async {
    final ref = _storage.ref().child(_profilePrefix).child(userId).child(filename);
    await ref.putData(Uint8List.fromList(bytes));
    return ref.getDownloadURL();
  }
}
