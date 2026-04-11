import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verdkomunumo_flutter/features/feed/widgets/post_card.dart';
import 'package:verdkomunumo_flutter/models/post.dart';
import 'package:verdkomunumo_flutter/models/profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var initialized = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
    initialized = true;
  });

  tearDownAll(() async {
    if (initialized) {
      await Supabase.instance.dispose();
    }
  });

  testWidgets('PostCard syncs like count when the post changes', (
    tester,
  ) async {
    final author = Profile(
      id: 'user-1',
      username: 'verdulo',
      displayName: 'Verdulo',
      bio: null,
      avatarUrl: null,
      esperantoLevel: 'komencanto',
      role: 'user',
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
    );

    Post buildPost({required String id, required int likesCount}) {
      return Post(
        id: id,
        authorId: author.id,
        content: 'Saluton mondo',
        categoryId: null,
        categoryName: null,
        imageUrls: const [],
        likesCount: likesCount,
        commentsCount: 0,
        isEdited: false,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        author: author,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PostCard(post: buildPost(id: 'post-1', likesCount: 3)),
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PostCard(post: buildPost(id: 'post-2', likesCount: 8)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('8'), findsOneWidget);
    expect(find.text('3'), findsNothing);
  });
}
