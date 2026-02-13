import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_of_service_screen.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service_base.dart';
import '../models/user.dart' as app_user;
import '../providers/wardrobe_provider.dart';
import '../providers/subscription_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Focus nodes for keyboard navigation
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isRegistering = false;
  final bool _isSocialLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<FirebaseAuthService>();
      final firestore = context.read<FirestoreServiceBase>();
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      final uid = authService.currentUserId;
      if (uid == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giriş yapılamadı.')));
        return;
      }
      app_user.User? profile = await firestore.getUserProfile(uid);
      profile ??= app_user.User(
        id: uid,
        email: _emailController.text.trim(),
        firstName: '',
        lastName: '',
        createdAt: DateTime.now(),
        isActive: true,
        isPremium: false,
      );
      if (!mounted) return;
      context.read<WardrobeProvider>().setCurrentUserId(uid);
      context.read<SubscriptionProvider>().setCurrentUser(profile);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Giriş yapılamadı')),
        );
      }
    } catch (e) {
      log('Giriş hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş yapılamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<FirebaseAuthService>();
      final firestore = context.read<FirestoreServiceBase>();
      await authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      final uid = authService.currentUserId;
      if (uid == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt yapılamadı.')));
        return;
      }
      await firestore.setUserProfile(
        uid,
        _emailController.text.trim(),
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
      );
      final profile = app_user.User(
        id: uid,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        createdAt: DateTime.now(),
        isActive: true,
        isPremium: false,
      );
      if (!mounted) return;
      context.read<WardrobeProvider>().setCurrentUserId(uid);
      context.read<SubscriptionProvider>().setCurrentUser(profile);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarılı! Hoş geldiniz!'), duration: Duration(seconds: 3)),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Kayıt yapılamadı')),
        );
      }
    } catch (e) {
      log('Kayıt hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt yapılamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper method to submit form when Enter is pressed on password field
  void _submitForm() {
    // Clear focus from all text fields
    _firstNameFocusNode.unfocus();
    _lastNameFocusNode.unfocus();
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();

    if (_isRegistering) {
      _signUp();
    } else {
      _signIn();
    }
  }

  // Social login methods - disabled for now since backend doesn't support them yet
  Future<void> _signInWithGoogle() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google ile giriş henüz desteklenmiyor')),
    );
  }

  Future<void> _signInWithFacebook() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facebook ile giriş henüz desteklenmiyor')),
    );
  }

  Future<void> _signInWithApple() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple ile giriş henüz desteklenmiyor')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Vestiyer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Stack(
        children: [
          // Static background matching home screen
          CustomPaint(
            size: Size(size.width, size.height),
            painter: BackgroundPainter(),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Hoş Geldiniz',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isRegistering
                            ? 'Yeni hesap oluşturun'
                            : 'Hesabınıza giriş yapın',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_isRegistering) ...[
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'Ad',
                          focusNode: _firstNameFocusNode,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) =>
                              _lastNameFocusNode.requestFocus(),
                          validator: (value) {
                            if (_isRegistering &&
                                (value == null || value.isEmpty)) {
                              return 'Lütfen adınızı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Soyad',
                          focusNode: _lastNameFocusNode,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) =>
                              _emailFocusNode.requestFocus(),
                          validator: (value) {
                            if (_isRegistering &&
                                (value == null || value.isEmpty)) {
                              return 'Lütfen soyadınızı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildTextField(
                        controller: _emailController,
                        label: 'E-posta',
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: _isRegistering
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: _isRegistering
                            ? (_) => _passwordFocusNode.requestFocus()
                            : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen e-posta adresinizi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Şifre',
                        focusNode: _passwordFocusNode,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitForm(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifrenizi girin';
                          }
                          if (_isRegistering && value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _isRegistering
                                  ? _signUp
                                  : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            shadowColor: Colors.transparent,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  _isRegistering ? 'Kayıt Ol' : 'Giriş Yap',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isRegistering
                                ? 'Zaten hesabınız var mı? '
                                : 'Hesabınız yok mu? ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Clear focus from all text fields
                              _firstNameFocusNode.unfocus();
                              _lastNameFocusNode.unfocus();
                              _emailFocusNode.unfocus();
                              _passwordFocusNode.unfocus();

                              setState(() {
                                _isRegistering = !_isRegistering;
                                _formKey.currentState?.reset();
                                _emailController.clear();
                                _passwordController.clear();
                                _firstNameController.clear();
                                _lastNameController.clear();
                              });
                            },
                            child: Text(
                              _isRegistering ? 'Giriş Yap' : 'Kayıt Ol',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'veya',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildSocialButton(
                        label: 'Google ile devam et',
                        onTap: _signInWithGoogle,
                        enabled: false, // Disabled for now
                      ),
                      const SizedBox(height: 16),
                      _buildSocialButton(
                        label: 'Facebook ile devam et',
                        onTap: _signInWithFacebook,
                        enabled: false, // Disabled for now
                      ),
                      const SizedBox(height: 16),
                      _buildSocialButton(
                        label: 'Apple ile devam et',
                        onTap: _signInWithApple,
                        enabled: false, // Disabled for now
                      ),
                      const SizedBox(height: 40),
                      // Legal links
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Kayıt olarak ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Gizlilik Politikası',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            ' ve ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TermsOfServiceScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Kullanım Şartları',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            "'nı kabul etmiş olursunuz.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    TextCapitalization? textCapitalization,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      style: const TextStyle(color: Colors.white),
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: enabled ? 0.05 : 0.02),
          foregroundColor:
              enabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withValues(alpha: enabled ? 0.1 : 0.05),
              width: 1,
            ),
          ),
          shadowColor: Colors.transparent,
        ),
        child: _isSocialLoading && enabled
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
                ),
              ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw dark background matching home screen
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

    // Draw static gradient shapes matching home screen
    final shapePaint = Paint()..style = PaintingStyle.fill;

    // First blob
    shapePaint.color = Colors.white.withValues(alpha: 0.03);
    final path1 = Path();
    final centerX1 = size.width * 0.2;
    final centerY1 = size.height * 0.2;
    final radius1 = size.width * 0.5;
    path1.addOval(
        Rect.fromCircle(center: Offset(centerX1, centerY1), radius: radius1));
    canvas.drawPath(path1, shapePaint);

    // Second blob
    shapePaint.color = Colors.white.withValues(alpha: 0.02);
    final path2 = Path();
    final centerX2 = size.width * 0.8;
    final centerY2 = size.height * 0.5;
    final radius2 = size.width * 0.4;
    path2.addOval(
        Rect.fromCircle(center: Offset(centerX2, centerY2), radius: radius2));
    canvas.drawPath(path2, shapePaint);

    // Third blob
    shapePaint.color = Colors.white.withValues(alpha: 0.01);
    final path3 = Path();
    final centerX3 = size.width * 0.5;
    final centerY3 = size.height * 0.8;
    final radius3 = size.width * 0.6;
    path3.addOval(
        Rect.fromCircle(center: Offset(centerX3, centerY3), radius: radius3));
    canvas.drawPath(path3, shapePaint);

    // Draw subtle grid pattern matching home screen
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
  bool shouldRepaint(BackgroundPainter oldDelegate) => false;
}
