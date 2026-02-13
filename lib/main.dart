import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'providers/subscription_provider.dart';
import 'providers/wardrobe_provider.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/firestore_service_base.dart';
import 'services/firebase_storage_service.dart';
import 'services/cloud_functions_service.dart';
import 'services/mock/mock_firebase_auth_service.dart';
import 'services/mock/mock_firestore_service.dart';
import 'services/mock/mock_firebase_storage_service.dart';
import 'services/mock/mock_cloud_functions_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Set to true to use in-memory mock services (no Firebase). Use for UI testing.
const bool kUseMockBackend = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAuthService>(
          create: (_) => kUseMockBackend
              ? MockFirebaseAuthService()
              : FirebaseAuthService(),
        ),
        Provider<FirestoreServiceBase>(
          create: (_) =>
              kUseMockBackend ? MockFirestoreService() : FirestoreService(),
        ),
        Provider<FirebaseStorageService>(
          create: (_) => kUseMockBackend
              ? MockFirebaseStorageService()
              : FirebaseStorageService(),
        ),
        Provider<CloudFunctionsService>(
          create: (_) => kUseMockBackend
              ? MockCloudFunctionsService()
              : CloudFunctionsService(),
        ),
        ChangeNotifierProvider<WardrobeProvider>(
          create: (context) => WardrobeProvider(
            context.read<FirestoreServiceBase>(),
            context.read<FirebaseStorageService>(),
            context.read<CloudFunctionsService>(),
          ),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (context) => SubscriptionProvider(
            context.read<FirebaseAuthService>(),
            context.read<FirestoreServiceBase>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Vestiyer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreenWrapper(),
      ),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (kUseMockBackend) {
      return ValueListenableBuilder<bool>(
        valueListenable: mockSignedInNotifier,
        builder: (_, signedIn, __) {
          return signedIn ? const _AuthenticatedHome() : const LoginScreen();
        },
      );
    }
    final authService = context.read<FirebaseAuthService>();
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;
        if (user != null) {
          return const _AuthenticatedHome();
        }
        return const LoginScreen();
      },
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome();

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final auth = context.read<FirebaseAuthService>();
    final uid = auth.currentUserId;
    if (uid == null) return;
    final firestore = context.read<FirestoreServiceBase>();
    final profile = await firestore.getUserProfile(uid);
    if (!mounted) return;
    context.read<WardrobeProvider>().setCurrentUserId(uid);
    context.read<SubscriptionProvider>().setCurrentUser(profile);
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }
    return const HomeScreen();
  }
}
