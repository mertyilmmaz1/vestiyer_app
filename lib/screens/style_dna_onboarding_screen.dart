import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

import '../constants/style_dna_constants.dart';
import '../models/style_profile.dart';
import '../models/user.dart' as app_user;
import '../services/firestore_service_base.dart';
import 'premium_screen.dart';

/// Oyunlaştırılmış Stil DNA onboarding — Zara Editoryal Tasarım
class StyleDNAOnboardingScreen extends StatefulWidget {
  const StyleDNAOnboardingScreen({
    super.key,
    required this.userId,
    required this.onComplete,
    this.nextScreen,
  });

  final String userId;
  final void Function(app_user.User? updatedUser) onComplete;
  final Widget? nextScreen;

  @override
  State<StyleDNAOnboardingScreen> createState() =>
      _StyleDNAOnboardingScreenState();
}

class _StyleDNAOnboardingScreenState extends State<StyleDNAOnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  static const int _totalSteps = 5;

  // Selections
  final List<String> _selectedStyles = [];
  final List<String> _selectedColors = [];
  String? _selectedFit;
  String? _selectedLifestyle;

  bool _isSaving = false;

  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
  }

  void _restartAnimation() {
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _saveAndComplete() async {
    if (_selectedStyles.isEmpty ||
        _selectedColors.isEmpty ||
        _selectedFit == null ||
        _selectedLifestyle == null) return;

    setState(() => _isSaving = true);

    try {
      final firestore = context.read<FirestoreServiceBase>();
      final profile = StyleProfile(
        styleDNA: _selectedStyles,
        colorBias: _selectedColors,
        fitPreference: _selectedFit!,
        lifestyle: _selectedLifestyle!,
        completedAt: DateTime.now(),
      );

      await firestore.setUserStyleProfile(
        widget.userId,
        profile.toFirestore()..['completedAt'] = DateTime.now(),
      );

      if (!mounted) return;
      final updatedUser = await firestore.getUserProfile(widget.userId);

      if (!mounted) return;
      if (widget.nextScreen != null) {
        Navigator.of(context).pushReplacement(
          EditorialPageRoute(page: widget.nextScreen!),
        );
      }
      widget.onComplete(updatedUser);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.background,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _restartAnimation();
    } else {
      _saveAndComplete();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _restartAnimation();
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedStyles.length >= 1 && _selectedStyles.length <= 3;
      case 1:
        return _selectedColors.isNotEmpty;
      case 2:
        return _selectedFit != null;
      case 3:
        return _selectedLifestyle != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildCurrentStep(),
                ),
              ),
            ),

            // Bottom Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _goBack,
                  child: const Icon(Icons.arrow_back_ios, size: 18),
                )
              else
                const SizedBox(width: 18),

              Text(
                'STİL DNA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 3.0,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
              ),

              const SizedBox(width: 18), // Balance for back icon
            ],
          ),
          const SizedBox(height: 16),
          // Progress Line
          Stack(
            children: [
              Container(
                height: 1,
                width: double.infinity,
                color: AppColors.textPrimary.withValues(alpha: 0.1),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                widthFactor: (_currentStep + 1) / _totalSteps,
                child: Container(
                  height: 1,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canProceed && !_isSaving ? _goNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: AppColors.background,
            disabledBackgroundColor:
                AppColors.textPrimary.withValues(alpha: 0.1),
            disabledForegroundColor:
                AppColors.textPrimary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: _isSaving
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.background),
                  ),
                )
              : Text(
                  _currentStep == _totalSteps - 1
                      ? 'PROFILIMI OLUŞTUR'
                      : 'DEVAM ET',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.0,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStyleStep();
      case 1:
        return _buildColorStep();
      case 2:
        return _buildFitStep();
      case 3:
        return _buildLifestyleStep();
      case 4:
        return _buildResultStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Style ───
  Widget _buildStyleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildQuestionTitle('TARZINI\nSEÇ'),
          const SizedBox(height: 12),
          _buildDescription(
              'Sana en yakın 3 stili seç.\nBu seçimler kombinlerini şekillendirecek.'),
          const SizedBox(height: 48),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kStyleDnaOptions.map((opt) {
              final selected = _selectedStyles.contains(opt.value);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedStyles.remove(opt.value);
                    } else if (_selectedStyles.length < 3) {
                      _selectedStyles.add(opt.value);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color:
                        selected ? AppColors.textPrimary : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    opt.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.0,
                      color: selected
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedStyles.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '${_selectedStyles.length}/3 SEÇİLDİ',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 2: Color ───
  Widget _buildColorStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildQuestionTitle('RENK\nTERCİHLERİN'),
          const SizedBox(height: 12),
          _buildDescription(
              'Dolabında en sık kullandığın renkleri seç.\nBirden fazla seçim yapabilirsin.'),
          const SizedBox(height: 48),
          Wrap(
            spacing: 20,
            runSpacing: 24,
            children: kColorBiasOptions.map((opt) {
              final selected = _selectedColors.contains(opt.value);
              // Map color names/codes to actual Colors if needed,
              // for now using a placeholder visual representation
              Color colorPreview;
              switch (opt.value) {
                case 'siyah':
                  colorPreview = const Color(0xFF000000);
                  break;
                case 'beyaz':
                  colorPreview = const Color(0xFFFFFFFF);
                  break;
                case 'bej':
                  colorPreview = const Color(0xFFF5F5DC);
                  break;
                case 'mavi':
                  colorPreview = const Color(0xFF2196F3);
                  break;
                case 'toprak_tonlari':
                  colorPreview = const Color(0xFF8B4513);
                  break;
                case 'renkli':
                  colorPreview = const Color(0xFFFF4081);
                  break;
                default:
                  colorPreview = Colors.grey;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedColors.remove(opt.value);
                        } else {
                          _selectedColors.add(opt.value);
                        }
                      });
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          color: colorPreview,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: AppColors.textPrimary, width: 2)
                              : Border.all(color: Colors.transparent, width: 2),
                          boxShadow: [
                            if (selected)
                              BoxShadow(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                          ]),
                      child: selected
                          ? Center(
                              child: Icon(
                                Icons.check,
                                color: colorPreview.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                size: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opt.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textPrimary
                          .withValues(alpha: selected ? 1.0 : 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Fit ───
  Widget _buildFitStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildQuestionTitle('FİT\nTERCİHİN'),
          const SizedBox(height: 12),
          _buildDescription(
              'Kıyafetlerin üzerindeki duruşu nasıl olmalı?\nSana özel öneriler için önemli.'),
          const SizedBox(height: 48),
          ...kFitOptions.map((opt) {
            final selected = _selectedFit == opt.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFit = opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.textPrimary.withValues(alpha: 0.03)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        opt.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w500 : FontWeight.w400,
                          letterSpacing: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check,
                            size: 18, color: AppColors.textPrimary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Step 4: Lifestyle ───
  Widget _buildLifestyleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildQuestionTitle('YAŞAM\nTARZIN'),
          const SizedBox(height: 12),
          _buildDescription(
              'Günlük hayatın nasıl geçiyor?\nKombinlerin temposuna uyum sağlasın.'),
          const SizedBox(height: 48),
          ...kLifestyleOptions.map((opt) {
            final selected = _selectedLifestyle == opt.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedLifestyle = opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.textPrimary.withValues(alpha: 0.03)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w500 : FontWeight.w400,
                            letterSpacing: 1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check,
                            size: 18, color: AppColors.textPrimary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Step 5: Result ───
  Widget _buildResultStep() {
    final styleLabels = _selectedStyles
        .map((v) => kStyleDnaOptions
            .firstWhere((o) => o.value == v,
                orElse: () => const StyleDnaOption('', ''))
            .label)
        .join(', ');

    final fitLabel = kFitOptions
        .firstWhere((o) => o.value == _selectedFit,
            orElse: () => const FitOption('', ''))
        .label;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildQuestionTitle('STİL\nANALİZİN'),
          const SizedBox(height: 12),
          _buildDescription(
              'Seçimlerine göre oluşturulan stil profilin hazır.'),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.softBackground,
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 20,
                        color: AppColors.textPrimary.withValues(alpha: 0.8)),
                    const SizedBox(width: 12),
                    Text(
                      'SENİN STİLİN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildResultRow('TARZ', styleLabels.toUpperCase()),
                const SizedBox(height: 24),
                _buildResultRow('FİT', fitLabel.toUpperCase()),
                const SizedBox(height: 24),
                _buildResultRow('MOD', _selectedLifestyle?.toUpperCase() ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                EditorialPageRoute(
                  page: const PremiumScreen(showCloseButton: true),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                  border: Border(
                top: BorderSide(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    width: 0.5),
                bottom: BorderSide(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    width: 0.5),
              )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAHA FAZLA ÖZELLİK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kişisel stil planını keşfet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: AppColors.textSecondary,
        height: 1.6,
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.5,
            color: AppColors.textPrimary.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
