import '../../../models/comment.dart';
import '../../../models/post.dart';

class PostDetailData {
  final Post post;
  final List<Comment> comments;

  const PostDetailData({
    required this.post,
    required this.comments,
  });
}

abstract class PostDetailRepository {
  Future<PostDetailData> fetchPostDetail(String postId);

  Future<void> createComment({
    required String postId,
    required String content,
  });
}
