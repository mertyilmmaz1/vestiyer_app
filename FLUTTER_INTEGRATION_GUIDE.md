# 📱 Vestiyer Backend - Flutter Integration Guide

Bu doküman Vestiyer backend API'sini Flutter'da kullanmak için gerekli temel bilgileri içerir.

## 🌐 Base Configuration

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';
  static const String authEndpoint = '/api/auth';
  static const String clothingEndpoint = '/api/clothing';
  static const String combinationEndpoint = '/api/combinations';
}
```

## 🔗 HTTP Headers

```dart
Map<String, String> getHeaders({String? token}) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  
  return headers;
}
```

---

## 📊 Data Models

### User Model
```dart
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final bool isPremium;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.createdAt,
    this.lastLogin,
    required this.isActive,
    required this.isPremium,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['_id'],
    email: json['email'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    profileImage: json['profileImage'],
    createdAt: DateTime.parse(json['createdAt']),
    lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    isActive: json['isActive'] ?? true,
    isPremium: json['isPremium'] ?? false,
  );
}
```

### Clothing Model
```dart
class Clothing {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String imageUrl;
  final String imagePath;
  final AdvancedAnalysis? advancedAnalysis;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Clothing({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.imagePath,
    this.advancedAnalysis,
    required this.tags,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Clothing.fromJson(Map<String, dynamic> json) => Clothing(
    id: json['_id'],
    userId: json['userId'],
    title: json['title'],
    category: json['category'],
    imageUrl: json['imageUrl'],
    imagePath: json['imagePath'],
    advancedAnalysis: json['advancedAnalysis'] != null 
        ? AdvancedAnalysis.fromJson(json['advancedAnalysis']) 
        : null,
    tags: List<String>.from(json['tags'] ?? []),
    isFavorite: json['isFavorite'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

class AdvancedAnalysis {
  final String? mainGroup;
  final String? category;
  final String? color;
  final String? material;
  final String? style;
  final String season;
  final String? details;
  final double? confidence;

  AdvancedAnalysis({
    this.mainGroup,
    this.category,
    this.color,
    this.material,
    this.style,
    required this.season,
    this.details,
    this.confidence,
  });

  factory AdvancedAnalysis.fromJson(Map<String, dynamic> json) => AdvancedAnalysis(
    mainGroup: json['mainGroup'],
    category: json['category'],
    color: json['color'],
    material: json['material'],
    style: json['style'],
    season: json['season'],
    details: json['details'],
    confidence: json['confidence']?.toDouble(),
  );
}
```

### Combination Model
```dart
class Combination {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String occasion;
  final String season;
  final List<CombinationItem> clothingItems;
  final bool isAIGenerated;
  final bool isFavorite;
  final int? rating;
  final int timesWorn;
  final DateTime? lastWorn;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Combination({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.occasion,
    required this.season,
    required this.clothingItems,
    required this.isAIGenerated,
    required this.isFavorite,
    this.rating,
    required this.timesWorn,
    this.lastWorn,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Combination.fromJson(Map<String, dynamic> json) => Combination(
    id: json['_id'],
    userId: json['userId'],
    name: json['name'],
    description: json['description'],
    occasion: json['occasion'],
    season: json['season'],
    clothingItems: List<CombinationItem>.from(
      json['clothingItems'].map((item) => CombinationItem.fromJson(item))
    ),
    isAIGenerated: json['isAIGenerated'] ?? false,
    isFavorite: json['isFavorite'] ?? false,
    rating: json['rating'],
    timesWorn: json['timesWorn'] ?? 0,
    lastWorn: json['lastWorn'] != null ? DateTime.parse(json['lastWorn']) : null,
    tags: List<String>.from(json['tags'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

class CombinationItem {
  final String clothingId;
  final String? category;
  final bool isRequired;
  final Clothing? clothingDetails;

  CombinationItem({
    required this.clothingId,
    this.category,
    required this.isRequired,
    this.clothingDetails,
  });

  factory CombinationItem.fromJson(Map<String, dynamic> json) => CombinationItem(
    clothingId: json['clothingId'] is String ? json['clothingId'] : json['clothingId']['_id'],
    category: json['category'],
    isRequired: json['isRequired'] ?? true,
    clothingDetails: json['clothingId'] is Map<String, dynamic> 
        ? Clothing.fromJson(json['clothingId']) 
        : null,
  );
}
```

---

## 🔌 API Service Class

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class VestiyerApiService {
  static const String baseUrl = 'http://localhost:3000';
  String? _token;
  
  void setToken(String token) => _token = token;
  String? get token => _token;
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Authentication
  Future<AuthResponse> register(String email, String password, String firstName, String lastName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );
    
    final authResponse = AuthResponse.fromJson(json.decode(response.body));
    if (authResponse.success && authResponse.data?.token != null) {
      setToken(authResponse.data!.token);
    }
    
    return authResponse;
  }

  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: json.encode({'email': email, 'password': password}),
    );
    
    final authResponse = AuthResponse.fromJson(json.decode(response.body));
    if (authResponse.success && authResponse.data?.token != null) {
      setToken(authResponse.data!.token);
    }
    
    return authResponse;
  }

  Future<User?> getProfile() async {
    if (_token == null) return null;
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data['data']['user']);
    }
    return null;
  }

  // Clothing
  Future<Clothing?> analyzeAndAddClothing(File imageFile, {String? title}) async {
    final base64Image = await _imageToBase64(imageFile);
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/clothing/analyze-and-add'),
      headers: _headers,
      body: json.encode({
        'base64Image': base64Image,
        if (title != null) 'title': title,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Clothing.fromJson(data['data']['clothing']);
    }
    return null;
  }

  Future<List<Clothing>> getAllClothing(String userId, {
    String? season,
    String? category,
    String? style,
  }) async {
    String url = '$baseUrl/api/clothing/$userId';
    
    List<String> queryParams = [];
    if (season != null) queryParams.add('season=$season');
    if (category != null) queryParams.add('category=$category');
    if (style != null) queryParams.add('style=$style');
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Clothing>.from(
        data['data'].map((item) => Clothing.fromJson(item))
      );
    }
    return [];
  }

  // Combinations
  Future<GenerateCombinationResponse> generateCombinations(String userId, {bool forceGenerate = false}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/combinations/generate'),
      headers: _headers,
      body: json.encode({
        'userId': userId,
        'forceGenerate': forceGenerate,
      }),
    );

    return GenerateCombinationResponse.fromJson(json.decode(response.body));
  }

  Future<List<Combination>> getUserCombinations(String userId, {
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

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Combination>.from(
        data['data']['combinations'].map((item) => Combination.fromJson(item))
      );
    }
    return [];
  }

  // Helper Methods
  Future<String> _imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64String = base64Encode(bytes);
    final mimeType = imageFile.path.endsWith('.png') ? 'png' : 'jpeg';
    return 'data:image/$mimeType;base64,$base64String';
  }

  String getImageUrl(String imagePath) => '$baseUrl$imagePath';
  
  void logout() => _token = null;
}
```

## 📋 Response Models

### Auth Response
```dart
class AuthResponse {
  final bool success;
  final String message;
  final UserData? data;

  AuthResponse({required this.success, required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    success: json['success'],
    message: json['message'],
    data: json['data'] != null ? UserData.fromJson(json['data']) : null,
  );
}

class UserData {
  final User user;
  final String token;

  UserData({required this.user, required this.token});

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    user: User.fromJson(json['user']),
    token: json['token'],
  );
}
```

### Generation Response
```dart
class GenerateCombinationResponse {
  final bool success;
  final String message;
  final GeneratedCombinationData? data;

  GenerateCombinationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory GenerateCombinationResponse.fromJson(Map<String, dynamic> json) => 
      GenerateCombinationResponse(
        success: json['success'],
        message: json['message'],
        data: json['data'] != null 
            ? GeneratedCombinationData.fromJson(json['data']) 
            : null,
      );
}

class GeneratedCombinationData {
  final List<Map<String, dynamic>> combinations;
  final List<Combination> savedCombinations;
  final int totalItems;
  final int usedItems;
  final int diversityScore;

  GeneratedCombinationData({
    required this.combinations,
    required this.savedCombinations,
    required this.totalItems,
    required this.usedItems,
    required this.diversityScore,
  });

  factory GeneratedCombinationData.fromJson(Map<String, dynamic> json) => 
      GeneratedCombinationData(
        combinations: List<Map<String, dynamic>>.from(json['combinations']),
        savedCombinations: List<Combination>.from(
          json['savedCombinations'].map((item) => Combination.fromJson(item))
        ),
        totalItems: json['totalItems'],
        usedItems: json['usedItems'],
        diversityScore: json['diversityScore'],
      );
}
```

---

## 📦 Required Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  image_picker: ^1.0.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 🔧 Error Handling

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

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
```

---

## 🎯 Quick Setup Checklist

1. ✅ Backend çalışıyor mu? (`http://localhost:3000`)
2. ✅ MongoDB bağlantısı aktif mi?
3. ✅ OpenAI API anahtarı ayarlandı mı?
4. ✅ Flutter dependencies yüklendi mi?
5. ✅ Kamera izinleri ayarlandı mı?
6. ✅ Internet izinleri ayarlandı mı?

Bu doküman ile backend API'nizi Flutter uygulamanızda entegre edebilirsiniz. 