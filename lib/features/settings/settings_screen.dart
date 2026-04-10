import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_routes.dart';
import '../../core/error/app_failure.dart';
import '../../core/notifications/notification_permission_status.dart';
import '../../core/responsive.dart';
import '../../core/theme_controller.dart';
import '../../models/profile.dart';
import '../../widgets/user_avatar.dart';
import '../auth/application/auth_providers.dart';
import '../auth/domain/auth_failure.dart';
import '../notifications/application/notification_preferences_providers.dart';
import '../notifications/application/notification_preferences_state.dart';
import 'application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final userEmail = ref.watch(currentUserEmailProvider);
    final state = ref.watch(settingsControllerProvider);
    final notificationState = ref.watch(
      notificationPreferencesControllerProvider,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final themeController = ThemeControllerScope.of(context);
    final themePreference = themeController.preference;

    Future<void> signOut() async {
      try {
        await ref.read(authActionControllerProvider.notifier).signOut();
        if (context.mounted) context.go(AppRoutes.feed);
      } on AuthFailure catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    Future<void> openEditProfile(Profile profile) async {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agordoj')),
      body: userId == null
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
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Ensalutu'),
                    ),
                  ],
                ),
              ),
            )
          : state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ResponsiveLayout.contentMaxWidth,
                ),
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  children: [
                    if (state.profile != null)
                      InkWell(
                        onTap: () => openEditProfile(state.profile!),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              UserAvatar(
                                avatarUrl: state.profile!.avatarUrl,
                                username: state.profile!.username,
                                radius: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.profile!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      '@${state.profile!.username}',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withAlpha(
                                          150,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userEmail ?? '',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withAlpha(
                                          120,
                                        ),
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
                      onTap: state.profile == null
                          ? null
                          : () => openEditProfile(state.profile!),
                    ),
                    ListTile(
                      leading: const Icon(Icons.visibility_outlined),
                      title: const Text('Vidi mian profilon'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: state.profile == null
                          ? null
                          : () => context.go(
                              '${AppRoutes.profilePrefix}/${state.profile!.username}',
                            ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Etoso'),
                      subtitle: const Text(
                        'Elektu luman, malluman aŭ sisteman etoson',
                      ),
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
                    _NotificationSettingsSection(state: notificationState),
                    if (notificationState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          notificationState.errorMessage!,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
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
                      onTap: signOut,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _NotificationSettingsSection extends ConsumerWidget {
  final NotificationPreferencesState state;

  const _NotificationSettingsSection({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      notificationPreferencesControllerProvider.notifier,
    );
    final isDenied =
        state.permissionStatus == NotificationPermissionStatus.denied;
    final isUndetermined =
        state.permissionStatus == NotificationPermissionStatus.notDetermined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.notifications_active_outlined),
          title: const Text('Moveblaj sciigoj'),
          subtitle: Text(_statusMessage(state)),
          value: state.preferences.enabled,
          onChanged: state.isLoading || state.isSaving
              ? null
              : (value) => controller.toggleNotifications(value),
        ),
        if (state.notificationsAvailable && (isDenied || isUndetermined))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: state.isSaving
                    ? null
                    : () => controller.openSystemSettings(),
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('Malfermi sistemajn agordojn'),
              ),
            ),
          ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.favorite_border),
          title: const Text('Ŝatoj'),
          subtitle: const Text('Sciigoj kiam iu ŝatas vian enhavon'),
          value: state.preferences.likesEnabled,
          onChanged: state.canManageChannels && !state.isSaving
              ? (value) => controller.updateChannels(likesEnabled: value)
              : null,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.chat_bubble_outline),
          title: const Text('Komentoj'),
          subtitle: const Text('Sciigoj pri novaj komentoj'),
          value: state.preferences.commentsEnabled,
          onChanged: state.canManageChannels && !state.isSaving
              ? (value) => controller.updateChannels(commentsEnabled: value)
              : null,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.person_add_alt_outlined),
          title: const Text('Novaj sekvantoj'),
          subtitle: const Text('Sciigoj kiam iu eksekvas vin'),
          value: state.preferences.followsEnabled,
          onChanged: state.canManageChannels && !state.isSaving
              ? (value) => controller.updateChannels(followsEnabled: value)
              : null,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.alternate_email),
          title: const Text('Mencioj'),
          subtitle: const Text('Sciigoj kiam iu mencias vin'),
          value: state.preferences.mentionsEnabled,
          onChanged: state.canManageChannels && !state.isSaving
              ? (value) => controller.updateChannels(mentionsEnabled: value)
              : null,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.mail_outline),
          title: const Text('Mesaĝoj'),
          subtitle: const Text('Sciigoj pri novaj privataj mesaĝoj'),
          value: state.preferences.messagesEnabled,
          onChanged: state.canManageChannels && !state.isSaving
              ? (value) => controller.updateChannels(messagesEnabled: value)
              : null,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.check_circle_outline),
          title: const Text('Aprobitaj kategorioj'),
          subtitle: const Text(
            'Sciigoj kiam proponita kategorio estas aprobita',
          ),
          value: state.preferences.categoryApprovedEnabled,
          onChanged: state.canManageChannels && !state.isSaving
              ? (value) =>
                    controller.updateChannels(categoryApprovedEnabled: value)
              : null,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.cancel_outlined),
          title: const Text('Malakceptitaj kategorioj'),
          subtitle: const Text(
            'Sciigoj kiam proponita kategorio estas malakceptita',
          ),
          value: state.preferences.categoryRejectedEnabled,
          onChanged: state.canManageChannels && !state.isSaving
              ? (value) =>
                    controller.updateChannels(categoryRejectedEnabled: value)
              : null,
        ),
      ],
    );
  }

  String _statusMessage(NotificationPreferencesState state) {
    switch (state.permissionStatus) {
      case NotificationPermissionStatus.granted:
        return 'Aktivaj sur ĉi tiu aparato';
      case NotificationPermissionStatus.denied:
        return 'La sistemo blokas sciigojn. Vi povas reŝalti ilin en la aparato.';
      case NotificationPermissionStatus.notDetermined:
        return 'La aplikaĵo ankoraŭ ne petis permeson por sciigoj.';
      case NotificationPermissionStatus.unsupported:
        return 'Ĉi tiu kontrolo funkcias en Android kaj iPhone.';
    }
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  final Profile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late String _esperantoLevel;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _displayNameController = TextEditingController(
      text: profile.displayName ?? '',
    );
    _bioController = TextEditingController(text: profile.bio ?? '');
    _esperantoLevel = profile.esperantoLevel ?? 'komencanto';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .saveProfile(
            profile: widget.profile,
            displayName: _displayNameController.text,
            bio: _bioController.text,
            esperantoLevel: _esperantoLevel,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilo ĝisdatigita!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.of(context).pop();
    } on AppFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(settingsControllerProvider).isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redakti Profilon'),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
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
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(40),
                    child: Text(
                      widget.profile.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  onChanged: (value) =>
                      setState(() => _esperantoLevel = value!),
                  child: Column(
                    children: const [
                      RadioListTile<String>(
                        value: 'komencanto',
                        title: Text('Komencanto'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        value: 'progresanto',
                        title: Text('Progresanto'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        value: 'flua',
                        title: Text('Flua'),
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
