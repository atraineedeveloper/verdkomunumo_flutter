import '../../../models/post.dart';
import '../../../models/profile.dart';

class SearchResults {
  final List<Post> posts;
  final List<Profile> users;

  const SearchResults({
    required this.posts,
    required this.users,
  });
}

abstract class SearchRepository {
  Future<SearchResults> search(String query);
}
