import 'package:firebase_auth/firebase_auth.dart';

/// Hata mesajlarını kullanıcı dostu Türkçe mesajlara çeviren yardımcı sınıf.
class ErrorMessageHelper {
  /// Teknik hata mesajını kullanıcı dostu Türkçe mesaja çevirir.
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Null type errors
    if (errorString.contains('null') && errorString.contains('subtype')) {
      return 'Profil bilgileriniz eksik. Lütfen tekrar giriş yapın.';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }

    // Firestore/Database errors
    if (errorString.contains('firestore') ||
        errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Veri tabanı hatası. Lütfen daha sonra tekrar deneyin.';
    }

    // Firebase Auth errors (fallback for uncaught codes)
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthMessage(error);
    }

    // Image/File errors
    if (errorString.contains('image') || errorString.contains('file')) {
      return 'Dosya yüklenirken bir hata oluştu. Lütfen tekrar deneyin.';
    }

    // Generic server errors
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
    }

    // Default fallback
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  /// Firebase Auth hatalarını Türkçe mesajlara çevirir.
  static String _getFirebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Kimlik doğrulama hatası. Lütfen tekrar deneyin.';
    }
  }
}
