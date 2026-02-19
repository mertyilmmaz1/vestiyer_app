import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/product/init/application_initialize.dart';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service_base.dart';
import '../services/revenuecat_init.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement identifier (must match dashboard).
const String _kPremiumEntitlementId = 'premium';

enum SubscriptionType {
  monthly,
  yearly,
  none,
}

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._authService, this._firestore) {
    _initialize();
  }

  final FirebaseAuthService _authService;
  final FirestoreServiceBase _firestore;

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isPremiumFromRevenueCat = false;
  DateTime? _subscriptionEndDate;
  SubscriptionType _subscriptionType = SubscriptionType.none;
  int _freeItemsUsed = 0;
  final int _freeItemLimit = 10;
  static const int freeLimit = 10;
  User? _currentUser;
  DateTime? _lastPaywallShownAt;
  static const String _keyLastPaywallShownAt = 'last_paywall_shown_at';
  static const String _keyLastFreeCombinationDate =
      'last_free_combination_date';

  /// Günlük 1 ücretsiz kombin limiti için son kullanım tarihi.
  DateTime? _lastFreeCombinationDate;

  /// Debug-only: override premium for testing (e.g. from dev menu).
  bool _debugPremiumOverride = false;

  bool get isLoading => _isLoading;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;
  SubscriptionType get subscriptionType => _subscriptionType;
  int get freeItemsUsed => _freeItemsUsed;
  int get freeItemLimit => _freeItemLimit;
  int get remainingFreeItems => freeLimit - _freeItemsUsed;
  bool get hasReachedFreeLimit => _freeItemsUsed >= freeLimit;
  User? get currentUser => _currentUser;

  /// Test premium: only in debug and when .env PREMIUM_TEST_MODE=true or dev override.
  bool get _isTestPremiumEnabled =>
      kDebugMode &&
      (dotenv.env['PREMIUM_TEST_MODE']?.toLowerCase() == 'true' ||
          _debugPremiumOverride);

  static const String _keyIsTutorialSampleUsed = 'is_tutorial_sample_used';

  /// Tutorial kapsamında bir defalık premium özelliği (AI analiz) deneme hakkı kullanıldı mı?
  bool _isTutorialSampleUsed = false;

  bool get isTutorialSampleUsed => _isTutorialSampleUsed;

  /// Premium status: test override OR RevenueCat entitlement OR database override.
  bool get isPremium =>
      _isTestPremiumEnabled ||
      _isPremiumFromRevenueCat ||
      (_currentUser?.isPremium ?? false);

  Future<void> useTutorialSample() async {
    _isTutorialSampleUsed = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsTutorialSampleUsed, true);
    } catch (e) {
      debugPrint('Error persisting tutorial sample usage: $e');
    }
  }

  /// Free kullanıcı için bugün ücretsiz kombin hakkı kaldı mı?
  bool get hasDailyFreeCombinationLeft {
    if (isPremium) return true;
    if (_lastFreeCombinationDate == null) return true;
    final now = DateTime.now();
    return _lastFreeCombinationDate!.year != now.year ||
        _lastFreeCombinationDate!.month != now.month ||
        _lastFreeCombinationDate!.day != now.day;
  }

  /// Günlük ücretsiz kombin kullanıldı - kaydet.
  Future<void> useDailyFreeCombination() async {
    if (isPremium) return;
    _lastFreeCombinationDate = DateTime.now();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyLastFreeCombinationDate,
        _lastFreeCombinationDate!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error persisting last free combination date: $e');
    }
  }

  /// Son paywall'dan bu yana yeterli süre (24 saat) geçti mi? Rate-limit için.
  bool get canShowPaywallAgain {
    if (_lastPaywallShownAt == null) return true;
    return DateTime.now().difference(_lastPaywallShownAt!).inHours >= 24;
  }

  /// Kıyafet ekleme izni için sadece [canAddClothing] kullanın.
  /// Özellik kilidi (AI Stilist, Gardırop analizi) için [isPremium] kullanın.

  void setCurrentUser(User? user) {
    _currentUser = user;
    if (user != null) {
      refreshSubscriptionStatus();
    } else {
      _resetSubscriptionData();
    }
  }

  /// Debug-only: toggle premium for testing without purchasing.
  void setDebugPremiumOverride(bool value) {
    if (!kDebugMode) return;
    _debugPremiumOverride = value;
    notifyListeners();
  }

  void _resetSubscriptionData() {
    _isPremiumFromRevenueCat = false;
    _freeItemsUsed = 0;
    _subscriptionEndDate = null;
    _subscriptionType = SubscriptionType.none;
    _lastFreeCombinationDate = null;
    _isTutorialSampleUsed = false;
    notifyListeners();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    try {
      _isLoading = true;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_keyLastPaywallShownAt);
      if (stored != null) {
        _lastPaywallShownAt = DateTime.tryParse(stored);
      }
      final comboStored = prefs.getString(_keyLastFreeCombinationDate);
      if (comboStored != null) {
        _lastFreeCombinationDate = DateTime.tryParse(comboStored);
      }
      _isTutorialSampleUsed = prefs.getBool(_keyIsTutorialSampleUsed) ?? false;
      final uid = _authService.currentUserId;
      if (uid != null) {
        _currentUser = await _firestore.getUserProfile(uid);
        if (_currentUser != null) await refreshSubscriptionStatus();
      }
      if (!kUseMockBackend && isRevenueCatConfigured) {
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _applyCustomerInfo(customerInfo);
    notifyListeners();
  }

  void _applyCustomerInfo(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[_kPremiumEntitlementId];
    if (entitlement != null && entitlement.isActive) {
      _isPremiumFromRevenueCat = true;
      final exp = entitlement.expirationDate;
      _subscriptionEndDate =
          exp == null ? null : DateTime.tryParse(exp.toString());
      _subscriptionType = _inferSubscriptionType(entitlement);
    } else {
      _isPremiumFromRevenueCat = false;
      _subscriptionEndDate = null;
      _subscriptionType = SubscriptionType.none;
    }
  }

  SubscriptionType _inferSubscriptionType(EntitlementInfo e) {
    final id = e.identifier.toLowerCase();
    if (id.contains('annual') || id.contains('yearly')) {
      return SubscriptionType.yearly;
    }
    if (id.contains('monthly') || id.contains('month')) {
      return SubscriptionType.monthly;
    }
    return SubscriptionType.none;
  }

  @override
  void dispose() {
    if (!kUseMockBackend && isRevenueCatConfigured) {
      try {
        Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> refreshSubscriptionStatus() async {
    if (_currentUser == null) {
      _resetSubscriptionData();
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      if (!kUseMockBackend && isRevenueCatConfigured) {
        try {
          final customerInfo = await Purchases.getCustomerInfo();
          _applyCustomerInfo(customerInfo);
        } catch (e) {
          debugPrint('RevenueCat getCustomerInfo: $e');
          _isPremiumFromRevenueCat = false;
          _subscriptionEndDate = null;
          _subscriptionType = SubscriptionType.none;
        }
      }
      final user = await _firestore.getUserProfile(_currentUser!.id);
      if (user != null) _currentUser = user;
      await _updateFreeItemsUsed();
    } catch (e) {
      debugPrint('Error refreshing subscription status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateFreeItemsUsed() async {
    if (_currentUser == null) return;
    try {
      final items = await _firestore.getAllClothing(_currentUser!.id);
      _freeItemsUsed = items.length;
    } catch (e) {
      _freeItemsUsed = 0;
    }
  }

  bool canAddClothing() {
    if (isPremium) return true;
    return _freeItemsUsed < freeLimit;
  }

  void incrementFreeItemsUsed() {
    if (!isPremium) {
      _freeItemsUsed++;
      notifyListeners();
    }
  }

  /// Purchases the given [Package] via RevenueCat. Returns true on success.
  Future<bool> purchasePackage(Package package) async {
    if (kUseMockBackend || !isRevenueCatConfigured) return false;
    try {
      _isLoading = true;
      notifyListeners();
      final customerInfo = await Purchases.purchasePackage(package);
      _applyCustomerInfo(customerInfo);
      return true;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Purchase cancelled by user');
      } else {
        debugPrint('Purchase error: ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('Error purchasing: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches current offerings. Returns null on error or when not configured.
  Future<Offerings?> getOfferings() async {
    if (kUseMockBackend || !isRevenueCatConfigured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
      return null;
    }
  }

  /// Purchase by subscription type (monthly/yearly). Uses current offering.
  Future<bool> purchaseSubscription(SubscriptionType type) async {
    if (kUseMockBackend || !isRevenueCatConfigured) return false;
    if (type == SubscriptionType.none) return false;
    try {
      final offerings = await getOfferings();
      final current = offerings?.current;
      if (current == null || current.availablePackages.isEmpty) {
        debugPrint('No current offering or packages');
        return false;
      }
      Package package;
      if (type == SubscriptionType.monthly) {
        package = current.monthly ??
            current.availablePackages
                .where((p) => p.packageType == PackageType.monthly)
                .firstOrNull ??
            current.availablePackages.first;
      } else {
        package = current.annual ??
            current.availablePackages
                .where((p) => p.packageType == PackageType.annual)
                .firstOrNull ??
            current.availablePackages.first;
      }
      return await purchasePackage(package);
    } catch (e) {
      debugPrint('Error in purchaseSubscription: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (kUseMockBackend || !isRevenueCatConfigured) {
      await refreshSubscriptionStatus();
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      final customerInfo = await Purchases.restorePurchases();
      _applyCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      _isPremiumFromRevenueCat = false;
      _subscriptionEndDate = null;
      _subscriptionType = SubscriptionType.none;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLastPaywallShown() async {
    _lastPaywallShownAt = DateTime.now();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyLastPaywallShownAt,
        _lastPaywallShownAt!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error persisting last paywall shown: $e');
    }
  }

  bool shouldShowPaywall() {
    if (isPremium) return false;
    return hasReachedFreeLimit;
  }

  String getSubscriptionPrice(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return '\$9.99/ay';
      case SubscriptionType.yearly:
        return '\$99.99/yıl';
      case SubscriptionType.none:
        return 'Ücretsiz';
    }
  }

  List<String> getPremiumFeatures() {
    return [
      'Dolabını tam analiz et',
      'Sana özel stil asistanı',
      'Kişisel stil raporu',
      'Eksik parça tespiti',
      'Sınırsız kombin ve kıyafet',
    ];
  }
}
