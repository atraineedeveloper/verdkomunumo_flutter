import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_routes.dart';
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
      await ref.read(authActionControllerProvider.notifier).signUp(
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authActionControllerProvider).isLoading;
    final isWideLandscape = ResponsiveLayout.isLandscape(context) &&
        MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: const Text('Nova Konto'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
          child: ResponsiveContent(
            maxWidth: ResponsiveLayout.formMaxWidth,
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Flex(
                  direction: isWideLandscape ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isWideLandscape
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Kreu vian konton',
                            textAlign: isWideLandscape
                                ? TextAlign.left
                                : TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aligxu al la verda komunumo',
                            textAlign: isWideLandscape
                                ? TextAlign.left
                                : TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(150),
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isWideLandscape) ...[
                      const SizedBox(width: 24),
                      VerticalDivider(
                        color: Theme.of(context).colorScheme.outline,
                        thickness: 1,
                      ),
                      const SizedBox(width: 24),
                    ] else
                      const SizedBox(height: 32),
                    Expanded(
                      flex: isWideLandscape ? 2 : 1,
                      child: Form(
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
                                  return 'Almenau 3 signoj';
                                }
                                if (!RegExp(r'^[a-z0-9_]+$')
                                    .hasMatch(value.toLowerCase())) {
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
                                labelText: 'Retposhtadreso',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enigu retposhtadreson';
                                }
                                if (!value.contains('@')) {
                                  return 'Nevalida retposhtadreso';
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
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Almenau 6 signoj';
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
                                        title: Text(
                                          'Komencanto (Beginners)',
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      RadioListTile<String>(
                                        value: 'progresanto',
                                        title: Text(
                                          'Progresanto (Intermediate)',
                                        ),
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
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text('Kreu Konton'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text(
                                  'Jam havas konton? ',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(150),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go(AppRoutes.login),
                                  child: const Text('Ensalutu'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
