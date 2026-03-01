import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  bool _isEnglish = true;

  bool get isEnglish => _isEnglish;

  void setLanguage(bool isEnglish) {
    _isEnglish = isEnglish;
    notifyListeners();
  }

  void setEnglish() {
    _isEnglish = true;
    notifyListeners();
  }

  void setVietnamese() {
    _isEnglish = false;
    notifyListeners();
  }

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }
}
