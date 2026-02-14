import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/product/init/application_initialize.dart';

/// True only after [configureRevenueCat] successfully called [Purchases.configure].
/// If false, [revenueCatLogIn] must not call any Purchases API (native SDK fatals otherwise).
bool _isRevenueCatConfigured = false;

/// Configures RevenueCat on iOS/Android. No-op if API keys are missing.
Future<void> configureRevenueCat() async {
  if (kUseMockBackend) return;

  final String? apiKey;
  if (Platform.isIOS) {
    apiKey = dotenv.env['REVENUECAT_APPLE_API_KEY']?.trim();
  } else if (Platform.isAndroid) {
    apiKey = dotenv.env['REVENUECAT_GOOGLE_API_KEY']?.trim();
  } else {
    return;
  }

  if (apiKey == null || apiKey.isEmpty) return;

  if (kDebugMode) {
    await Purchases.setLogLevel(LogLevel.debug);
  }

  final configuration = PurchasesConfiguration(apiKey);
  await Purchases.configure(configuration);
  _isRevenueCatConfigured = true;
}

/// True if [configureRevenueCat] successfully ran (API key was present and [Purchases.configure] was called).
bool get isRevenueCatConfigured => _isRevenueCatConfigured;

/// Logs in the given user ID to RevenueCat (e.g. Firebase UID). Call after auth.
/// No-op if RevenueCat was never configured (e.g. missing API key); calling Purchases
/// before configure causes a fatal error on native side.
Future<void> revenueCatLogIn(String userId) async {
  if (kUseMockBackend || !_isRevenueCatConfigured) return;
  try {
    await Purchases.logIn(userId);
  } catch (_) {
    // Network error etc.; ignore
  }
}
