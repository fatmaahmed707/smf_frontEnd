import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  static const _languagePreferenceKey = 'app_language';

  String currentLanguage;

  LanguageProvider._(this.currentLanguage);

  static Future<LanguageProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languagePreferenceKey);
    if (savedLanguage == 'ar' || savedLanguage == 'en') {
      return LanguageProvider._(savedLanguage!);
    }

    final deviceLanguage =
        ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    final initialLanguage = deviceLanguage == 'ar' ? 'ar' : 'en';
    return LanguageProvider._(initialLanguage);
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'ar' && languageCode != 'en') return;
    if (currentLanguage == languageCode) return;
    currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePreferenceKey, languageCode);
    notifyListeners();
  }

  void toggleLanguage() {
    setLanguage(currentLanguage == 'en' ? 'ar' : 'en');
  }

  String getText(String key) {
    return AppStrings.text[currentLanguage]?[key] ??
        AppStrings.text['en']?[key] ??
        key;
  }

  bool get isArabic => currentLanguage == 'ar';
}
