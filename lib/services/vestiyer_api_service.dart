import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/clothing.dart';
import '../models/combination.dart';
import '../models/api_response.dart';

class VestiyerApiService {
  // Production URL for live app
  static const String baseUrl = 'http://vestiyerapp.com';

  // Development URL - uncomment for local testing
  // static const String baseUrl = 'http://localhost:3000';
  String? _token;

  void setToken(String token) => _token = token;
  String? get token => _token;

  // Authentication
  Future<AuthResponse> register(
      String email, String password, String firstName, String lastName) async {
    final requestBody = {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(requestBody),
      );

      debugPrint('REGISTER API Response: ${response.body}');

      final authResponse = AuthResponse.fromJson(json.decode(response.body));

      if (authResponse.success && authResponse.data?.token != null) {
        setToken(authResponse.data!.token);
        await _saveToken(authResponse.data!.token);
      }

      return authResponse;
    } catch (e) {
      debugPrint('REGISTER API Error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    final requestBody = {'email': email, 'password': password};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(requestBody),
      );

      debugPrint('LOGIN API Response: ${response.body}');

      final authResponse = AuthResponse.fromJson(json.decode(response.body));

      if (authResponse.success && authResponse.data?.token != null) {
        setToken(authResponse.data!.token);
        await _saveToken(authResponse.data!.token);
      }

      return authResponse;
    } catch (e) {
      debugPrint('LOGIN API Error: $e');
      rethrow;
    }
  }

  Future<User?> getProfile() async {
    if (_token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('GET PROFILE API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['data']['user']);
      }
      return null;
    } catch (e) {
      debugPrint('GET PROFILE API Error: $e');
      return null;
    }
  }

  // Clothing - Multipart Form Data ile fotoğraf upload ve analiz
  Future<Clothing?> analyzeAndAddClothing(File imageFile, String userId,
      {String? title}) async {
    try {
      debugPrint('Kıyafet analizi başladı: ${imageFile.path}');

      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Resim dosyası bulunamadı');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/clothing/analyze-and-add'),
      );

      // UserId ekleme (API'nizde userId body'den alınıyor)
      request.fields['userId'] = userId;
      if (title != null) {
        request.fields['title'] = title;
      }

      // Image dosyası ekleme (API'nizde 'image' field name'i bekleniyor)
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // API'nizde bu field name kullanılıyor
          imageFile.path,
        ),
      );

      // Gönderme
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Response: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        if (data['success'] == true && data['data'] != null) {
          return Clothing.fromJson(data['data']);
        } else {
          debugPrint('API Error: ${data['message']}');
          return null;
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ANALYZE AND ADD CLOTHING API Error: $e');
      return null;
    }
  }

  Future<List<Clothing>> getAllClothing(
    String userId, {
    String? season,
    String? category,
    String? style,
  }) async {
    String url = '$baseUrl/api/clothing/$userId';

    List<String> queryParams = [];
    if (season != null && season != 'all') {
      queryParams.add('season=$season');
    }
    if (category != null && category != 'all') {
      queryParams.add('category=$category');
    }
    if (style != null && style != 'all') {
      queryParams.add('style=$style');
    }

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      });

      debugPrint('GET ALL CLOTHING API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Clothing>.from(
              data['data'].map((item) => Clothing.fromJson(item)));
        }
      }
      return [];
    } catch (e) {
      debugPrint('GET ALL CLOTHING API Error: $e');
      return [];
    }
  }

  Future<List<Clothing>> getClothingBySeason(
      String userId, String season) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clothing/$userId/season?season=$season'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('GET CLOTHING BY SEASON API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Clothing>.from(
              data['data'].map((item) => Clothing.fromJson(item)));
        }
      }
      return [];
    } catch (e) {
      debugPrint('GET CLOTHING BY SEASON API Error: $e');
      return [];
    }
  }

  Future<List<Clothing>> getCurrentSeasonClothing(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clothing/$userId/current-season'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('GET CURRENT SEASON CLOTHING API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Clothing>.from(
              data['data'].map((item) => Clothing.fromJson(item)));
        }
      }
      return [];
    } catch (e) {
      debugPrint('GET CURRENT SEASON CLOTHING API Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSeasonStatistics(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clothing/$userId/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('GET SEASON STATISTICS API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'currentSeason': data['currentSeason'],
            'statistics': data['statistics'],
          };
        }
      }
      return {};
    } catch (e) {
      debugPrint('GET SEASON STATISTICS API Error: $e');
      return {};
    }
  }

  // Alias for getSeasonStatistics
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    return getSeasonStatistics(userId);
  }

  // Update clothing item
  Future<Clothing?> updateClothing(
      String clothingId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/clothing/$clothingId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(updates),
      );

      debugPrint('UPDATE CLOTHING API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Clothing.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('UPDATE CLOTHING API Error: $e');
      return null;
    }
  }

  // Delete clothing item
  Future<bool> deleteClothing(String clothingId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/clothing/$clothingId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('DELETE CLOTHING API Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DELETE CLOTHING API Error: $e');
      return false;
    }
  }

  // Mark combination as favorite
  Future<bool> markCombinationAsFavorite(
      String combinationId, bool isFavorite) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/combinations/$combinationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode({'isFavorite': isFavorite}),
      );

      debugPrint('MARK COMBINATION AS FAVORITE API Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('MARK COMBINATION AS FAVORITE API Error: $e');
      return false;
    }
  }

  // Update combination
  Future<Combination?> updateCombination(
      String combinationId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/combinations/$combinationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(updates),
      );

      debugPrint('UPDATE COMBINATION API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Combination.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('UPDATE COMBINATION API Error: $e');
      return null;
    }
  }

  // Combinations
  Future<GenerateCombinationResponse> generateCombinations(String userId,
      {bool forceGenerate = false, String? occasion}) async {
    try {
      final requestBody = {
        'userId': userId,
        'forceGenerate': forceGenerate,
      };

      // Add occasion parameter if provided
      if (occasion != null && occasion.isNotEmpty) {
        requestBody['occasion'] = occasion;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/combinations/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(requestBody),
      );

      debugPrint('GENERATE COMBINATIONS API Response: ${response.body}');

      if (response.statusCode == 200) {
        return GenerateCombinationResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Kombin oluşturma başarısız: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GENERATE COMBINATIONS API Error: $e');
      rethrow;
    }
  }

  Future<List<Combination>> getUserCombinations(
    String userId, {
    int page = 1,
    int limit = 10,
    String? occasion,
    bool? isFavorite,
  }) async {
    String url = '$baseUrl/api/combinations/user/$userId';

    List<String> queryParams = ['page=$page', 'limit=$limit'];
    if (occasion != null) queryParams.add('occasion=$occasion');
    if (isFavorite != null) queryParams.add('isFavorite=$isFavorite');

    url += '?${queryParams.join('&')}';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      });

      debugPrint('GET USER COMBINATIONS API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Combination>.from(data['data']['combinations']
            .map((item) => Combination.fromJson(item)));
      }
      return [];
    } catch (e) {
      debugPrint('GET USER COMBINATIONS API Error: $e');
      return [];
    }
  }

  Future<List<Clothing>> getCombinationClothingDetails(
      List<String> clothingIds, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/combinations/clothing-details'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'clothingIds': clothingIds,
          'userId': userId,
        }),
      );

      debugPrint('GET COMBINATION CLOTHING DETAILS API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Clothing>.from(data['data']['clothingItems']
            .map((item) => Clothing.fromJson(item)));
      }
      return [];
    } catch (e) {
      debugPrint('GET COMBINATION CLOTHING DETAILS API Error: $e');
      return [];
    }
  }

  // Helper Methods
  String getImageUrl(String imagePath) => '$baseUrl$imagePath';

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> loadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _token = token;
    }
    return token;
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Error handling helper
  Future<T> handleApiResponse<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await request();
      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parser(data);
      } else {
        throw ApiException(
          data['message'] ?? 'Unknown error occurred',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }
}
