import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.kenea; // Default to KENEA

  AppThemeType get currentTheme => _currentTheme;

  void toggleTheme() {
    _currentTheme = _currentTheme == AppThemeType.inventory 
        ? AppThemeType.kenea 
        : AppThemeType.inventory;
    notifyListeners();
  }

  void setTheme(AppThemeType type) {
    _currentTheme = type;
    notifyListeners();
  }
}
