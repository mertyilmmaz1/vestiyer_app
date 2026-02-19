import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_typography.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_primary_button.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_text_field.dart';
import 'package:vestiyer_nodejs/core/product/utils/scaffold_messenger_helper.dart';
import 'package:vestiyer_nodejs/core/product/utils/error_message_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/hive_cache_service.dart';
import '../services/firestore_service_base.dart';
import '../utils/mock_data_helper.dart';
import '../widgets/vestiyer_page_header.dart';
import '../main.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isUploadingProfileImage = false;

  bool get _canShowTestPremiumButton =>
      kDebugMode ||
      (Platform.isIOS &&
          dotenv.env['SHOW_TEST_PREMIUM_BUTTON']?.toLowerCase() == 'true');

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
      final cache = context.read<HiveCacheService?>();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      await prefs.remove('has_seen_new_intro');

      if (cache != null) {
        await cache.clearAll(); // Clear EVERYTHING
      }

      await authService.signOut();

      if (!mounted) return;

      // Reset providers
      context.read<WardrobeProvider>().setCurrentUserId(null);
      context.read<SubscriptionProvider>().setCurrentUser(null);

      // Reset static state
      resetAuthenticatedHomeState();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          EditorialPageRoute(page: const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showError('Çıkış yapılırken hata oluştu: $e');
      }
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    final uid = context.read<SubscriptionProvider>().currentUser?.id;
    if (uid == null) return;
    if (_isUploadingProfileImage) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedImage01, size: 24),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01, size: 24),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _isUploadingProfileImage = true);
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (picked == null) {
        setState(() => _isUploadingProfileImage = false);
        return;
      }
      final File file = File(picked.path);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showError('Seçilen dosya bulunamadı');
        }
        setState(() => _isUploadingProfileImage = false);
        return;
      }

      final File toUpload = await _compressProfileImage(file);
      final storage = context.read<FirebaseStorageService>();
      final firestore = context.read<FirestoreServiceBase>();
      final subscriptionProvider = context.read<SubscriptionProvider>();
      final oldUrl = subscriptionProvider.currentUser?.profileImage;

      final url = await storage.uploadProfileImage(uid, toUpload);
      if (toUpload.path != file.path) await toUpload.delete();

      if (oldUrl != null && oldUrl.isNotEmpty) {
        try {
          await storage.deleteByUrl(oldUrl);
        } catch (_) {}
      }

      await firestore.updateUserProfile(uid, {'profileImage': url});
      final updatedUser = await firestore.getUserProfile(uid);
      if (mounted && updatedUser != null) {
        subscriptionProvider.setCurrentUser(updatedUser);
        ScaffoldMessenger.of(context)
            .showSuccess('Profil fotoğrafı güncellendi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showError('Profil fotoğrafı yüklenemedi: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingProfileImage = false);
    }
  }

  Future<File> _compressProfileImage(File file) async {
    try {
      if (!await file.exists()) return file;
      final fileSize = await file.length();
      if (fileSize < 300 * 1024) return file;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return file;

      final image = img.decodeImage(bytes);
      if (image == null) return file;

      const int maxSize = 400;
      int targetWidth = image.width;
      int targetHeight = image.height;
      if (image.width > maxSize || image.height > maxSize) {
        if (image.width >= image.height) {
          targetWidth = maxSize;
          targetHeight = (image.height * maxSize / image.width).round();
        } else {
          targetHeight = maxSize;
          targetWidth = (image.width * maxSize / image.height).round();
        }
      }

      final resized = img.copyResize(image,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear);
      final compressed = img.encodeJpg(resized, quality: 85);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);
      return tempFile;
    } catch (e) {
      debugPrint('Profil resmi sıkıştırma hatası: $e');
      return file;
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
        final updatedUser =
            uid != null ? await firestore.getUserProfile(uid) : null;
        if (updatedUser != null) {
          context.read<SubscriptionProvider>().setCurrentUser(updatedUser);
        }
        ScaffoldMessenger.of(context).showSuccess('Profil güncellendi');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showError('Güncelleme başarısız: $e');
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
      backgroundColor: Colors.transparent,
      body: Column(
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
                                color: AppColors.softBackground,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _isUploadingProfileImage
                                            ? null
                                            : _pickAndUploadProfileImage,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: AppColors.textPrimary
                                                    .withValues(alpha: 0.1),
                                                border: Border.all(
                                                  color: AppColors.border,
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: (user?.profileImage ?? '')
                                                      .isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl:
                                                          user!.profileImage!,
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : HugeIcon(
                                                      icon: HugeIcons
                                                          .strokeRoundedUser,
                                                      color: AppColors
                                                          .textPrimary
                                                          .withValues(
                                                              alpha: 0.5),
                                                      size: 30,
                                                    ),
                                            ),
                                            if (_isUploadingProfileImage)
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          AppColors.primary),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${user?.firstName ?? ''} ${user?.lastName ?? ''}'
                                                  .toUpperCase(),
                                              style: AppTypography.headline
                                                  .copyWith(
                                                fontSize: 18,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user?.email ?? '',
                                              style:
                                                  AppTypography.body.copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
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
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Lütfen adınızı girin'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            VestiyerTextField(
                              controller: _lastNameController,
                              label: 'Soyad',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Lütfen soyadınızı girin'
                                  : null,
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
                                icon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedLogout01,
                                    size: 20,
                                    color: AppColors.textPrimary
                                        .withValues(alpha: 0.7)),
                                label: Text(
                                  'Çıkış Yap',
                                  style: TextStyle(
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.7),
                                      fontSize: 15),
                                ),
                              ),
                            ),
                            if (kDebugMode) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton(
                                  onPressed:
                                      _isLoading ? null : _loadSampleData,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary, width: 0.5),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  child: const Text('Test verilerini yükle'),
                                ),
                              ),
                            ],
                            if (_canShowTestPremiumButton) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _togglePremium,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary, width: 0.5),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  child: Consumer<SubscriptionProvider>(
                                    builder: (context, sub, child) {
                                      return Text(sub.isPremium
                                          ? 'Premium\'u İptal Et (Test)'
                                          : 'Premium Ol (Test)');
                                    },
                                  ),
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
    );
  }

  Future<void> _togglePremium() async {
    final subProvider = context.read<SubscriptionProvider>();
    final user = subProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showError('Önce giriş yapın');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firestore = context.read<FirestoreServiceBase>();
      final newStatus = !subProvider.isPremium;

      await firestore.updateUserProfile(user.id, {'isPremium': newStatus});

      final updatedUser = await firestore.getUserProfile(user.id);
      if (mounted && updatedUser != null) {
        subProvider.setCurrentUser(updatedUser);
        ScaffoldMessenger.of(context).showSuccess(
          newStatus ? 'Premium mod aktif edildi' : 'Premium mod pasif edildi',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showError('Hata: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSampleData() async {
    final uid = context.read<SubscriptionProvider>().currentUser?.id ??
        context.read<WardrobeProvider>().currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showError('Önce giriş yapın');
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
            'clothingItems':
                combo.clothingItems.map((e) => e.toJson()).toList(),
            'isAIGenerated': true,
            'isFavorite': false,
            'timesWorn': 0,
            'tags': [],
          });
        }
      }
      if (mounted) {
        context.read<WardrobeProvider>().loadClothingItems();
        ScaffoldMessenger.of(context)
            .showSuccess('${list.length} kıyafet ve örnek kombinler eklendi.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showError(
          ErrorMessageHelper.getUserFriendlyMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
