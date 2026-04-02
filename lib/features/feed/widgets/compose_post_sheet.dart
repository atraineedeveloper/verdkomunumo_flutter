import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';

class ComposePostSheet extends StatefulWidget {
  final List<Map<String, String>> categories;

  const ComposePostSheet({super.key, this.categories = const []});

  @override
  State<ComposePostSheet> createState() => _ComposePostSheetState();
}

class _ComposePostSheetState extends State<ComposePostSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('posts').insert({
        'user_id': userId,
        'content': content,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eraro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = AppConstants.maxPostLength - _controller.text.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nova afiŝo',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 18),
                label: const Text('Sendu'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            maxLength: AppConstants.maxPostLength,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Kion vi pensas?',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          // Category selector
          if (widget.categories.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "Neniu" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: const Text('—', style: TextStyle(fontSize: 12)),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = null),
                      selectedColor: colorScheme.surfaceContainerHighest,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  ...widget.categories.map((cat) {
                    final selected = _selectedCategoryId == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          cat['name'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.black : colorScheme.onSurface,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryId = cat['id']),
                        selectedColor: colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$remaining signoj',
                style: TextStyle(
                  fontSize: 12,
                  color: remaining < 100
                      ? Colors.redAccent
                      : colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
