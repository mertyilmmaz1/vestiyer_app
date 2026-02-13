import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/paywall_widget.dart';
import 'premium_screen.dart';
import 'dart:async';
import 'wardrobe_screen.dart';
import 'dart:math' as math;

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

  // OpenAI tarzı monokromatik renk paleti
  final _primaryColor = Colors.white; // Ana metin rengi
  final _secondaryColor = Colors.white70; // İkincil metin rengi
  final _backgroundColor = const Color(0xFF121212); // Koyu arkaplan

  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController.forward();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Check if the user has reached the free limit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFreeLimit();
    });
  }

  Future<void> _checkFreeLimit() async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    if (subscriptionProvider.hasReachedFreeLimit &&
        !subscriptionProvider.isPremium) {
      await PaywallWidget.showPaywall(
        context,
        type: PaywallType.itemLimit,
        barrierDismissible: true,
      );

      // If user is still not premium after seeing the paywall, return to previous screen
      if (!subscriptionProvider.isPremium && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
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
        barrierDismissible: true,
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
          backgroundColor: const Color(0xFF1E1E1E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Limit Uyarısı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Ücretsiz sürümde $remainingFreeItems kıyafet ekleme hakkınız kaldı, ancak ${_images.length} kıyafet seçtiniz. Premium üyelikle sınırsız kıyafet ekleyebilirsiniz veya seçiminizi azaltabilirsiniz.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
              child: const Text(
                'Premium\'a Yükselt',
                style: TextStyle(color: Colors.amber),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'İlk $remainingFreeItems Kıyafeti Yükle',
                style: const TextStyle(color: Colors.white),
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
                barrierDismissible: true,
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
                  backgroundColor: Colors.red.shade900,
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Yükleme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red.shade900,
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isSuccess ? 'Yükleme Başarılı' : 'Kıyafet Yükle',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (_, __) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: BackgroundPainter(_backgroundController.value),
              );
            },
          ),

          // Content
          SafeArea(
            child: _isLoading
                ? _buildLoadingScreen()
                : _isSuccess
                    ? _buildSuccessScreen()
                    : _buildInitialUploadScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialUploadScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Dolabını Güncelle',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kıyafetlerini yükle ve kişisel dolabını oluştur.',
              style: TextStyle(
                fontSize: 16,
                color: _secondaryColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _getImages(ImageSource.gallery),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fotoğraf Ekle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Galeriden seç veya fotoğraf çek',
                      style: TextStyle(
                        fontSize: 14,
                        color: _secondaryColor,
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
                'Seçilen Kıyafetler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                  letterSpacing: -0.2,
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
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: _primaryColor.withValues(alpha: 0.8),
                          size: 28,
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
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
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
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
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: _primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Kıyafetleri Yükle ve Analiz Et',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
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
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _loadingMessages[_currentMessageIndex],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '${_currentUploadIndex + 1} / $_totalUploads',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryColor,
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
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Başarılı!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_uploadedDescription != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _uploadedDescription!,
                  style: TextStyle(
                    fontSize: 14,
                    color: _secondaryColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: _primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Yeni Yükleme'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WardrobeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Dolabı Gör'),
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

class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw dark background
    final backgroundGradient = const LinearGradient(
      colors: [
        Color(0xFF121212),
        Color(0xFF1A1A1A),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    paint.shader = backgroundGradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw animated gradient shapes
    final shapePaint = Paint()..style = PaintingStyle.fill;

    // First blob
    shapePaint.color = Colors.white.withValues(alpha: 0.03);
    final path1 = Path();
    final centerX1 = size.width * 0.2 + math.sin(animationValue * math.pi) * 40;
    final centerY1 =
        size.height * 0.2 + math.cos(animationValue * math.pi) * 40;
    final radius1 = size.width * 0.5;
    path1.addOval(
        Rect.fromCircle(center: Offset(centerX1, centerY1), radius: radius1));
    canvas.drawPath(path1, shapePaint);

    // Second blob
    shapePaint.color = Colors.white.withValues(alpha: 0.02);
    final path2 = Path();
    final centerX2 =
        size.width * 0.8 + math.cos(animationValue * 1.5 * math.pi) * 30;
    final centerY2 =
        size.height * 0.5 + math.sin(animationValue * 1.5 * math.pi) * 30;
    final radius2 = size.width * 0.4;
    path2.addOval(
        Rect.fromCircle(center: Offset(centerX2, centerY2), radius: radius2));
    canvas.drawPath(path2, shapePaint);

    // Third blob
    shapePaint.color = Colors.white.withValues(alpha: 0.01);
    final path3 = Path();
    final centerX3 =
        size.width * 0.5 + math.sin(animationValue * 2 * math.pi + 2) * 20;
    final centerY3 =
        size.height * 0.8 + math.cos(animationValue * 2 * math.pi + 2) * 20;
    final radius3 = size.width * 0.6;
    path3.addOval(
        Rect.fromCircle(center: Offset(centerX3, centerY3), radius: radius3));
    canvas.drawPath(path3, shapePaint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
