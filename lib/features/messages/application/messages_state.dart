import '../../../models/profile.dart';
import '../domain/conversation.dart';

class MessagesState {
  final bool isLoading;
  final bool isSearching;
  final bool isStarting;
  final String? errorMessage;
  final String searchQuery;
  final List<ConversationSummary> conversations;
  final List<Profile> searchResults;

  const MessagesState({
    required this.isLoading,
    required this.isSearching,
    required this.isStarting,
    required this.conversations,
    required this.searchResults,
    required this.searchQuery,
    this.errorMessage,
  });

  factory MessagesState.initial() => const MessagesState(
    isLoading: false,
    isSearching: false,
    isStarting: false,
    conversations: [],
    searchResults: [],
    searchQuery: '',
  );

  MessagesState copyWith({
    bool? isLoading,
    bool? isSearching,
    bool? isStarting,
    String? errorMessage,
    String? searchQuery,
    List<ConversationSummary>? conversations,
    List<Profile>? searchResults,
  }) {
    return MessagesState(
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isStarting: isStarting ?? this.isStarting,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      conversations: conversations ?? this.conversations,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}
