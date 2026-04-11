import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../core/constants.dart';
import '../../../core/responsive.dart';
import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _esperantoLevel = 'komencanto';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final normalizedUsername = _usernameController.text.trim().toLowerCase();

    try {
      await ref
          .read(authActionControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            username: normalizedUsername,
            esperantoLevel: _esperantoLevel,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konto kreita sukcese!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      context.go(AppRoutes.feed);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await ref
          .read(authActionControllerProvider.notifier)
          .signInWithGoogle(redirectUrl: AppConstants.supabaseAuthRedirectUrl);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildIntroPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Kreu vian konton',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Aliĝu al la verda komunumo',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel(BuildContext context, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Salutnomo',
              prefixIcon: Icon(Icons.alternate_email),
              hintText: 'ekzemple: johano',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enigu salutnomon';
              }
              if (value.length < 3) {
                return 'Almenaŭ 3 signoj';
              }
              if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value.toLowerCase())) {
                return 'Nur literoj, ciferoj kaj _';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Retpoŝtadreso',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enigu retpoŝtadreson';
              }
              if (!value.contains('@')) {
                return 'Nevalida retpoŝtadreso';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Pasvorto',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Almenaŭ 6 signoj';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Via Esperanto-nivelo',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _esperantoLevel,
                onChanged: (value) {
                  setState(() => _esperantoLevel = value!);
                },
                child: Column(
                  children: const [
                    RadioListTile<String>(
                      value: 'komencanto',
                      title: Text('Komencanto (Beginners)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      value: 'progresanto',
                      title: Text('Progresanto (Intermediate)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      value: 'flua',
                      title: Text('Flua (Fluent)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _signUp,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(color: Colors.black),
                    )
                  : const Text('Kreu Konton'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Daŭrigi per Google'),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                'Jam havas konton? ',
                style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Ensalutu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authActionControllerProvider).isLoading;
    final isWideLandscape =
        ResponsiveLayout.isLandscape(context) &&
        MediaQuery.sizeOf(context).width >= 700;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: const Text('Nova Konto'),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withAlpha(18),
                colorScheme.surface,
                colorScheme.surfaceContainerHighest.withAlpha(210),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveLayout.horizontalPadding(context),
            ),
            child: ResponsiveContent(
              maxWidth: ResponsiveLayout.formMaxWidth,
              padding: EdgeInsets.zero,
              alignment: Alignment.center,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: isWideLandscape
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildIntroPanel(context)),
                            const SizedBox(width: 24),
                            VerticalDivider(
                              color: colorScheme.outline,
                              thickness: 1,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _buildFormPanel(context, isLoading),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildIntroPanel(context),
                            const SizedBox(height: 32),
                            _buildFormPanel(context, isLoading),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
