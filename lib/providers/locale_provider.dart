import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';

  Locale _locale;

  LocaleProvider({Locale? initialLocale})
      : _locale = initialLocale ?? _deviceLocale();

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  static const supportedLocales = [
    Locale('tr'),
    Locale('en'),
  ];

  static Locale _deviceLocale() {
    final code = Platform.localeName.split('_').first;
    if (supportedLocales.any((l) => l.languageCode == code)) {
      return Locale(code);
    }
    return const Locale('en');
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null &&
        supportedLocales.any((l) => l.languageCode == saved)) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
