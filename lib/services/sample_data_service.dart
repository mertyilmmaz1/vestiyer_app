// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import '../models/clothing_item.dart';
// class SampleDataService {
//   final FirestoreServiceBase _firestoreService;
//   final FirebaseStorageService _storageService;

//   SampleDataService(this._firestoreService, this._storageService);

//   Future<void> loadSampleData() async {
//     try {
//       // JSON dosyasını oku
//       final jsonString =
//           await rootBundle.loadString('assets/data/sample_clothes.json');
//       final data = json.decode(jsonString);
//       final clothes = List<Map<String, dynamic>>.from(data['clothes']);

//       // Her kıyafet için
//       for (final clothData in clothes) {
//         // Resmi indir
//         final imageUrl = clothData['image_url'] as String;
//         final imageFile = await _downloadImage(imageUrl);

//         if (imageFile != null) {
//           // Kıyafet nesnesini oluştur
//           final item = ClothingItem(
//             category: clothData['category'],
//             description: clothData['description'],
//             color: clothData['color'],
//             material: clothData['material'],
//             style: clothData['style'],
//             season: clothData['season'],
//             imageFile: imageFile,
//           );

//           // Firebase Storage'a yükle, Firestore'a ekle
//           // final uploadedImageUrl = await _storageService.uploadImage(...);
//           // await _firestoreService.addClothingItem(...);

//           // Geçici dosyayı sil
//           await imageFile.delete();
//         }
//       }
//     } catch (e) {
//       print('Test verileri yüklenirken hata: $e');
//       rethrow;
//     }
//   }

//   Future<File?> _downloadImage(String imageUrl) async {
//     try {
//       final response = await http.get(Uri.parse(imageUrl));

//       if (response.statusCode == 200) {
//         // Geçici dosya oluştur
//         final tempDir = await getTemporaryDirectory();
//         final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
//         final file = File('${tempDir.path}/$fileName');

//         // Resmi kaydet
//         await file.writeAsBytes(response.bodyBytes);
//         return file;
//       }
//     } catch (e) {
//       print('Resim indirilirken hata: $e');
//     }
//     return null;
//   }
// }
