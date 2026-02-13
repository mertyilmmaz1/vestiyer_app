import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service_base.dart';

enum SubscriptionType {
  monthly,
  yearly,
  none,
}

class SubscriptionProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  final FirestoreServiceBase _firestore;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isPremium = false;
  DateTime? _subscriptionEndDate;
  SubscriptionType _subscriptionType = SubscriptionType.none;
  int _freeItemsUsed = 0;
  final int _freeItemLimit = 10;
  static const int freeLimit = 10;
  User? _currentUser;

  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;
  SubscriptionType get subscriptionType => _subscriptionType;
  int get freeItemsUsed => _freeItemsUsed;
  int get freeItemLimit => _freeItemLimit;
  int get remainingFreeItems => freeLimit - _freeItemsUsed;
  bool get hasReachedFreeLimit => _freeItemsUsed >= freeLimit;
  User? get currentUser => _currentUser;

  SubscriptionProvider(this._authService, this._firestore) {
    _initialize();
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
    if (user != null) {
      refreshSubscriptionStatus();
    } else {
      _resetSubscriptionData();
    }
  }

  void _resetSubscriptionData() {
    _isPremium = false;
    _freeItemsUsed = 0;
    _subscriptionEndDate = null;
    _subscriptionType = SubscriptionType.none;
    notifyListeners();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    try {
      _isLoading = true;
      notifyListeners();
      final uid = _authService.currentUserId;
      if (uid != null) {
        _currentUser = await _firestore.getUserProfile(uid);
        if (_currentUser != null) await refreshSubscriptionStatus();
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSubscriptionStatus() async {
    if (_currentUser == null) {
      _resetSubscriptionData();
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      final user = await _firestore.getUserProfile(_currentUser!.id);
      if (user != null) {
        _currentUser = user;
        _isPremium = user.isPremium;
        _subscriptionEndDate = null;
        _subscriptionType = _isPremium ? SubscriptionType.monthly : SubscriptionType.none;
        await _updateFreeItemsUsed();
      }
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
    if (_isPremium) return true;
    return _freeItemsUsed < freeLimit;
  }

  void incrementFreeItemsUsed() {
    if (!_isPremium) {
      _freeItemsUsed++;
      notifyListeners();
    }
  }

  Future<void> purchaseSubscription(SubscriptionType type) async {
    try {
      _isLoading = true;
      notifyListeners();
      final now = DateTime.now();
      final endDate = type == SubscriptionType.monthly
          ? DateTime(now.year, now.month + 1, now.day)
          : DateTime(now.year + 1, now.month, now.day);
      _isPremium = true;
      _subscriptionEndDate = endDate;
      _subscriptionType = type;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    try {
      _isLoading = true;
      notifyListeners();
      await refreshSubscriptionStatus();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLastPaywallShown() async {}

  bool shouldShowPaywall() {
    if (_isPremium) return false;
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
      'Sınırsız kıyafet ekleme',
      'Gelişmiş AI kombinleri',
      'Özel stilist tavsiyeleri',
      'Reklamsız deneyim',
      'Öncelikli müşteri desteği',
    ];
  }
}
