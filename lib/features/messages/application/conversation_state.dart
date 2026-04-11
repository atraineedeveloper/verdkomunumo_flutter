import '../domain/conversation.dart';

class ConversationState {
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final ConversationThread? conversation;

  const ConversationState({
    required this.isLoading,
    required this.isSending,
    required this.conversation,
    this.errorMessage,
  });

  factory ConversationState.initial() => const ConversationState(
    isLoading: false,
    isSending: false,
    conversation: null,
  );

  ConversationState copyWith({
    bool? isLoading,
    bool? isSending,
    ConversationThread? conversation,
    String? errorMessage,
  }) {
    return ConversationState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      conversation: conversation ?? this.conversation,
      errorMessage: errorMessage,
    );
  }
}
