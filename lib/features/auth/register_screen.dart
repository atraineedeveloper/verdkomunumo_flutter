import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/responsive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
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
    setState(() => _loading = true);
    final normalizedUsername = _usernameController.text.trim().toLowerCase();
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'username': normalizedUsername,
          'esperanto_level': _esperantoLevel,
        },
      );

      if (response.user != null) {
        // Create profile
        await Supabase.instance.client.from('profiles').upsert({
          'id': response.user!.id,
          'username': normalizedUsername,
          'esperanto_level': _esperantoLevel,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konto kreita sukcese!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
          context.go('/fonto');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideLandscape = ResponsiveLayout.isLandscape(context) &&
        MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/ensaluti'),
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
                            'Aliĝu al la verda komunumo',
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
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enigu salutnomon';
                                }
                                if (v.length < 3) return 'Almenaŭ 3 signoj';
                                if (!RegExp(r'^[a-z0-9_]+$')
                                    .hasMatch(v.toLowerCase())) {
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
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enigu retpoŝtadreson';
                                }
                                if (!v.contains('@')) {
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
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) {
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
                                  onChanged: (v) =>
                                      setState(() => _esperantoLevel = v!),
                                  child: Column(
                                    children: {
                                      'komencanto': '🌱 Komencanto (Beginners)',
                                      'progresanto':
                                          '🌿 Progresanto (Intermediate)',
                                      'flua': '🌳 Flua (Fluent)',
                                    }.entries.map(
                                      (e) => RadioListTile<String>(
                                        value: e.key,
                                        title: Text(e.value),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _signUp,
                                child: _loading
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
                                  onPressed: () => context.go('/ensaluti'),
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
