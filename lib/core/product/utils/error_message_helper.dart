import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Hata mesajlarını kullanıcı dostu yerelleştirilmiş mesajlara çevirir.
class ErrorMessageHelper {
  /// Teknik hata mesajını kullanıcı dostu mesaja çevirir.
  static String getUserFriendlyMessage(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context);
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('null') && errorString.contains('subtype')) {
      return l10n.errorProfileMissing;
    }
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return l10n.errorNoInternet;
    }
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return l10n.errorTimeout;
    }
    if (errorString.contains('firestore') ||
        errorString.contains('permission') ||
        errorString.contains('denied')) {
      return l10n.errorDatabase;
    }
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthMessage(context, error);
    }
    if (errorString.contains('image') || errorString.contains('file')) {
      return l10n.errorFileUpload;
    }
    if (errorString.contains('server') || errorString.contains('500')) {
      return l10n.errorServer;
    }
    return l10n.errorGeneric;
  }

  static String _getFirebaseAuthMessage(
      BuildContext context, FirebaseAuthException error) {
    final l10n = AppLocalizations.of(context);
    switch (error.code) {
      case 'user-not-found':
        return l10n.errorUserNotFound;
      case 'wrong-password':
        return l10n.errorWrongPassword;
      case 'invalid-email':
        return l10n.errorInvalidEmail;
      case 'user-disabled':
        return l10n.errorUserDisabled;
      case 'email-already-in-use':
        return l10n.errorEmailInUse;
      case 'weak-password':
        return l10n.errorWeakPassword;
      case 'network-request-failed':
        return l10n.errorNoInternet;
      default:
        return l10n.errorAuthDefault;
    }
  }
}
