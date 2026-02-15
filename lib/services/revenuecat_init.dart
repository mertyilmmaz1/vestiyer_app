// import 'revenuecat_init_stub.dart'
//    if (dart.library.io) 'revenuecat_init_io.dart' as rc;

/// Configures RevenueCat when on iOS/Android with valid API keys. No-op on web/desktop or when keys are missing.
Future<void> configureRevenueCat() async {} // Fixed as no-op

/// Logs in the user to RevenueCat (e.g. Firebase UID). No-op on web or when not configured.
Future<void> revenueCatLogIn(String userId) async {} // Fixed as no-op

/// True only if RevenueCat was configured (API key set and configure succeeded). Use to avoid calling any Purchases API when not set up.
bool get isRevenueCatConfigured => false; // Fixed as false
