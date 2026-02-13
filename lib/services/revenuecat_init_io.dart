import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/product/init/application_initialize.dart';

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
}

/// Logs in the given user ID to RevenueCat (e.g. Firebase UID). Call after auth.
Future<void> revenueCatLogIn(String userId) async {
  if (kUseMockBackend) return;
  try {
    await Purchases.logIn(userId);
  } catch (_) {
    // SDK may not be configured or network error; ignore
  }
}
