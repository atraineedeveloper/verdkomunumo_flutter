import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';


class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double radius;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.username,
    this.radius = 20,
  });

  // Generates a consistent color from the username
  Color _avatarColor() {
    const palette = [
      Color(0xFF22C55E),
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
      Color(0xFFF97316),
      Color(0xFF06B6D4),
    ];
    if (username.isEmpty) return palette[0];
    final index = username.codeUnits.fold(0, (a, b) => a + b) % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    final color = _avatarColor();
    final letter =
        username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.25)!,
          ],
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.85,
            fontFamily: 'Inter',
            height: 1,
          ),
        ),
      ),
    );
  }
}
