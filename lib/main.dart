import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/product/init/application_initialize.dart';
import 'core/product/theme/app_colors.dart';
import 'core/product/theme/app_theme.dart';
import 'providers/subscription_provider.dart';
import 'providers/wardrobe_provider.dart';
import 'screens/ai_stylist_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'services/cached_firestore_service.dart';
import 'services/revenuecat_init.dart';
import 'services/cloud_functions_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_storage_service.dart';
import 'services/firestore_service.dart';
import 'services/firestore_service_base.dart';
import 'services/hive_cache_service.dart';
import 'services/mock/mock_cloud_functions_service.dart';
import 'services/mock/mock_firebase_auth_service.dart';
import 'services/mock/mock_firebase_storage_service.dart';
import 'services/mock/mock_firestore_service.dart';

HiveCacheService? _hiveCache;

void main() async {
  _hiveCache = await ApplicationInitialize().make();
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
          create: (_) => kUseMockBackend
              ? MockFirestoreService()
              : CachedFirestoreService(FirestoreService(), _hiveCache!),
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
        Provider<HiveCacheService?>(
          create: (_) => _hiveCache,
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
        theme: AppTheme.darkTheme,
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
    // Kısa gecikme: splash animasyonu için (logo vb. görünsün)
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final authService = context.read<FirebaseAuthService>();
    // Auth state hazır olana kadar bekle (ikinci yükleme ekranını önlemek için)
    final isSignedIn = await _waitForAuthState(authService);
    if (!mounted) return;

    if (isSignedIn) {
      // Giriş yapmışsa profil/abonelik yüklemeyi burada yap ki _AuthenticatedHome tekrar splash göstermesin
      await _initAuthenticatedUser();
      if (!mounted) return;
    }

    if (isSignedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            nextScreen: const AuthWrapper(),
          ),
        ),
      );
    }
  }

  /// Auth state ilk değerini alana kadar bekle (en fazla 3 sn)
  Future<bool> _waitForAuthState(FirebaseAuthService authService) async {
    if (authService.currentUserId != null) return true;
    final completer = Completer<bool>();
    late StreamSubscription sub;
    sub = authService.authStateChanges.listen((user) {
      if (!completer.isCompleted) {
        sub.cancel();
        completer.complete(user != null);
      }
    });
    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        sub.cancel();
        return false;
      },
    );
  }

  /// Giriş yapmış kullanıcı için profil/abonelik yüklemesi (splash sadece bir kez gösterilsin diye)
  Future<void> _initAuthenticatedUser() async {
    final auth = context.read<FirebaseAuthService>();
    final uid = auth.currentUserId;
    if (uid == null) return;
    final firestore = context.read<FirestoreServiceBase>();
    final profile = await firestore.getUserProfile(uid);
    if (!mounted) return;
    context.read<WardrobeProvider>().setCurrentUserId(uid);
    context.read<SubscriptionProvider>().setCurrentUser(profile);
    await revenueCatLogIn(uid);
    if (!mounted) return;
    _AuthenticatedHome.markPreInitialized();
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
        // SplashScreenWrapper zaten auth state'i beklediği için waiting çok kısa olur;
        // yine de beklerken tam splash yerine minimal gösterge kullan (çift splash önlenir)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
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

  static bool _preInitialized = false;

  static void markPreInitialized() {
    _preInitialized = true;
  }

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  bool _initialized = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (_AuthenticatedHome._preInitialized) {
      _initialized = true;
      return;
    }
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
    await revenueCatLogIn(uid);
    if (!mounted) return;
    setState(() => _initialized = true);
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UploadScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: [
          HomeScreen(onSelectTab: (i) => setState(() => _currentIndex = i)),
          const WardrobeScreen(showBackButton: false),
          const AIStylistScreen(),
          const ProfileScreen(showBackButton: false),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          border: Border(
            top: BorderSide(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  isSelected: _currentIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _NavItem(
                  icon: Icons.checkroom_outlined,
                  selectedIcon: Icons.checkroom_rounded,
                  label: 'Dolabım',
                  isSelected: _currentIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: Icons.add_circle_outline,
                  selectedIcon: Icons.add_circle,
                  label: 'Yükle',
                  isSelected: false,
                  onTap: () => _onTabTapped(2),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome,
                  label: 'Kombinler',
                  isSelected: _currentIndex == 3,
                  onTap: () => _onTabTapped(3),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profil',
                  isSelected: _currentIndex == 4,
                  onTap: () => _onTabTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

