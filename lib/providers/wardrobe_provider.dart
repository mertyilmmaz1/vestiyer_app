import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/clothing.dart';
import '../services/cloud_functions_service.dart';
import '../services/firestore_service_base.dart';
import '../services/firebase_storage_service.dart';

class WardrobeProvider with ChangeNotifier {
  final List<Clothing> _items = [];
  final FirestoreServiceBase _firestore;
  final FirebaseStorageService _storage;
  final CloudFunctionsService _functions;
  bool _isLoading = false;
  String? _currentUserId;
  Map<String, dynamic>? _lastResponse;

  WardrobeProvider(this._firestore, this._storage, this._functions);

  List<Clothing> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;

  Map<String, dynamic>? getLastResponse() => _lastResponse;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      loadClothingItems();
    }
  }

  Future<void> loadClothingItems() async {
    if (_currentUserId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final items = await _firestore.getAllClothing(_currentUserId!);
      _items.clear();
      _items.addAll(items);
      notifyListeners();
    } catch (e) {
      debugPrint('Kıyafetler yüklenirken hata oluştu: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClothingItem(File imageFile, {String? title}) async {
    if (_currentUserId == null) {
      throw Exception('Kullanıcı girişi yapılmamış');
    }

    try {
      _isLoading = true;
      notifyListeners();

      final compressedImage = await _compressImage(imageFile);
      final imageUrl = await _storage.uploadClothingImage(
        _currentUserId!,
        compressedImage,
      );
      await compressedImage.delete();

      final result = await _functions.analyzeClothing(
        _currentUserId!,
        imageUrl,
        title: title,
      );

      final clothingId = result['clothingId'] as String?;
      if (clothingId != null) {
        final clothing = await _firestore.getClothing(_currentUserId!, clothingId);
        if (clothing != null) {
          _items.insert(0, clothing);
          _lastResponse = {
            'description': clothing.advancedAnalysis?.details ??
                clothing.formattedAnalysis?.detaylar ??
                clothing.title,
          };
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('HATA - Kıyafet eklenirken hata oluştu: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      if (!await file.exists()) {
        throw Exception('Resim dosyası bulunamadı: ${file.path}');
      }
      final fileSize = await file.length();
      if (fileSize < 500 * 1024) return file;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw Exception('Resim dosyası boş');

      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Resim decode edilemedi. Desteklenen formatlar: JPEG, PNG, GIF, BMP');
      }

      int targetWidth = 800;
      int targetHeight = (image.height * targetWidth / image.width).round();
      if (targetHeight < 600) {
        targetHeight = 600;
        targetWidth = (image.width * targetHeight / image.height).round();
      }

      if (image.width <= 800 && image.height <= 600) {
        final compressed = img.encodeJpg(image, quality: 85);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}.jpg');
        await tempFile.writeAsBytes(compressed);
        return tempFile;
      }

      final resized = img.copyResize(image,
          width: targetWidth, height: targetHeight, interpolation: img.Interpolation.linear);
      final compressed = img.encodeJpg(resized, quality: 85);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}.jpg');
      await tempFile.writeAsBytes(compressed);
      return tempFile;
    } catch (e) {
      debugPrint('Resim sıkıştırma hatası: $e');
      throw Exception('Resim sıkıştırılamadı: $e');
    }
  }

  Future<void> deleteClothingItem(Clothing item) async {
    if (_currentUserId == null) {
      throw Exception('Kullanıcı girişi yapılmamış');
    }
    try {
      await _firestore.deleteClothing(_currentUserId!, item.id);
      _items.removeWhere((i) => i.id == item.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting clothing item: $e');
      rethrow;
    }
  }

  void removeItemLocally(Clothing item) {
    _items.removeWhere((i) => i.id == item.id);
    notifyListeners();
  }

  void addItemLocally(Clothing item) {
    if (!_items.any((i) => i.id == item.id)) {
      _items.add(item);
      notifyListeners();
    }
  }

  Future<void> resetWardrobe() async {
    _items.clear();
    notifyListeners();
  }

  List<Clothing> getItemsByCategory(String category) {
    return _items
        .where((item) => item.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<Clothing> getItemsBySeason(String season) {
    return _items
        .where((item) =>
            item.advancedAnalysis?.season?.toLowerCase() == season.toLowerCase() ||
            item.advancedAnalysis?.season?.toLowerCase() == 'all-season')
        .toList();
  }

  List<Clothing> getItemsByStyle(String style) {
    return _items
        .where((item) =>
            item.advancedAnalysis?.style?.toLowerCase() == style.toLowerCase())
        .toList();
  }

  Map<String, int> getCategoryStats() {
    Map<String, int> stats = {};
    for (var item in _items) {
      stats[item.category] = (stats[item.category] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> getSeasonStats() {
    Map<String, int> stats = {};
    for (var item in _items) {
      String season = item.advancedAnalysis?.season ?? 'unknown';
      stats[season] = (stats[season] ?? 0) + 1;
    }
    return stats;
  }

  String getFormattedClothingItems() {
    return _items.map((item) {
      return '''[Kıyafet ${item.id}]
ID: ${item.id}
Başlık: ${item.title}
Kategori: ${item.category}
Ana Grup: ${item.advancedAnalysis?.mainGroup ?? 'Belirtilmemiş'}
Renk: ${item.colors.isNotEmpty ? item.colors.join(', ') : (item.advancedAnalysis?.color ?? 'Belirtilmemiş')}
Materyal: ${item.advancedAnalysis?.material ?? 'Belirtilmemiş'}
Stil: ${item.advancedAnalysis?.style ?? 'Belirtilmemiş'}
Sezon: ${item.advancedAnalysis?.season ?? 'Belirtilmemiş'}
Detaylar: ${item.advancedAnalysis?.details ?? 'Belirtilmemiş'}
-------------------''';
    }).join('\n\n');
  }
}
