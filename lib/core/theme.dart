import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color darkGreen = Color(0xFF16A34A);
  static const Color lightGreen = Color(0xFFBBF7D0);
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceVariant = Color(0xFF252836);
  static const Color onSurface = Color(0xFFE2E8F0);
  static const Color onSurfaceMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFF2D3047);
  static const Color lightBackground = Color(0xFFF4F8F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE6F1E8);
  static const Color lightSurfaceRaised = Color(0xFFF9FCF8);
  static const Color lightOnSurface = Color(0xFF102417);
  static const Color lightOnSurfaceMuted = Color(0xFF5E6E63);
  static const Color lightBorder = Color(0xFFD0DDD2);
  static const Color lightPrimaryTint = Color(0xFFDDF4E3);
  static const Color lightShadow = Color(0x140D1B12);

  static ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackground: background,
    surfaceColor: surface,
    surfaceVariantColor: surfaceVariant,
    onSurfaceColor: onSurface,
    onSurfaceMutedColor: onSurfaceMuted,
    outlineColor: border,
    appBarBackground: background,
  );

  static ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scaffoldBackground: lightBackground,
    surfaceColor: lightSurface,
    surfaceVariantColor: lightSurfaceVariant,
    onSurfaceColor: lightOnSurface,
    onSurfaceMutedColor: lightOnSurfaceMuted,
    outlineColor: lightBorder,
    appBarBackground: lightBackground,
    raisedSurfaceColor: lightSurfaceRaised,
    primaryContainerColor: lightPrimaryTint,
    shadowColor: lightShadow,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color surfaceColor,
    required Color surfaceVariantColor,
    required Color onSurfaceColor,
    required Color onSurfaceMutedColor,
    required Color outlineColor,
    required Color appBarBackground,
    Color? raisedSurfaceColor,
    Color? primaryContainerColor,
    Color? shadowColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final effectiveRaisedSurface = raisedSurfaceColor ?? surfaceColor;
    final effectivePrimaryContainer = primaryContainerColor ?? primaryGreen;
    final effectiveShadowColor = shadowColor ?? Colors.black26;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: brightness,
      ).copyWith(
        primary: primaryGreen,
        onPrimary: Colors.black,
        secondary: darkGreen,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        primaryContainer: effectivePrimaryContainer,
        surfaceContainerHighest: surfaceVariantColor,
        outline: outlineColor,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 1,
        shadowColor: effectiveShadowColor,
        surfaceTintColor: effectivePrimaryContainer.withAlpha(isDark ? 0 : 32),
        titleTextStyle: const TextStyle(
          color: primaryGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: effectiveRaisedSurface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: onSurfaceMutedColor,
        type: BottomNavigationBarType.fixed,
        elevation: isDark ? 0 : 6,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: effectiveRaisedSurface,
        selectedIconTheme: const IconThemeData(color: primaryGreen),
        unselectedIconTheme: IconThemeData(color: onSurfaceMutedColor),
        selectedLabelTextStyle: const TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: onSurfaceMutedColor),
      ),
      cardTheme: CardThemeData(
        color: effectiveRaisedSurface,
        elevation: isDark ? 0 : 1,
        shadowColor: effectiveShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: outlineColor, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: effectiveRaisedSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: effectiveRaisedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: TextStyle(color: onSurfaceMutedColor),
        hintStyle: TextStyle(color: onSurfaceMutedColor),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return effectivePrimaryContainer;
            }
            return effectiveRaisedSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? Colors.black : darkGreen;
            }
            return onSurfaceColor;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: outlineColor),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? onSurfaceColor : darkGreen,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryGreen),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: onSurfaceMutedColor,
        indicatorColor: primaryGreen,
        dividerColor: outlineColor.withAlpha(120),
      ),
      dividerTheme: DividerThemeData(color: outlineColor, space: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF183221),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantColor,
        labelStyle: TextStyle(color: onSurfaceColor, fontSize: 12),
        side: BorderSide(color: outlineColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
