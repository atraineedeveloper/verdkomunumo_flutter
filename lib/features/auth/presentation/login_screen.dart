import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../core/responsive.dart';
import '../../../widgets/esperanto_star.dart';
import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authActionControllerProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
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

  Widget _buildBrandPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withAlpha(60)),
          ),
          child: EsperantoStar(size: 44, color: colorScheme.primary),
        ),
        const SizedBox(height: 20),
        Text(
          'Verdkomunumo',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'La Verda Komunumo',
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Retpoŝtadreso',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enigu vian retpoŝtadreson';
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
                  if (value == null || value.isEmpty) {
                    return 'Enigu vian pasvorton';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _signIn,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Ensalutu'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Ankoraŭ ne havas konton? ',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text('Registriĝu'),
            ),
          ],
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.feed),
          child: Text(
            'Daŭrigu sen konto',
            style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
          ),
        ),
      ],
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
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withAlpha(22),
                colorScheme.surface,
                colorScheme.surfaceContainerHighest.withAlpha(210),
              ],
            ),
          ),
          child: Center(
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
                              Expanded(child: _buildBrandPanel(context)),
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
                              _buildBrandPanel(context),
                              const SizedBox(height: 40),
                              _buildFormPanel(context, isLoading),
                            ],
                          ),
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
