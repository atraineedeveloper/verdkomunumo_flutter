class PostInteractionState {
  final int likesCount;
  final bool isLiked;
  final bool isLoading;

  const PostInteractionState({
    required this.likesCount,
    required this.isLiked,
    required this.isLoading,
  });

  factory PostInteractionState.initial(int likesCount) {
    return PostInteractionState(
      likesCount: likesCount,
      isLiked: false,
      isLoading: false,
    );
  }

  PostInteractionState copyWith({
    int? likesCount,
    bool? isLiked,
    bool? isLoading,
  }) {
    return PostInteractionState(
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
