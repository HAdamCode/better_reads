import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shelf_theme.dart';

class ShelfThemeProvider extends ChangeNotifier {
  static const _storageKey = 'shelf_theme';

  ShelfThemeType _currentThemeType = ShelfThemeType.classicWood;
  bool _isLoaded = false;

  ShelfThemeType get currentThemeType => _currentThemeType;
  ShelfTheme get theme => ShelfTheme.fromType(_currentThemeType);
  bool get isLoaded => _isLoaded;

  ShelfThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_storageKey);
      if (themeString != null) {
        _currentThemeType = ShelfThemeType.values.firstWhere(
          (t) => t.name == themeString,
          orElse: () => ShelfThemeType.classicWood,
        );
      }
    } catch (e) {
      debugPrint('Error loading shelf theme: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setTheme(ShelfThemeType type) async {
    if (_currentThemeType == type) return;

    _currentThemeType = type;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, type.name);
    } catch (e) {
      debugPrint('Error saving shelf theme: $e');
    }
  }

  void cycleTheme() {
    final currentIndex = ShelfThemeType.values.indexOf(_currentThemeType);
    final nextIndex = (currentIndex + 1) % ShelfThemeType.values.length;
    setTheme(ShelfThemeType.values[nextIndex]);
  }
}
