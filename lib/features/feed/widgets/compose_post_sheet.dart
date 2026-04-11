import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/error/app_failure.dart';
import '../application/feed_providers.dart';
import '../domain/feed_category.dart';

class ComposePostSheet extends ConsumerStatefulWidget {
  final List<FeedCategory> categories;

  const ComposePostSheet({super.key, this.categories = const []});

  @override
  ConsumerState<ComposePostSheet> createState() => _ComposePostSheetState();
}

class _ComposePostSheetState extends ConsumerState<ComposePostSheet> {
  final _controller = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _loading = false;
  String? _selectedCategoryId;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildoj ne estas subtenataj en la reta versio.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (!mounted) return;
    setState(() => _selectedImage = picked);
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elektu kategorion por la afiŝo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(feedControllerProvider.notifier)
          .createPost(
            content: content,
            categoryId: _selectedCategoryId,
            imagePath: _selectedImage?.path,
          );
      if (mounted) Navigator.of(context).pop();
    } on AppFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failureMessageOf(error, fallback: 'Ne eblis krei la afiŝon.'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
          Row(
            children: [
              TextButton.icon(
                onPressed: _loading ? null : _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Aldoni bildon'),
              ),
              if (_selectedImage != null)
                TextButton.icon(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Forigi'),
                ),
            ],
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selectedImage!.path),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (widget.categories.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...widget.categories.map((category) {
                    final selected = _selectedCategoryId == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? Colors.black
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryId = category.id),
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
