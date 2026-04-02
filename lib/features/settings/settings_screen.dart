import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/responsive.dart';
import '../../core/theme_controller.dart';
import '../../models/profile.dart';
import '../../widgets/user_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Profile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      setState(() {
        _profile = Profile.fromJson(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/fonto');
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final themeController = ThemeControllerScope.of(context);
    final themePreference = themeController.preference;

    return Scaffold(
      appBar: AppBar(title: const Text('Agordoj')),
      body: user == null
          ? Center(
              child: ResponsiveContent(
                maxWidth: ResponsiveLayout.formMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Vi ne estas ensalutinta'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/ensaluti'),
                      child: const Text('Ensalutu'),
                    ),
                  ],
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ResponsiveLayout.contentMaxWidth,
                    ),
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      children: [
                    // Profile card
                    if (_profile != null)
                      InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(profile: _profile!),
                            ),
                          );
                          _loadProfile();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              UserAvatar(
                                avatarUrl: _profile!.avatarUrl,
                                username: _profile!.username,
                                radius: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _profile!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      '@${_profile!.username}',
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withAlpha(150),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email ?? '',
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withAlpha(120),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.edit_outlined,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Redakti profilon'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        if (_profile == null) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditProfileScreen(profile: _profile!),
                          ),
                        );
                        _loadProfile();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.visibility_outlined),
                      title: const Text('Vidi mian profilon'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        if (_profile != null) {
                          context.go('/profilo/${_profile!.username}');
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Etoso'),
                      subtitle: const Text('Elektu luman, malluman aŭ sisteman etoson'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: SegmentedButton<AppThemePreference>(
                        showSelectedIcon: false,
                        multiSelectionEnabled: false,
                        emptySelectionAllowed: false,
                        segments: const [
                          ButtonSegment<AppThemePreference>(
                            value: AppThemePreference.system,
                            icon: Icon(Icons.brightness_auto_outlined),
                            label: Text('Sistemo'),
                          ),
                          ButtonSegment<AppThemePreference>(
                            value: AppThemePreference.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Luma'),
                          ),
                          ButtonSegment<AppThemePreference>(
                            value: AppThemePreference.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Malluma'),
                          ),
                        ],
                        selected: <AppThemePreference>{themePreference},
                        onSelectionChanged: (selection) {
                          final nextPreference = selection.first;
                          themeController.updatePreference(nextPreference);
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Elsalutu',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onTap: _signOut,
                    ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ──────────────────────────────────────────────
// Edit Profile Screen
// ──────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  final Profile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late String _esperantoLevel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _displayNameController =
        TextEditingController(text: p.displayName ?? '');
    _bioController = TextEditingController(text: p.bio ?? '');
    _esperantoLevel = p.esperantoLevel ?? 'komencanto';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'display_name': _displayNameController.text.trim(),
            'bio': _bioController.text.trim(),
            'esperanto_level': _esperantoLevel,
          })
          .eq('id', widget.profile.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilo ĝisdatigita!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eraro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redakti Profilon'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Konservi'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
        child: ResponsiveContent(
          maxWidth: ResponsiveLayout.formMaxWidth,
          padding: EdgeInsets.zero,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(40),
                        child: Text(
                          widget.profile.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            color:
                                Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Montrata nomo',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Biografio',
                    prefixIcon: Icon(Icons.info_outline),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 200,
                ),
                const SizedBox(height: 8),
                Text(
                  'Via Esperanto-nivelo',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _esperantoLevel,
                  onChanged: (v) =>
                      setState(() => _esperantoLevel = v!),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'komencanto',
                        title: const Text('🌱 Komencanto'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        value: 'progresanto',
                        title: const Text('🌿 Progresanto'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        value: 'flua',
                        title: const Text('🌳 Flua'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
