import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wardrobe_provider.dart';
import '../models/clothing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ai_stylist_screen.dart';
import 'clothing_detail_screen.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Load clothing items when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeProvider>().loadClothingItems();
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, Clothing item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Kıyafeti Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu kıyafeti silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Önce UI'dan kaldır
                context.read<WardrobeProvider>().removeItemLocally(item);
                // Sonra backend'den sil
                await context.read<WardrobeProvider>().deleteClothingItem(item);
              } catch (e) {
                if (context.mounted) {
                  // Hata durumunda item'ı geri ekle
                  context.read<WardrobeProvider>().addItemLocally(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.grey.shade800,
                    ),
                  );
                }
              }
            },
            child: Text('Sil', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _showResetWardrobeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Dolabı Sıfırla', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm kıyafetleriniz silinecek. Bu işlem geri alınamaz. Emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<WardrobeProvider>().resetWardrobe();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dolap başarıyla sıfırlandı'),
                      backgroundColor: Color(0xFF2A2A2A),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.grey.shade800,
                    ),
                  );
                }
              }
            },
            child:
                Text('Sıfırla', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<WardrobeProvider>(
      builder: (context, wardrobeProvider, child) {
        final items = wardrobeProvider.items;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'dolabım',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white70, size: 26),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (items.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted,
                      color: Colors.white70, size: 26),
                  onPressed: () async {
                    try {
                      final formattedItems =
                          wardrobeProvider.getFormattedClothingItems();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: const Text('Kıyafet Listesi',
                                style: TextStyle(color: Colors.white)),
                            content: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: SelectableText(
                                formattedItems,
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.white70),
                              ),
                            ),
                            actions: [
                              TextButton.icon(
                                icon: const Icon(Icons.copy,
                                    color: Colors.white70),
                                label: const Text('Kopyala',
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: formattedItems));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Kıyafet listesi kopyalandı'),
                                        backgroundColor: Color(0xFF2A2A2A),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Kapat',
                                    style: TextStyle(color: Colors.white70)),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.grey.shade800,
                          ),
                        );
                      }
                    }
                  },
                  tooltip: 'Kıyafet Listesi',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.white70, size: 26),
                  onPressed: () => _showResetWardrobeConfirmation(context),
                  tooltip: 'Dolabı Sıfırla',
                ),
              ],
              const SizedBox(width: 6),
            ],
          ),
          floatingActionButton: items.isNotEmpty
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const AIStylistScreen(),
                          transitionsBuilder: (_, animation, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutQuint,
                              )),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    backgroundColor: Colors.grey.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    label: const Text(
                      'Kombin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    extendedPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                )
              : null,
          body: Stack(
            children: [
              // Animated background
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  return CustomPaint(
                    size: Size(size.width, size.height),
                    painter: BackgroundPainter(_controller.value),
                  );
                },
              ),

              // Content
              SafeArea(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.checkroom_outlined,
                              size: 70,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Henüz kıyafet eklenmemiş',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Dolabınızı oluşturmak için ana sayfadan kıyafet yükleyin',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kıyafet Koleksiyonunuz',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${items.length} kıyafet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(20),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            ClothingDetailScreen(item: item),
                                        transitionsBuilder:
                                            (_, animation, __, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade900,
                                          Colors.grey.shade800,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: Hero(
                                                  tag: 'clothing_${item.id}',
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color: Colors.white
                                                              .withValues(alpha: 0.1),
                                                          width: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: item.imageUrl,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        color: Colors.white
                                                            .withValues(alpha: 0.05),
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white70),
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          _buildImageErrorWidget(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade900,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.category,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      item.title,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(alpha: 0.7),
                                                        fontSize: 12,
                                                        height: 1.2,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF1E1E1E)
                                                            .withValues(alpha: 0.8),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(alpha: 0.2),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.05),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      onTap: () =>
                                                          _showDeleteConfirmation(
                                                              context, item),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Icon(
                                                          Icons
                                                              .delete_outline_rounded,
                                                          size: 20,
                                                          color: Colors.white
                                                              .withValues(alpha: 0.8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.white38,
          size: 40,
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

    // Draw subtle grid pattern
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
