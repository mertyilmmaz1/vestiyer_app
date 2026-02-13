// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/api_usage.dart';
// import '../models/clothing_item.dart';
// import 'package:uuid/uuid.dart';

// class ChatGPTService {
//   final String apiKey;
//   final _uuid = const Uuid();

//   // GPT-4 Turbo pricing (as of March 2024)
//   static const double gpt4TurboInputPricePer1kTokens =
//       0.01; // $0.01 per 1K tokens for input
//   static const double gpt4TurboOutputPricePer1kTokens =
//       0.03; // $0.03 per 1K tokens for output
//   static const double gpt4TurboVisionInputPricePer1kTokens =
//       0.00765; // $0.00765 per 1K tokens for vision input
//   static const double gpt4TurboVisionOutputPricePer1kTokens =
//       0.03; // $0.03 per 1K tokens for vision output

//   // GPT-3.5 Turbo pricing (as of March 2024)
//   static const double gpt35TurboInputPricePer1kTokens =
//       0.0005; // $0.0005 per 1K tokens for input
//   static const double gpt35TurboOutputPricePer1kTokens =
//       0.0015; // $0.0015 per 1K tokens for output

//   ChatGPTService({required this.apiKey});

//   Future<String> classifyClothingItem(String base64Image) async {
//     try {
//       final response = await http.post(
//         Uri.parse('https://api.openai.com/v1/chat/completions'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $apiKey',
//         },
//         body: jsonEncode({
//           'model': 'gpt-4-turbo',
//           'messages': [
//             {
//               'role': 'user',
//               'content': [
//                 {
//                   'type': 'text',
//                   'text': '''
// Bu kıyafetin detaylı analizini yap. Yanıtı şu formatta ver:

// Kategori: [kategori]
// Renk: [renk]
// Kumaş: [kumaş]
// Mevsim: [yaz/kış/geçiş]
// Tarz: [klasik/casual/sportif]
// Detaylar: [kıyafetin öne çıkan özellikleri]
// '''
//                 },
//                 {
//                   'type': 'image_url',
//                   'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
//                 }
//               ]
//             }
//           ],
//           'max_tokens': 500,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final usage = data['usage'];
//         final promptTokens = usage['prompt_tokens'];
//         final completionTokens = usage['completion_tokens'];

//         // Calculate cost for vision model
//         final cost = (promptTokens *
//                 gpt4TurboVisionInputPricePer1kTokens /
//                 1000) +
//             (completionTokens * gpt4TurboVisionOutputPricePer1kTokens / 1000);

//         // Track usage (Firestore)
//         // final userId = auth.currentUserId;
//         // if (userId != null) { ... }

//         return utf8.decode(data['choices'][0]['message']['content'].codeUnits);
//       } else {
//         throw Exception(
//             'ChatGPT API error: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print('ChatGPT error: $e');
//       rethrow;
//     }
//   }

//   Future<Map<String, dynamic>> generateOutfitSuggestions(
//       List<ClothingItem> items) async {
//     try {
//       print('=== DEBUG: Starting outfit generation ===');
//       print('Total items in wardrobe: ${items.length}');

//       // Format clothing items for the prompt - only send IDs and categories
//       final clothingDescriptions = items.map((item) {
//         return '''ID: ${item.id}
// Kategori: ${item.category}''';
//       }).join('\n\n');

//       print('=== DEBUG: Items being sent to ChatGPT ===');
//       print(clothingDescriptions);

//       final requestBody = {
//         'model': 'gpt-3.5-turbo',
//         'messages': [
//           {
//             'role': 'system',
//             'content':
//                 '''Sen bir stilistsin. Kullanıcının dolabındaki kıyafetleri kullanarak uyumlu kombinler öner. 
// Her kombin için tam olarak aşağıdaki formatta yanıt ver:

// KOMBİN 1:
// ID: [kıyafet-id-1]
// ID: [kıyafet-id-2]
// [Bu kombin neden uyumlu, hangi durumlar için uygun]

// KOMBİN 2:
// ID: [kıyafet-id-3]
// ID: [kıyafet-id-4]
// [Bu kombin neden uyumlu, hangi durumlar için uygun]

// KOMBİN 3:
// ID: [kıyafet-id-5]
// ID: [kıyafet-id-6]
// [Bu kombin neden uyumlu, hangi durumlar için uygun]

// Önemli: 
// 1. Her ID'yi tam olarak verilen formatta kullan: "ID: [id]"
// 2. Her kombin için en az 2 kıyafet seç
// 3. Sadece verilen ID'leri kullan
// 4. ID'leri değiştirmeden, tam olarak verildiği gibi kullan''',
//           },
//           {
//             'role': 'user',
//             'content': '''Dolabımdaki kıyafetler:

// $clothingDescriptions

// Yukarıdaki kıyafetlerle 3 farklı kombin önerisi yap.''',
//           }
//         ],
//         'temperature': 0.7,
//         'max_tokens': 1000,
//       };

//       print('=== DEBUG: Sending request to ChatGPT ===');
//       final response = await http.post(
//         Uri.parse('https://api.openai.com/v1/chat/completions'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $apiKey',
//         },
//         body: jsonEncode(requestBody),
//       );

//       print('=== DEBUG: Response Status Code: ${response.statusCode} ===');

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final content =
//             utf8.decode(data['choices'][0]['message']['content'].codeUnits);

//         print('=== DEBUG: ChatGPT Response ===');
//         print(content);

//         // Validate that the response contains IDs that exist in our wardrobe
//         final responseIds = RegExp(r'ID: ([^\n]+)')
//             .allMatches(content)
//             .map((m) => m.group(1)?.trim())
//             .where((id) => id != null)
//             .toList();

//         print('=== DEBUG: Extracted IDs from response ===');
//         print('Found IDs: $responseIds');

//         final validIds = items.map((item) => item.id).toList();
//         print('Valid IDs in wardrobe: $validIds');

//         final invalidIds =
//             responseIds.where((id) => !validIds.contains(id)).toList();
//         if (invalidIds.isNotEmpty) {
//           print('=== WARNING: Invalid IDs in response ===');
//           print('Invalid IDs: $invalidIds');
//         }

//         final usage = data['usage'];
//         final promptTokens = usage['prompt_tokens'];
//         final completionTokens = usage['completion_tokens'];

//         // Calculate cost
//         final cost = (promptTokens * gpt35TurboInputPricePer1kTokens / 1000) +
//             (completionTokens * gpt35TurboOutputPricePer1kTokens / 1000);

//         // Track usage (Firestore)
//         // final userId = auth.currentUserId;
//         // if (userId != null) { ... }

//         return {
//           'suggestions': content,
//           'usage': {
//             'promptTokens': promptTokens,
//             'completionTokens': completionTokens,
//             'cost': cost,
//           }
//         };
//       } else {
//         print('=== DEBUG: Error Response ===');
//         print(response.body);
//         throw Exception(
//             'ChatGPT API error: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print('=== DEBUG: Exception ===');
//       print(e);
//       rethrow;
//     }
//   }
// }
