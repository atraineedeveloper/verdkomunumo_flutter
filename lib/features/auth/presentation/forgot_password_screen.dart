import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
import '../../../core/constants.dart';
import '../../../core/responsive.dart';
import '../../../widgets/esperanto_star.dart';
import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authActionControllerProvider.notifier)
          .sendPasswordReset(
            email: _emailController.text.trim(),
            redirectUrl: AppConstants.supabaseAuthRedirectUrl,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se konto ekzistas por tiu retpoŝto, ni sendis la ligilon.',
          ),
          backgroundColor: Color(0xFF22C55E),
        ),
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
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withAlpha(60)),
          ),
          child: EsperantoStar(size: 40, color: colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Restarigi pasvorton',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ni sendos ligilon al via retpoŝto.',
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _sendReset,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Sendi ligilon'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(
              'Reen al ensaluto',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
            ),
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
        title: const Text('Pasvorto'),
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
