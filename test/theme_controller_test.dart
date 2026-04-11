import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdkomunumo_flutter/core/theme_controller.dart';

void main() {
  group('AppThemeController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('load() returns system theme when no value is stored', () async {
      final controller = await AppThemeController.load();

      expect(controller.themeMode, ThemeMode.system);
      expect(controller.preference, AppThemePreference.system);
    });

    test('load() returns light theme when "light" is stored', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final controller = await AppThemeController.load();

      expect(controller.themeMode, ThemeMode.light);
      expect(controller.preference, AppThemePreference.light);
    });

    test('load() returns dark theme when "dark" is stored', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final controller = await AppThemeController.load();

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.preference, AppThemePreference.dark);
    });

    test('load() returns system theme when invalid value is stored', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
      final controller = await AppThemeController.load();

      expect(controller.themeMode, ThemeMode.system);
      expect(controller.preference, AppThemePreference.system);
    });

    test('updatePreference() updates theme mode, notifies listeners, and saves to SharedPreferences', () async {
      final controller = await AppThemeController.load();
      var notifyCount = 0;
      controller.addListener(() {
        notifyCount++;
      });

      await controller.updatePreference(AppThemePreference.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.preference, AppThemePreference.dark);
      expect(notifyCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('updatePreference() does not notify listeners or update storage if preference is the same', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final controller = await AppThemeController.load();
      var notifyCount = 0;
      controller.addListener(() {
        notifyCount++;
      });

      await controller.updatePreference(AppThemePreference.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.preference, AppThemePreference.dark);
      expect(notifyCount, 0);
    });
  });
}
