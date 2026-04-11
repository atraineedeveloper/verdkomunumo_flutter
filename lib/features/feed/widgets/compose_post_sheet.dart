import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme.dart';
import '../../../widgets/user_avatar.dart';
import '../../settings/application/settings_providers.dart';
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
  final _focusNode = FocusNode();
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
    // Auto-focus after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
        const SnackBar(content: Text('Elektu kategorion por la afiŝo.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(feedControllerProvider.notifier).createPost(
            content: content,
            categoryId: _selectedCategoryId,
            imagePath: _selectedImage?.path,
          );
      if (mounted) Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              failureMessageOf(e, fallback: 'Ne eblis krei la afiŝon.')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final settingsState = ref.watch(settingsControllerProvider);
    final profile = settingsState.profile;

    final charCount = _controller.text.length;
    final remaining = AppConstants.maxPostLength - charCount;
    final progress = charCount / AppConstants.maxPostLength;
    final isOverLimit = remaining < 0;
    final isNearLimit = remaining < 40 && !isOverLimit;
    final canPost = charCount > 0 && !isOverLimit && !_loading;

    final progressColor = isOverLimit
        ? Colors.redAccent
        : isNearLimit
            ? Colors.orange
            : AppTheme.primaryGreen;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withAlpha(60),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withAlpha(160),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Nuligi'),
                ),
                const Spacer(),
                Text(
                  'Nova afiŝo',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                // Post button
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: canPost ? 1.0 : 0.4,
                  child: FilledButton(
                    onPressed: canPost ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CupertinoActivityIndicator(
                                color: Colors.black,
                              ),
                          )
                        : const Text('Sendu'),
                  ),
                ),
              ],
            ),
          ),

          // ── Body — avatar + text area ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current user avatar
                UserAvatar(
                  avatarUrl: profile?.avatarUrl,
                  username: profile?.username ?? '?',
                  radius: 20,
                ),
                const SizedBox(width: 12),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 4,
                    maxLength: AppConstants.maxPostLength + 20,
                    decoration: InputDecoration(
                      hintText: 'Kion vi pensas?',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withAlpha(80),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),

          // ── Image preview ────────────────────────────────────────────────────
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 16, 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_selectedImage!.path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Category selector ────────────────────────────────────────────────
          if (widget.categories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.label_outline_rounded,
                    size: 14,
                    color: colorScheme.onSurface.withAlpha(120),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Kategorio',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                children: widget.categories.map((cat) {
                  final selected = _selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategoryId = cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryGreen
                              : isDark
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryGreen
                                : colorScheme.outline.withAlpha(80),
                          ),
                        ),
                        child: Text(
                          cat.name,
                          style: textTheme.labelSmall?.copyWith(
                            color: selected
                                ? Colors.black
                                : colorScheme.onSurface.withAlpha(200),
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Bottom toolbar ───────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              6,
              8,
              12,
              8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withAlpha(60),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Image picker
                IconButton(
                  onPressed: _loading ? null : _pickImage,
                  icon: Icon(
                    _selectedImage != null
                        ? Icons.image_rounded
                        : Icons.image_outlined,
                    size: 22,
                    color: _selectedImage != null
                        ? AppTheme.primaryGreen
                        : colorScheme.onSurface.withAlpha(140),
                  ),
                  tooltip: 'Aldoni bildon',
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                // Char counter — circular progress
                if (isNearLimit || isOverLimit)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      '$remaining',
                      style: textTheme.labelSmall?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CustomPaint(
                    painter: _CircleProgressPainter(
                      progress: progress.clamp(0.0, 1.0),
                      color: progressColor,
                      trackColor: colorScheme.outline.withAlpha(60),
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circular progress painter ─────────────────────────────────────────────────

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress || old.color != color;
}
