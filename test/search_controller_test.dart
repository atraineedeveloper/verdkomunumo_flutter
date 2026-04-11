import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/features/search/application/search_controller.dart';
import 'package:verdkomunumo_flutter/features/search/domain/search_repository.dart';
import 'package:verdkomunumo_flutter/models/post.dart';
import 'package:verdkomunumo_flutter/models/profile.dart';

void main() {
  group('SearchController', () {
    test('search with empty query resets to initial state', () async {
      final controller = SearchController(_FakeSearchRepository());

      await controller.search('');

      expect(controller.state.query, isEmpty);
      expect(controller.state.posts, isEmpty);
      expect(controller.state.users, isEmpty);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
    });

    test('search with < 2 chars sets query but does not search', () async {
      final repository = _FakeSearchRepository();
      final controller = SearchController(repository);

      await controller.search('a');

      expect(controller.state.query, 'a');
      expect(controller.state.posts, isEmpty);
      expect(controller.state.users, isEmpty);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
      expect(repository.searchCalls, isEmpty);
    });

    test('search with valid query returns results', () async {
      final repository = _FakeSearchRepository(
        results: SearchResults(
          posts: [_post(id: '1')],
          users: [_profile(id: 'u1')],
        ),
      );
      final controller = SearchController(repository);

      await controller.search('esperanto');

      expect(controller.state.query, 'esperanto');
      expect(controller.state.posts, hasLength(1));
      expect(controller.state.users, hasLength(1));
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
      expect(repository.searchCalls.single, 'esperanto');
    });

    test('search fails and sets error message', () async {
      final repository = _FakeSearchRepository(shouldFail: true);
      final controller = SearchController(repository);

      await controller.search('eraro');

      expect(controller.state.query, 'eraro');
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, 'Ne eblis ŝargi la serĉrezultojn.');
      expect(repository.searchCalls.single, 'eraro');
    });

    test('clear resets to initial state', () async {
      final controller = SearchController(_FakeSearchRepository());
      await controller.search('esperanto');

      controller.clear();

      expect(controller.state.query, isEmpty);
      expect(controller.state.posts, isEmpty);
      expect(controller.state.users, isEmpty);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
    });
  });
}

class _FakeSearchRepository implements SearchRepository {
  final SearchResults? results;
  final bool shouldFail;
  final List<String> searchCalls = [];

  _FakeSearchRepository({
    this.results,
    this.shouldFail = false,
  });

  @override
  Future<SearchResults> search(String query) async {
    searchCalls.add(query);
    if (shouldFail) {
      throw Exception('Search failed');
    }
    return results ?? const SearchResults(posts: [], users: []);
  }
}

Post _post({required String id}) {
  return Post(
    id: id,
    authorId: 'author-1',
    content: 'Saluton',
    imageUrls: const [],
    likesCount: 0,
    commentsCount: 0,
    isEdited: false,
    createdAt: DateTime(2026, 1, 1),
  );
}

Profile _profile({required String id}) {
  return Profile(
    id: id,
    username: 'testuser',
    role: 'user',
    displayName: 'Test User',
    bio: '',
    avatarUrl: null,
    followersCount: 0,
    followingCount: 0,
    postsCount: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}
