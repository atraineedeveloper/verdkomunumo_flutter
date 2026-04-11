import '../domain/community_message.dart';

class CommunityChatState {
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final List<CommunityMessage> messages;

  const CommunityChatState({
    required this.isLoading,
    required this.isSending,
    required this.messages,
    this.errorMessage,
  });

  factory CommunityChatState.initial() => const CommunityChatState(
    isLoading: false,
    isSending: false,
    messages: [],
  );

  CommunityChatState copyWith({
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    List<CommunityMessage>? messages,
  }) {
    return CommunityChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      messages: messages ?? this.messages,
    );
  }
}
