import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_primary_button.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/paywall_widget.dart';
import '../widgets/vestiyer_page_header.dart';
import 'premium_screen.dart';
import 'dart:async';
import 'wardrobe_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

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
  bool _lastUploadHadLowConfidence = false;

  final _colorController = TextEditingController();
  final _materialController = TextEditingController();

  final List<String> _loadingMessages = [
    'Kıyafetiniz analiz ediliyor...',
    'Stil ve renk uyumu değerlendiriliyor...',
    'En uygun kombinler belirleniyor...',
    'Kıyafetinizin kategorisi tespit ediliyor...',
    'Moda trendlerine göre değerlendiriliyor...',
    'Stil önerileri hazırlanıyor...',
    'Dolabınıza ekleniyor...',
  ];
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
              (_currentMessageIndex + 1) % _loadingMessages.length;
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

      final List<XFile> images = await _picker.pickMultiImage();
      if (!mounted) return;
      if (images.isNotEmpty) {
        setState(() {
          _images = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir fotoğraf seçin')),
      );
      return;
    }

    // Check if the user has reached the free limit and is not premium
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final remainingFreeItems = subscriptionProvider.remainingFreeItems;

    if (!subscriptionProvider.canAddClothing()) {
      // Show paywall immediately if no free items left
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.itemLimit,
        customMessage:
            'Ücretsiz kıyafet ekleme limitine ulaştınız. Premium üyelikle sınırsız kıyafet ekleyin.',
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
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.softBackground,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text(
            'LİMİT UYARISI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          content: Text(
            'Ücretsiz sürümde $remainingFreeItems kıyafet ekleme hakkınız kaldı, ancak ${_images.length} kıyafet seçtiniz. Premium üyelikle sınırsız kıyafet ekleyebilirsiniz veya seçiminizi azaltabilirsiniz.',
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
                'İptal',
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
              child: const Text(
                'Premium\'a Yükselt',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'İlk $remainingFreeItems Kıyafeti Yükle',
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

      for (int i = 0; i < _images.length; i++) {
        setState(() {
          _currentUploadIndex = i;
        });

        try {
          await provider.addClothingItem(_images[i]);

          // Update the free items counter in the subscription provider
          if (!subscriptionProvider.isPremium) {
            subscriptionProvider.incrementFreeItemsUsed();
          }

          // Get the analysis results
          final response = provider.getLastResponse();
          if (response != null) {
            setState(() {
              _uploadedDescriptions
                  .add(response['description'] ?? 'Kıyafet eklendi');
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
              await PaywallWidget.showPaywall(
                context,
                type: PaywallType.itemLimit,
                customMessage:
                    'Ücretsiz kıyafet ekleme limitine ulaştınız. Premium üyelikle sınırsız kıyafet ekleyin.',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kıyafet yüklenirken hata oluştu: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
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
        _uploadedDescription = _uploadedDescriptions.isNotEmpty
            ? _uploadedDescriptions.join('\n\n')
            : 'Kıyafetler başarıyla eklendi';
      });

      // After successful upload and analysis
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kıyafet başarıyla yüklendi ve analiz edildi'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Yükleme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
        ),
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
      _lastUploadHadLowConfidence = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSuccess ? 'Yükleme Başarılı' : 'Kıyafet Yükle';
    final subtitle =
        _isSuccess ? null : 'Kıyafetlerini yükle ve kişisel dolabını oluştur.';
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

  Widget _buildInitialUploadScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _getImages(ImageSource.gallery),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: AppColors.softBackground,
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FOTOĞRAF EKLE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Galeriden seç veya fotoğraf çek',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'SEÇİLEN KIYAFETLER',
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
                    'KIYAFETLERİ YÜKLE VE ANALİZ ET',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _loadingMessages[_currentMessageIndex],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '${_currentUploadIndex + 1} / $_totalUploads',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
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
              'BAŞARILI!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
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
                        'Analiz tam emin değil. Kıyafet detaylarını dolaptan düzenleyebilirsiniz.',
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
                    child: const Text('Yeni Yükleme'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: VestiyerPrimaryButton(
                    text: 'Dolabı Gör',
                    onTap: () {
                      Navigator.push(
                        context,
                        EditorialPageRoute(page: const WardrobeScreen()),
                      );
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
}
