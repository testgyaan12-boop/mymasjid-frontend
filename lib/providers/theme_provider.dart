import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _primaryHsl = '142 76% 36%';
  String _secondaryHsl = '43 76% 58%';

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  String get primaryHsl => _primaryHsl;
  String get secondaryHsl => _secondaryHsl;

  Color get primaryColor => HSLColorConverter.fromHslString(_primaryHsl);
  Color get secondaryColor => HSLColorConverter.fromHslString(_secondaryHsl);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme');
    if (saved == 'dark') _themeMode = ThemeMode.dark;
    final primary = prefs.getString('primaryHsl');
    final secondary = prefs.getString('secondaryHsl');
    if (primary != null && primary.isNotEmpty) _primaryHsl = primary;
    if (secondary != null && secondary.isNotEmpty) _secondaryHsl = secondary;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setBrandingColors(String primary, String secondary) {
    _primaryHsl = primary;
    _secondaryHsl = secondary;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString('primaryHsl', primary);
      await prefs.setString('secondaryHsl', secondary);
    });
  }
}
