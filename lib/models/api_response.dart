import 'user.dart';
import 'combination.dart';

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

  static int _safeInt(dynamic v) =>
      (v is int) ? v : (v is num) ? v.toInt() : 0;

  factory GeneratedCombinationData.fromJson(Map<String, dynamic> json) =>
      GeneratedCombinationData(
        combinations: List<Map<String, dynamic>>.from(json['combinations'] ?? []),
        savedCombinations: List<Combination>.from((json['savedCombinations'] as List<dynamic>?)
                ?.map((item) => Combination.fromJson(Map<String, dynamic>.from(item as Map))) ??
            []),
        totalItems: _safeInt(json['totalItems']),
        usedItems: _safeInt(json['usedItems']),
        diversityScore: _safeInt(json['diversityScore']),
      );
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
