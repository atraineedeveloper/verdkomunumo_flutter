import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/core/analytics/analytics_service.dart';
import 'package:verdkomunumo_flutter/features/suggestions/application/suggestions_controller.dart';
import 'package:verdkomunumo_flutter/features/suggestions/domain/suggestions_repository.dart';

void main() {
  group('SuggestionsController', () {
    test('submitSuggestion delegates to repository', () async {
      final repository = _FakeSuggestionsRepository();
      final controller = SuggestionsController(
        repository,
        const AnalyticsService.disabled(),
      );

      await controller.submitSuggestion(
        title: 'Nova ideo',
        description: 'Detaloj pri la ideo',
        context: 'Kunteksto',
      );

      expect(repository.calls, 1);
      expect(repository.lastTitle, 'Nova ideo');
    });
  });
}

class _FakeSuggestionsRepository implements SuggestionsRepository {
  int calls = 0;
  String? lastTitle;

  @override
  Future<void> submitSuggestion({
    required String title,
    required String description,
    required String context,
  }) async {
    calls += 1;
    lastTitle = title;
  }
}
