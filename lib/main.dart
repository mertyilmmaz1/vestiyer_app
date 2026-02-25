import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'core/product/init/application_initialize.dart';
import 'core/product/navigation/editorial_page_route.dart';
import 'core/product/theme/app_colors.dart';
import 'core/product/theme/app_theme.dart';
import 'core/product/theme/app_typography.dart';
import 'providers/locale_provider.dart';
import 'providers/subscription_provider.dart';

import 'providers/wardrobe_provider.dart';
import 'models/user.dart' as app_user;
import 'screens/ai_stylist_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/style_dna_onboarding_screen.dart';
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
import 'widgets/intro_dialog.dart';

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
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) {
            final provider = LocaleProvider();
            provider.loadSavedLocale();
            return provider;
          },
        ),
        Provider<FirebaseAuthService>(
          create: (_) {
            if (kUseMockBackend) return MockFirebaseAuthService();
            final webClientId =
                dotenv.env['FIREBASE_GOOGLE_WEB_CLIENT_ID']?.trim();
            return FirebaseAuthService(
              googleServerClientId:
                  (webClientId != null && webClientId.isNotEmpty)
                      ? webClientId
                      : null,
            );
          },
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
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Vestiyer',
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreenWrapper(),
          );
        },
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
        EditorialPageRoute(page: const AuthWrapper()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        EditorialPageRoute(
          page: OnboardingScreen(nextScreen: const AuthWrapper()),
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
    try {
      final profile = await firestore
          .getUserProfile(uid)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      context.read<WardrobeProvider>().setCurrentUserId(uid);
      context.read<SubscriptionProvider>().setCurrentUser(profile);
      await revenueCatLogIn(uid);
      if (!mounted) return;
      _AuthenticatedHome.markPreInitialized();
    } catch (e) {
      debugPrint('Error initializing authenticated user: $e');
      // If error or timeout, we still want to show the app,
      // but maybe without pre-initialization.
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class _AuthContent extends StatefulWidget {
  const _AuthContent({required this.uid});

  final String uid;

  @override
  State<_AuthContent> createState() => _AuthContentState();
}

class _AuthContentState extends State<_AuthContent> {
  late Future<app_user.User?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture =
        context.read<FirestoreServiceBase>().getUserProfile(widget.uid);
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture =
          context.read<FirestoreServiceBase>().getUserProfile(widget.uid);
    });
  }

  void _onStyleDNAComplete(app_user.User? updatedUser) {
    if (updatedUser != null && updatedUser.styleProfile?.isCompleted == true) {
      setState(() {
        _profileFuture = Future.value(updatedUser);
      });
    } else {
      _refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<app_user.User?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final profile = snapshot.data;
        if (profile?.styleProfile?.isCompleted != true) {
          return StyleDNAOnboardingScreen(
            userId: widget.uid,
            onComplete: _onStyleDNAComplete,
          );
        }
        return const _AuthenticatedHome();
      },
    );
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
          if (!signedIn) return const LoginScreen();
          return _AuthContent(uid: MockFirebaseAuthService.mockUserId);
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
          return _AuthContent(uid: user.uid);
        }
        return const LoginScreen();
      },
    );
  }
}

/// Public function callable from other screens (e.g. profile_screen logout)
/// to reset the pre-initialized flag so the next user gets fresh initialization.
void resetAuthenticatedHomeState() {
  _AuthenticatedHome.resetPreInitialized();
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome();

  static bool _preInitialized = false;

  static void markPreInitialized() {
    _preInitialized = true;
  }

  /// Reset the pre-initialized flag on logout so the next user gets fresh init.
  static void resetPreInitialized() {
    _preInitialized = false;
  }

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  bool _initialized = false;
  int _currentIndex = 0;

  final _uploadButtonKey = GlobalKey();
  final _aiTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (_AuthenticatedHome._preInitialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        IntroDialog.show(context);
      });
      return;
    }
    _initUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initUser() async {
    final auth = context.read<FirebaseAuthService>();
    final uid = auth.currentUserId;
    if (uid == null) return;
    final firestore = context.read<FirestoreServiceBase>();
    try {
      final profile = await firestore
          .getUserProfile(uid)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      context.read<WardrobeProvider>().setCurrentUserId(uid);
      context.read<SubscriptionProvider>().setCurrentUser(profile);
      await revenueCatLogIn(uid);
    } catch (e) {
      debugPrint('Error in _initUser: $e');
    }

    if (!mounted) return;
    setState(() => _initialized = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) IntroDialog.show(context);
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _openUpload() {
    Navigator.of(context).push(
      EditorialPageRoute(page: const UploadScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }

    final l10n = AppLocalizations.of(context);
    final topTabs = [
      {'label': l10n.navHome, 'index': 0},
      {'label': l10n.navWardrobe, 'index': 1},
      {'label': l10n.navAiStylist, 'index': 2},
      {'label': l10n.navProfile, 'index': 3},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── GLOBAL TOP HEADER (Zara Inspired) ───
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.appTitle,
                      style: AppTypography.display.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 4.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    key: _uploadButtonKey,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () {
                      _openUpload();
                    },
                  ),
                ],
              ),
            ),
            // ─── TOP TAB BAR ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: topTabs.map((tab) {
                    final index = tab['index'] as int;
                    final isSelected = _currentIndex == index;
                    final isAiTab = index == 2;
                    return InkWell(
                      key: isAiTab ? _aiTabKey : null,
                      onTap: () => _onTabTapped(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          tab['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w300,
                            letterSpacing: 1.5,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // ─── PAGE CONTENT ───
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeScreen(
                      onSelectTab: (i) => setState(() => _currentIndex = i)),
                  WardrobeScreen(
                    showBackButton: false,
                    onKombinPressed: () => _onTabTapped(2),
                  ),
                  const AIStylistScreen(),
                  const ProfileScreen(showBackButton: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
