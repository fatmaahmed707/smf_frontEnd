import 'package:flutter/material.dart';
import '../localization/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  String currentLanguage = 'ar';

  void setLanguage(String languageCode) {
    if (languageCode != 'ar' && languageCode != 'en') return;
    if (currentLanguage == languageCode) return;
    currentLanguage = languageCode;
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
