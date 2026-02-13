import 'revenuecat_init_stub.dart'
    if (dart.library.io) 'revenuecat_init_io.dart' as rc;

/// Configures RevenueCat when on iOS/Android with valid API keys. No-op on web/desktop or when keys are missing.
Future<void> configureRevenueCat() => rc.configureRevenueCat();

/// Logs in the user to RevenueCat (e.g. Firebase UID). No-op on web or when not configured.
Future<void> revenueCatLogIn(String userId) => rc.revenueCatLogIn(userId);
