import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../firebase_options.dart';
import '../../../services/hive_cache_service.dart';
import '../../../services/revenuecat_init.dart';

/// Set to true to use in-memory mock services (no Firebase).
const bool kUseMockBackend = false;

/// Application initialization sequence.
class ApplicationInitialize {
  Future<HiveCacheService?> make() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    await configureRevenueCat();

    HiveCacheService? hiveCache;
    if (!kUseMockBackend) {
      await Hive.initFlutter();
      hiveCache = HiveCacheService();
      await hiveCache.init();
    }
    return hiveCache;
  }
}
