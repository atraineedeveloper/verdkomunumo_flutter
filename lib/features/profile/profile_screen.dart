import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/responsive.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../widgets/user_avatar.dart';
import '../feed/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  List<Post> _posts = [];
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('username', widget.username)
          .single();

      final profile = Profile.fromJson(profileData);

      final postsData = await Supabase.instance.client
          .from('posts')
          .select('*, author:profiles!user_id(*), category:categories!category_id(name)')
          .eq('user_id', profile.id)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(30);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      bool isFollowing = false;
      if (userId != null && userId != profile.id) {
        final followData = await Supabase.instance.client
            .from('follows')
            .select('id')
            .eq('follower_id', userId)
            .eq('following_id', profile.id)
            .maybeSingle();
        isFollowing = followData != null;
      }

      setState(() {
        _profile = profile;
        _posts = postsData.map((j) => Post.fromJson(j)).toList();
        _isFollowing = isFollowing;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eraro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      context.push('/ensaluti');
      return;
    }
    if (_followLoading || _profile == null) return;
    setState(() => _followLoading = true);

    try {
      if (_isFollowing) {
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', userId)
            .eq('following_id', _profile!.id);
        setState(() => _isFollowing = false);
      } else {
        await Supabase.instance.client.from('follows').insert({
          'follower_id': userId,
          'following_id': _profile!.id,
        });
        setState(() => _isFollowing = true);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? widget.username),
        actions: [
          if (_profile != null && currentUserId == _profile!.id)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/agordoj'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profilo ne trovita'))
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: ResponsiveLayout.contentMaxWidth,
                            ),
                            child: _ProfileHeader(
                              profile: _profile!,
                              isFollowing: _isFollowing,
                              isOwnProfile: currentUserId == _profile!.id,
                              followLoading: _followLoading,
                              onFollowTap: _toggleFollow,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          8,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: ResponsiveLayout.contentMaxWidth,
                            ),
                            child: Text(
                              '${_posts.length} afiŝoj',
                              style: TextStyle(
                                color: colorScheme.onSurface.withAlpha(150),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_posts.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: ResponsiveLayout.contentMaxWidth,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Ankoraŭ ne estas afiŝoj',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: ResponsiveLayout.contentMaxWidth,
                                ),
                                child: PostCard(
                                  key: ValueKey(_posts[i].id),
                                  post: _posts[i],
                                ),
                              ),
                            ),
                          ),
                          childCount: _posts.length,
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Profile profile;
  final bool isFollowing;
  final bool isOwnProfile;
  final bool followLoading;
  final VoidCallback onFollowTap;

  const _ProfileHeader({
    required this.profile,
    required this.isFollowing,
    required this.isOwnProfile,
    required this.followLoading,
    required this.onFollowTap,
  });

  String get _levelLabel {
    switch (profile.esperantoLevel) {
      case 'progresanto':
        return '🌿 Progresanto';
      case 'flua':
        return '🌳 Flua';
      default:
        return '🌱 Komencanto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                avatarUrl: profile.avatarUrl,
                username: profile.username,
                radius: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  runAlignment: WrapAlignment.center,
                  children: [
                    if (!isOwnProfile)
                      OutlinedButton(
                        onPressed: followLoading ? null : onFollowTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFollowing
                              ? colorScheme.onSurface
                              : colorScheme.primary,
                          side: BorderSide(
                            color: isFollowing
                                ? colorScheme.outline
                                : colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: followLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isFollowing ? 'Malsekvata' : 'Sekvu'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '@${profile.username}',
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(150),
              fontSize: 14,
            ),
          ),
          if (profile.bio?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(profile.bio!, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
          const SizedBox(height: 10),
          Chip(
            label: Text(_levelLabel, style: const TextStyle(fontSize: 12)),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _StatItem(count: profile.followingCount, label: 'Sekvitaj'),
              _StatItem(count: profile.followersCount, label: 'Sekvantoj'),
              _StatItem(count: profile.postsCount, label: 'Afiŝoj'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ],
    );
  }
}
