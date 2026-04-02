import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

class AppThemeController extends ChangeNotifier {
  static const String _preferenceKey = 'theme_mode';

  AppThemeController._(this._themeMode);

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  AppThemePreference get preference {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppThemePreference.light;
      case ThemeMode.dark:
        return AppThemePreference.dark;
      case ThemeMode.system:
        return AppThemePreference.system;
    }
  }

  static Future<AppThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_preferenceKey);
    return AppThemeController._(_themeModeFromStorage(storedValue));
  }

  Future<void> updatePreference(AppThemePreference preference) async {
    final nextMode = _themeModeFromPreference(preference);
    if (_themeMode == nextMode) return;

    _themeMode = nextMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, preference.name);
  }

  static ThemeMode _themeModeFromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static ThemeMode _themeModeFromPreference(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }
}

class ThemeControllerScope extends InheritedNotifier<AppThemeController> {
  const ThemeControllerScope({
    super.key,
    required AppThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope not found in context');
    return scope!.notifier!;
  }
}
