import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../application/suggestions_providers.dart';

class SuggestionSheet extends ConsumerStatefulWidget {
  const SuggestionSheet({super.key});

  @override
  ConsumerState<SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends ConsumerState<SuggestionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contextController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(suggestionsControllerProvider.notifier)
          .submitSuggestion(
            title: _titleController.text,
            description: _descriptionController.text,
            context: _contextController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Via sugesto estis sendita.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authStateNotifierProvider).isAuthenticated;
    final isLoading = ref.watch(suggestionsControllerProvider).isLoading;

    if (!isLoggedIn) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Ensalutu por sendi sugeston.'),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sugesti plibonigon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Mallonga titolo'),
              maxLength: 80,
              validator: (value) {
                if (value == null || value.trim().length < 4) {
                  return 'Almenaŭ 4 signoj';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Kio devus pliboniĝi?',
              ),
              maxLines: 3,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Almenaŭ 10 signoj';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contextController,
              decoration: const InputDecoration(
                labelText: 'Kunteksto aŭ ekzemplo (laŭvole)',
              ),
              maxLines: 2,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CupertinoActivityIndicator(color: Colors.black),
                      )
                    : const Text('Sendi sugeston'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
