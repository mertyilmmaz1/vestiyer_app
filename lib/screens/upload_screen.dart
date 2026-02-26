import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_primary_button.dart';
import 'package:vestiyer_nodejs/core/product/utils/scaffold_messenger_helper.dart';
import 'package:vestiyer_nodejs/core/product/utils/error_message_helper.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/paywall_widget.dart';
import '../widgets/vestiyer_page_header.dart';
import 'premium_screen.dart';
import 'dart:async';
import 'clothing_camera_screen.dart';
import '../widgets/upload_guide_card.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/product/theme/app_typography.dart';
import '../core/product/theme/app_spacing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing.dart';
import 'clothing_detail_screen.dart';
import 'wardrobe_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, this.onViewWardrobe});

  final VoidCallback? onViewWardrobe;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _uploadedDescription;
  int _currentUploadIndex = 0;
  int _totalUploads = 0;
  List<String> _uploadedDescriptions = [];
  List<Clothing> _uploadedItems = [];
  bool _lastUploadHadLowConfidence = false;

  final _colorController = TextEditingController();
  final _materialController = TextEditingController();

  static const int _loadingMessagesCount = 7;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController.forward();

    // Check if the user has reached the free limit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFreeLimit();
    });
  }

  Future<void> _checkFreeLimit() async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    if (!subscriptionProvider.canAddClothing()) {
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.itemLimit,
      );

      if (!subscriptionProvider.isPremium && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startLoadingAnimation() {
    _currentMessageIndex = 0;
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessagesCount;
        });
      }
    });
  }

  void _stopLoadingAnimation() {
    _messageTimer?.cancel();
  }

  Future<void> _getImages(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (!mounted) return;
        if (images.isNotEmpty) {
          setState(() {
            final newImages = images.map((image) => File(image.path)).toList();
            _images.addAll(newImages);
          });
        }
      } else {
        // Use our custom camera screen
        final File? image = await Navigator.push<File>(
          context,
          EditorialPageRoute(page: const ClothingCameraScreen()),
        );

        if (!mounted) return;
        if (image != null) {
          setState(() {
            _images.add(image);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showError(
        ErrorMessageHelper.getUserFriendlyMessage(context, e),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_images.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showError(l10n.uploadSelectPhoto);
      return;
    }

    // Check if the user has reached the free limit and is not premium
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final remainingFreeItems = subscriptionProvider.remainingFreeItems;

    if (!subscriptionProvider.canAddClothing()) {
      // Show paywall immediately if no free items left
      final l10n = AppLocalizations.of(context)!;
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.itemLimit,
        customMessage: l10n.uploadLimitReached,
      );
      if (!mounted) return;

      // If user didn't upgrade to premium, return without uploading
      if (!subscriptionProvider.isPremium) {
        return;
      }
    }

    // Check if the number of images exceeds the remaining free limit for non-premium users
    if (!subscriptionProvider.isPremium &&
        _images.length > remainingFreeItems) {
      final l10n = AppLocalizations.of(context)!;
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.softBackground,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(
            l10n.uploadLimitTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          content: Text(
            l10n.uploadLimitMessage(remainingFreeItems, _images.length),
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.7)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.push(
                  context,
                  EditorialPageRoute(page: const PremiumScreen()),
                );
              },
              child: Text(
                l10n.uploadUpgradePremium,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.uploadFirstItems(remainingFreeItems),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;

      if (result != true) {
        return;
      }

      // Trim images to remaining free limit
      setState(() {
        _images = _images.sublist(0, remainingFreeItems);
      });
    }

    try {
      setState(() {
        _isLoading = true;
        _currentUploadIndex = 0;
        _totalUploads = _images.length;
        _uploadedDescriptions = [];
        _lastUploadHadLowConfidence = false;
      });
      _startLoadingAnimation();

      if (!mounted) return;
      final provider = Provider.of<WardrobeProvider>(context, listen: false);
      final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;

      for (int i = 0; i < _images.length; i++) {
        setState(() {
          _currentUploadIndex = i;
        });

        try {
          final newlyAddedItem = await provider.addClothingItem(_images[i],
              locale: locale);
          if (newlyAddedItem != null) {
            _uploadedItems.add(newlyAddedItem);
          }

          // Update the free items counter in the subscription provider
          if (!subscriptionProvider.isPremium) {
            subscriptionProvider.incrementFreeItemsUsed();
          }

          // Get the analysis results
          final response = provider.getLastResponse();
          if (response != null) {
            final l10n = AppLocalizations.of(context)!;
            setState(() {
              _uploadedDescriptions
                  .add(response['description'] ?? l10n.uploadClothingAdded);
              if (response['lowConfidence'] == true) {
                _lastUploadHadLowConfidence = true;
              }
            });
          }
        } catch (e) {
          debugPrint('Kıyafet yükleme hatası: $e');

          // Handle free limit exceeded error
          if (e.toString().contains('limit') ||
              e.toString().contains('Limit')) {
            if (mounted) {
              // Show paywall for limit exceeded
              final l10n = AppLocalizations.of(context)!;
              await PaywallWidget.showPaywall(
                context,
                type: PaywallType.itemLimit,
                customMessage: l10n.uploadLimitReached,
              );

              // If user didn't upgrade, stop the upload process
              if (!subscriptionProvider.isPremium) {
                setState(() {
                  _isLoading = false;
                });
                return;
              }
            }
          } else {
            // Show generic error for other errors
            if (mounted) {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context)
                  .showError(l10n.uploadError(e.toString()));
            }
          }

          // Don't mark as success if there was an error
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isSuccess = true;
        final l10n = AppLocalizations.of(context)!;
      _uploadedDescription = _uploadedDescriptions.isNotEmpty
            ? _uploadedDescriptions.join('\n\n')
            : l10n.uploadSuccessMessage;
      });

      // After successful upload and analysis
      if (mounted) {
        if (_uploadedItems.length == 1) {
          Navigator.push(
            context,
            EditorialPageRoute(
                page: ClothingDetailScreen(item: _uploadedItems.first)),
          );
        }

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSuccess(l10n.uploadSuccessSnackbar);
      }
    } catch (e) {
      debugPrint('Yükleme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showError(
        ErrorMessageHelper.getUserFriendlyMessage(context, e),
      );
    } finally {
      _stopLoadingAnimation();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetUpload() {
    setState(() {
      _isSuccess = false;
      _images = [];
      _currentUploadIndex = 0;
      _totalUploads = 0;
      _uploadedDescriptions = [];
      _uploadedItems = [];
      _lastUploadHadLowConfidence = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _isSuccess ? l10n.uploadSuccessTitle : l10n.uploadTitle;
    final subtitle = _isSuccess ? null : l10n.uploadSubtitle;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VestiyerPageHeader(
              title: title,
              subtitle: subtitle,
              showBackButton: true,
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _isSuccess
                      ? _buildSuccessScreen()
                      : _buildInitialUploadScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required dynamic icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            HugeIcon(
              icon: icon,
              color: AppColors.textPrimary,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialUploadScreen() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UploadGuideCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: l10n.uploadGallery,
                    subtitle: l10n.uploadMultiSelect,
                    icon: HugeIcons.strokeRoundedImage01,
                    onTap: () => _getImages(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    title: l10n.uploadCamera,
                    subtitle: l10n.uploadSpecialShot,
                    icon: HugeIcons.strokeRoundedCamera01,
                    onTap: () => _getImages(ImageSource.camera),
                  ),
                ),
              ],
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.uploadSelectedItems,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _images.length + 1, // +1 for add button
                itemBuilder: (context, index) {
                  if (index == _images.length) {
                    // Add button
                    return GestureDetector(
                      onTap: () => _getImages(ImageSource.gallery),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.softBackground,
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                          size: 28,
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Image.file(
                          _images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.textPrimary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _uploadImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.textPrimary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    l10n.uploadAndAnalyze,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final l10n = AppLocalizations.of(context)!;
    final messages = [
      l10n.uploadAnalyzing,
      l10n.uploadStyleCheck,
      l10n.uploadCombinCheck,
      l10n.uploadCategoryCheck,
      l10n.uploadTrendCheck,
      l10n.uploadStyleSuggestions,
      l10n.uploadAddingToWardrobe,
    ];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.softBackground,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: _images.isNotEmpty
                    ? Image.file(_images[_currentUploadIndex],
                        fit: BoxFit.cover)
                    : const Center(
                        child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCircle,
                            size: 40,
                            color: AppColors.border)),
              ),
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Positioned(
                    top: _fadeController.value * 160,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.0),
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            messages[_currentMessageIndex % messages.length],
            style: AppTypography.title.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${_currentUploadIndex + 1} / $_totalUploads',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.uploadSuccessBadge,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            if (_uploadedItems.isNotEmpty) ...[
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _uploadedItems.length,
                  itemBuilder: (context, index) {
                    final item = _uploadedItems[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          EditorialPageRoute(
                              page: ClothingDetailScreen(item: item)),
                        );
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: CachedNetworkImage(
                                imageUrl: item.displayImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.softBackground,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              color: AppColors.background,
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_uploadedDescription != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.softBackground,
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _uploadedDescription!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_lastUploadHadLowConfidence) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.uploadLowConfidence,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.textPrimary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(l10n.uploadNewUpload),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: VestiyerPrimaryButton(
                    text: l10n.uploadViewWardrobe,
                    onTap: () {
                      if (widget.onViewWardrobe != null) {
                        Navigator.of(context).pop();
                        widget.onViewWardrobe!();
                      } else {
                        Navigator.push(
                          context,
                          EditorialPageRoute(page: const WardrobeScreen()),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadIcon(dynamic icon) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: 28,
          color: AppColors.textPrimary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
