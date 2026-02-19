import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Extension to easily show themed snackbars via ScaffoldMessenger.
extension ScaffoldMessengerHelper on ScaffoldMessengerState {
  /// Shows a standard info/success snackbar (black background, white text).
  void showInfo(String message) {
    showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  /// Shows an error snackbar (red background, white text).
  void showError(String message) {
    showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a success snackbar (black background, white text by default,
  /// but can be customized if needed).
  void showSuccess(String message) {
    showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
