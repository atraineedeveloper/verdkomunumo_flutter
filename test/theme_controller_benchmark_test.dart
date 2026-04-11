import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdkomunumo_flutter/core/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Benchmark updatePreference', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final controller = await AppThemeController.load();

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      await controller.updatePreference(
        i % 2 == 0 ? AppThemePreference.dark : AppThemePreference.light,
      );
    }
    stopwatch.stop();

    print('Time taken: ${stopwatch.elapsedMilliseconds} ms');
  });
}
