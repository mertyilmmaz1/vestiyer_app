import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vestiyer_nodejs/core/product/extensions/context_extension.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_card.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_divider.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_primary_button.dart';
import 'package:vestiyer_nodejs/core/product/widget/design/vestiyer_text_field.dart';

import '../models/user.dart' as app_user;
import '../providers/subscription_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service_base.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_of_service_screen.dart';

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

  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isRegistering = false;

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
    setState(() => _isLoading = true);
    try {
      final authService = context.read<FirebaseAuthService>();
      final firestore = context.read<FirestoreServiceBase>();
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      final uid = authService.currentUserId;
      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giriş yapılamadı.')),
          );
        }
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
      // AuthWrapper StreamBuilder auth state ile _AuthenticatedHome (bottom nav) gösterecek
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
    setState(() => _isLoading = true);
    try {
      final authService = context.read<FirebaseAuthService>();
      final firestore = context.read<FirestoreServiceBase>();
      await authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      final uid = authService.currentUserId;
      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt yapılamadı.')),
          );
        }
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
      // AuthWrapper StreamBuilder auth state ile _AuthenticatedHome (bottom nav) gösterecek
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Hoş geldiniz!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
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

  void _submitForm() {
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

  void _toggleRegister() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: context.paddingHorizontalDefault +
                  EdgeInsets.only(top: context.dynamicHeight(0.03)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Vestiyer',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  SizedBox(height: context.dynamicHeight(0.018)),
                  Center(
                    child: Text(
                      'Kıyafet dolabınızı yapay zeka ile yönetin.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary
                                .withValues(alpha: 0.4),
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                  SizedBox(height: context.dynamicHeight(0.04)),
                  VestiyerCard(
                    hasGlow: true,
                    padding: context.paddingHorizontalDefault +
                        (context.paddingVerticalDefault * 1.5),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRegistering ? 'Kayıt Ol' : 'Giriş Yap',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isRegistering
                                ? 'Yeni hesap oluşturun.'
                                : 'E-posta ile hızlıca başla.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.45),
                                      fontWeight: FontWeight.w400,
                                    ),
                          ),
                          const SizedBox(height: 18),
                          if (_isRegistering) ...[
                            VestiyerTextField(
                              controller: _firstNameController,
                              label: 'Ad',
                              focusNode: _firstNameFocusNode,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              onFieldSubmitted: (_) =>
                                  _lastNameFocusNode.requestFocus(),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Lütfen adınızı girin' : null,
                            ),
                            const SizedBox(height: 16),
                            VestiyerTextField(
                              controller: _lastNameController,
                              label: 'Soyad',
                              focusNode: _lastNameFocusNode,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              onFieldSubmitted: (_) =>
                                  _emailFocusNode.requestFocus(),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Lütfen soyadınızı girin' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          VestiyerTextField(
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
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Lütfen e-posta adresinizi girin' : null,
                          ),
                          const SizedBox(height: 16),
                          VestiyerTextField(
                            controller: _passwordController,
                            label: 'Şifre',
                            focusNode: _passwordFocusNode,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitForm(),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Lütfen şifrenizi girin';
                              }
                              if (_isRegistering && v.length < 6) {
                                return 'Şifre en az 6 karakter olmalıdır';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          VestiyerPrimaryButton(
                            text: _isRegistering ? 'Kayıt Ol' : 'Giriş Yap',
                            isLoading: _isLoading,
                            enabled: !_isLoading,
                            onTap: _isRegistering ? _signUp : _signIn,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.dynamicHeight(0.03)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegistering ? 'Zaten hesabınız var mı? ' : 'Hesabınız yok mu? ',
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleRegister,
                        child: Text(
                          _isRegistering ? 'Giriş Yap' : 'Kayıt Ol',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dynamicHeight(0.025)),
                  const VestiyerDivider(),
                  SizedBox(height: context.dynamicHeight(0.025)),
                  _buildSocialButton(
                    label: 'Google ile devam et',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google ile giriş henüz desteklenmiyor')),
                    ),
                    enabled: false,
                    icon: Icons.g_mobiledata,
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButton(
                    label: 'Apple ile devam et',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Apple ile giriş henüz desteklenmiyor')),
                    ),
                    enabled: false,
                    icon: Icons.apple,
                  ),
                  SizedBox(height: context.dynamicHeight(0.035)),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Gizlilik Politikası',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary.withValues(alpha: 0.35),
                          decoration: TextDecoration.underline,
                          decorationColor:
                              AppColors.textPrimary.withValues(alpha: 0.2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Kullanım Şartları',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary.withValues(alpha: 0.35),
                          decoration: TextDecoration.underline,
                          decorationColor:
                              AppColors.textPrimary.withValues(alpha: 0.2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.dynamicHeight(0.03)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
