import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/clothing.dart';
import '../models/combination.dart';
import '../models/api_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VestiyerApiService {
  // Production URL for live app
  static const String baseUrl = 'http://vestiyerapp.com';

  String get _segmentServiceUrl =>
      dotenv.env['SEGMENT_SERVICE_URL'] ?? 'http://vestiyerapp.com:8000';
  String? get _segmentApiKey => dotenv.env['SEGMENT_SERVICE_API_KEY'];

  // ── VPS availability cache ──────────────────────────────────────
  bool _vpsAvailable = true;
  DateTime? _lastVpsCheck;
  static const _vpsCacheDuration = Duration(minutes: 5);
  static const _vpsHealthTimeout = Duration(seconds: 5);

  /// Check if VPS is reachable. Caches result for 5 minutes.
  Future<bool> isVpsAvailable({bool forceCheck = false}) async {
    if (!forceCheck &&
        _lastVpsCheck != null &&
        DateTime.now().difference(_lastVpsCheck!) < _vpsCacheDuration) {
      return _vpsAvailable;
    }
    try {
      final response = await http
          .get(Uri.parse('$_segmentServiceUrl/health'))
          .timeout(_vpsHealthTimeout);
      _vpsAvailable = response.statusCode == 200;
    } catch (e) {
      debugPrint('VPS health check failed: $e');
      _vpsAvailable = false;
    }
    _lastVpsCheck = DateTime.now();
    debugPrint('VPS availability: $_vpsAvailable');
    return _vpsAvailable;
  }

  /// Reset VPS cache (e.g. after a failure) so next call re-checks.
  void resetVpsCache() {
    _lastVpsCheck = null;
  }

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

      debugPrint(
          'GET COMBINATION CLOTHING DETAILS API Response: ${response.body}');

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

  /// Segment image via VPS. Returns null if VPS is unavailable, output is
  /// invalid, or processing fails — the caller should fall back to the
  /// original image for Firebase analysis.
  Future<Uint8List?> segmentImage(String imageUrl) async {
    // Quick VPS availability check (cached for 5 min)
    final vpsOk = await isVpsAvailable();
    if (!vpsOk) {
      debugPrint(
          'VPS is unavailable (cached). Skipping segmentation, using original image.');
      return null;
    }

    try {
      debugPrint('Segmenting image via VPS: $_segmentServiceUrl');
      debugPrint('Image URL for segmentation: $imageUrl');
      final response = await http
          .post(
            Uri.parse('$_segmentServiceUrl/segment'),
            headers: {
              'Content-Type': 'application/json',
              if (_segmentApiKey != null) 'X-API-Key': _segmentApiKey!,
            },
            body: json.encode({'imageUrl': imageUrl}),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('Segment Service Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint(
            'Segment Service HTTP Error: ${response.statusCode} - ${response.body}');
        _markVpsDown();
        return null;
      }

      // ── 1. Parse JSON response ─────────────────────────────────────
      final dynamic data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        debugPrint('Segment Service: JSON parse error: $e');
        _markVpsDown();
        return null;
      }

      if (data['success'] != true || data['imageBase64'] == null) {
        debugPrint('Segment Service: unexpected response fields: ${data.keys}');
        _markVpsDown();
        return null;
      }

      // ── 2. Decode base64 ───────────────────────────────────────────
      String base64String = data['imageBase64'] as String;
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      if (base64String.isEmpty) {
        debugPrint('Segment Service: empty base64 string');
        _markVpsDown();
        return null;
      }

      final Uint8List imageBytes;
      try {
        imageBytes = base64Decode(base64String);
      } catch (e) {
        debugPrint('Segment Service: base64 decode error: $e');
        _markVpsDown();
        return null;
      }

      // ── 3. Validate image data ─────────────────────────────────────
      // Minimum size check: a valid segmented PNG should be > 1 KB
      if (imageBytes.length < 1024) {
        debugPrint(
            'Segment Service: image too small (${imageBytes.length} bytes), likely corrupt');
        return null; // Don't mark VPS down — it replied, image was just bad
      }

      // PNG header check: first 8 bytes = 137 80 78 71 13 10 26 10
      const pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];
      if (imageBytes.length >= 8) {
        bool validPng = true;
        for (int i = 0; i < 8; i++) {
          if (imageBytes[i] != pngHeader[i]) {
            validPng = false;
            break;
          }
        }
        if (!validPng) {
          debugPrint(
              'Segment Service: invalid PNG header, data may be corrupt');
          return null;
        }
      }

      debugPrint(
          'Segment Service: valid PNG received (${imageBytes.length} bytes)');
      return imageBytes;
    } on TimeoutException {
      debugPrint('Segment Service: request timed out (60s)');
      _markVpsDown();
      return null;
    } catch (e) {
      debugPrint('Segment Service Exception: $e');
      _markVpsDown();
      return null;
    }
  }

  /// Mark VPS as unavailable for the cache duration.
  void _markVpsDown() {
    _vpsAvailable = false;
    _lastVpsCheck = DateTime.now();
    debugPrint(
        'VPS marked as down — will skip for ${_vpsCacheDuration.inMinutes} min');
  }
}
