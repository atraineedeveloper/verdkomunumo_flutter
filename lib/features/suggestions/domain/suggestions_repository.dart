abstract class SuggestionsRepository {
  Future<void> submitSuggestion({
    required String title,
    required String description,
    required String context,
  });
}
