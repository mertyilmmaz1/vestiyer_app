import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TutorialStep {
  welcome, // Show greeting, prompt to upload
  uploading, // User is uploading items — show encouragement
  reached5Items, // Prompt to try AI Stylist
  aiPreview, // One-time premium preview on AI Stylist screen
  completed, // Tutorial done — never show again
}

class TutorialProvider extends ChangeNotifier {
  TutorialProvider();

  TutorialStep _currentStep = TutorialStep.welcome;
  bool _isInitialized = false;
  String? _currentUserId;

  /// Tracks which step's overlay has been dismissed so we don't re-show it.
  TutorialStep? _lastDismissedStep;

  TutorialStep get currentStep => _currentStep;
  bool get isInitialized => _isInitialized;

  /// Tutorial is active if not completed AND initialized.
  bool get isActive => _isInitialized && _currentStep != TutorialStep.completed;

  /// Whether the overlay should currently be visible.
  /// True only if the tutorial is active AND the overlay for this step
  /// hasn't been dismissed yet.
  bool get shouldShowOverlay => isActive && _lastDismissedStep != _currentStep;

  /// Per-user SharedPreferences key.
  String _stepKey(String uid) => 'vestiyer_tutorial_step_$uid';

  /// Call this when a user logs in. Loads tutorial progress for that user.
  Future<void> setCurrentUserId(String? uid) async {
    _currentUserId = uid;
    if (uid == null) {
      // User logged out — reset in-memory state
      _currentStep = TutorialStep.welcome;
      _lastDismissedStep = null;
      _isInitialized = false;
      notifyListeners();
      return;
    }
    // Load the tutorial progress for this specific user
    await _loadProgress(uid);
  }

  Future<void> _loadProgress(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stepIndex = prefs.getInt(_stepKey(uid));
      if (stepIndex != null && stepIndex < TutorialStep.values.length) {
        _currentStep = TutorialStep.values[stepIndex];
      } else {
        // New user — start from welcome
        _currentStep = TutorialStep.welcome;
      }
      _lastDismissedStep = null;
    } catch (e) {
      debugPrint('Error loading tutorial progress: $e');
      _currentStep = TutorialStep.welcome;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _persistStep(TutorialStep step) async {
    final uid = _currentUserId;
    if (uid == null) return; // Can't persist without a user
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_stepKey(uid), step.index);
    } catch (e) {
      debugPrint('Error saving tutorial progress: $e');
    }
  }

  /// Advance to a specific step. Only moves forward, never backward.
  Future<void> setStep(TutorialStep step) async {
    if (step.index <= _currentStep.index) return; // Only move forward
    _currentStep = step;
    _lastDismissedStep = null; // Reset overlay visibility for new step
    notifyListeners();
    await _persistStep(step);
  }

  /// Complete the current step and advance to the next one.
  Future<void> completeStep(TutorialStep step) async {
    if (_currentStep != step) return;
    final nextIndex = step.index + 1;
    if (nextIndex < TutorialStep.values.length) {
      await setStep(TutorialStep.values[nextIndex]);
    }
  }

  /// Dismiss the current overlay without advancing the step.
  /// The overlay won't re-appear for this step until it naturally advances.
  void dismissOverlay() {
    if (!isActive) return;
    _lastDismissedStep = _currentStep;
    notifyListeners();
  }

  /// Skip the entire tutorial. Sets step to completed permanently.
  Future<void> skipTutorial() async {
    _currentStep = TutorialStep.completed;
    _lastDismissedStep = null;
    notifyListeners();
    await _persistStep(TutorialStep.completed);
  }

  /// Reset tutorial to the beginning (for debugging/testing only).
  Future<void> resetTutorial() async {
    _currentStep = TutorialStep.welcome;
    _lastDismissedStep = null;
    notifyListeners();
    await _persistStep(TutorialStep.welcome);
  }

  bool isStepActive(TutorialStep step) => _currentStep == step;
}
