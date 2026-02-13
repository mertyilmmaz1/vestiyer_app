import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_primary_button.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_text_field.dart';
import '../providers/subscription_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/hive_cache_service.dart';
import '../services/firestore_service_base.dart';
import '../utils/mock_data_helper.dart';
import '../widgets/vestiyer_page_header.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBackButton = true});

  /// When false (e.g. when used as bottom nav tab), back button is hidden.
  final bool showBackButton;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final user = subscriptionProvider.currentUser;

    if (user != null) {
      setState(() {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final authService = context.read<FirebaseAuthService>();
      final uid = authService.currentUserId;
      final cache = context.read<HiveCacheService?>();
      if (cache != null && uid != null) {
        await cache.invalidateUser(uid);
        await cache.invalidateClothing(uid);
        await cache.invalidateCombinations(uid);
      }
      await authService.signOut();
      if (!mounted) return;
      context.read<WardrobeProvider>().setCurrentUserId(null);
      context.read<SubscriptionProvider>().setCurrentUser(null);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = context.read<FirestoreServiceBase>();
      final uid = context.read<SubscriptionProvider>().currentUser?.id;
      if (uid != null) {
        await firestore.updateUserProfile(uid, {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil güncelleme özelliği yakında eklenecek'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme başarısız: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VestiyerPageHeader(
              title: 'Profil',
              subtitle: 'Profili düzenle',
              showBackButton: widget.showBackButton,
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              const SizedBox(height: 20),
              Consumer<SubscriptionProvider>(
                builder: (context, subscriptionProvider, child) {
                  final user = subscriptionProvider.currentUser;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.textPrimary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user != null
                                            ? '${user.firstName} ${user.lastName}'
                                            : 'Kullanıcı',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: subscriptionProvider.isPremium
                                              ? AppColors.primary.withValues(alpha: 0.2)
                                              : AppColors.textSecondary.withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          subscriptionProvider.isPremium
                                              ? 'Premium Üye'
                                              : 'Ücretsiz Üye',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: subscriptionProvider
                                                    .isPremium
                                                ? AppColors.primary
                                                : AppColors.textPrimary.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      VestiyerTextField(
                        controller: _firstNameController,
                        label: 'Ad',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Lütfen adınızı girin' : null,
                      ),
                      const SizedBox(height: 16),
                      VestiyerTextField(
                        controller: _lastNameController,
                        label: 'Soyad',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Lütfen soyadınızı girin' : null,
                      ),
                      const SizedBox(height: 32),
                      VestiyerPrimaryButton(
                        text: 'Profili Güncelle',
                        isLoading: _isLoading,
                        enabled: !_isLoading,
                        onTap: _updateProfile,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _logout,
                          icon: Icon(Icons.logout_outlined, size: 20, color: AppColors.textPrimary.withValues(alpha: 0.7)),
                          label: Text(
                            'Çıkış Yap',
                            style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.7), fontSize: 15),
                          ),
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _loadSampleData,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Test verilerini yükle'),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSampleData() async {
    final uid = context.read<SubscriptionProvider>().currentUser?.id ?? context.read<WardrobeProvider>().currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce giriş yapın')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final firestore = context.read<FirestoreServiceBase>();
      final list = await loadSampleClothingFromAssets(userId: uid, limit: 8);
      final ids = <String>[];
      for (final c in list) {
        final added = await firestore.addClothing(uid, c.toFirestore());
        if (added != null) ids.add(added.id);
      }
      if (ids.length >= 2) {
        final combos = mockCombinations(userId: uid, clothingIds: ids);
        for (final combo in combos) {
          await firestore.addCombination(uid, {
            'name': combo.name,
            'description': combo.description,
            'occasion': combo.occasion,
            'season': combo.season,
            'clothingItems': combo.clothingItems.map((e) => e.toJson()).toList(),
            'isAIGenerated': true,
            'isFavorite': false,
            'timesWorn': 0,
            'tags': [],
          });
        }
      }
      if (mounted) {
        context.read<WardrobeProvider>().loadClothingItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${list.length} kıyafet ve örnek kombinler eklendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
