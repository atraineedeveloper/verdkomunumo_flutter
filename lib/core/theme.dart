import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand ───────────────────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color darkGreen = Color(0xFF16A34A);
  static const Color lightGreen = Color(0xFFBBF7D0);

  // ── Dark mode — iOS true-black system colors ─────────────────────────────
  static const Color background = Color(0xFF000000); // OLED black
  static const Color surface = Color(0xFF1C1C1E); // iOS secondary bg
  static const Color surfaceVariant = Color(0xFF2C2C2E); // iOS tertiary bg
  static const Color surfaceElevated = Color(0xFF3A3A3C); // iOS fills
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceMuted = Color(0xFF8E8E93); // iOS secondary label
  static const Color border = Color(0xFF38383A); // iOS separator dark
  static const Color darkPrimaryContainer = Color(0xFF0D3320);

  // ── Light mode — iOS grouped background system ──────────────────────────
  static const Color lightBackground = Color(0xFFF2F2F7); // iOS grouped bg
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEFEFF4);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF000000);
  static const Color lightOnSurfaceMuted = Color(0xFF8E8E93);
  static const Color lightBorder = Color(0xFFC6C6C8); // iOS separator light
  static const Color lightPrimaryTint = Color(0xFFDCF5E7);
  static const Color lightShadow = Color(0x14000000);

  static ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackground: background,
    surfaceColor: surface,
    surfaceVariantColor: surfaceVariant,
    surfaceElevatedColor: surfaceElevated,
    onSurfaceColor: onSurface,
    onSurfaceMutedColor: onSurfaceMuted,
    outlineColor: border,
    appBarBackground: background,
    primaryContainerColor: darkPrimaryContainer,
  );

  static ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scaffoldBackground: lightBackground,
    surfaceColor: lightSurface,
    surfaceVariantColor: lightSurfaceVariant,
    surfaceElevatedColor: lightSurfaceVariant,
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
    required Color surfaceElevatedColor,
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
    final effectivePrimaryContainer =
        primaryContainerColor ?? darkPrimaryContainer;
    final effectiveShadowColor = shadowColor ?? Colors.black38;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme:
          ColorScheme.fromSeed(
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
            shadow: effectiveShadowColor,
            surfaceContainer: surfaceElevatedColor,
          ),
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      splashFactory: InkSparkle.splashFactory,

      // ── System overlays ──────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: onSurfaceColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: onSurfaceColor, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── NavigationBar ────────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : lightSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 60,
        indicatorColor: isDark ? primaryGreen.withAlpha(28) : lightPrimaryTint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? primaryGreen : darkGreen,
              size: 23,
            );
          }
          return IconThemeData(color: onSurfaceMutedColor, size: 23);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: isDark ? primaryGreen : darkGreen,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(
            color: onSurfaceMutedColor,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── NavigationRail ────────────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: effectiveRaisedSurface,
        selectedIconTheme: const IconThemeData(color: primaryGreen),
        unselectedIconTheme: IconThemeData(color: onSurfaceMutedColor),
        indicatorColor: isDark ? primaryGreen.withAlpha(28) : lightPrimaryTint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: primaryGreen,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: onSurfaceMutedColor,
          fontSize: 11,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isDark ? surface : lightSurface,
        elevation: isDark ? 0 : 0,
        shadowColor: effectiveShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide.none
              : BorderSide(color: outlineColor.withAlpha(80)),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? surface : lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: onSurfaceMutedColor.withAlpha(80),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? surface : lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isDark ? 0 : 12,
        shadowColor: effectiveShadowColor,
      ),

      // ── Inputs ────────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceVariantColor : lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: onSurfaceMutedColor, fontSize: 15),
        hintStyle: GoogleFonts.inter(
          color: onSurfaceMutedColor.withAlpha(160),
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Segmented Button ───────────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return effectivePrimaryContainer;
            }
            return isDark ? surfaceVariantColor : lightSurfaceVariant;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? primaryGreen : darkGreen;
            }
            return onSurfaceMutedColor;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      // ── Elevated Button ────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.1,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          side: BorderSide(color: outlineColor),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),

      // ── ListTile ───────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? onSurfaceColor : darkGreen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.transparent,
      ),

      // ── TabBar ─────────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: onSurfaceMutedColor,
        indicatorColor: primaryGreen,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: outlineColor.withAlpha(80),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),

      // ── Divider ────────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: outlineColor.withAlpha(isDark ? 255 : 120),
        space: 1,
        thickness: 0.5,
      ),

      // ── FAB ────────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFF1A2E20),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),

      // ── Chip ───────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantColor,
        labelStyle: GoogleFonts.inter(
          color: onSurfaceColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Switch ─────────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGreen;
          return null;
        }),
      ),
    );

    // ── Apply Inter font system-wide ────────────────────────────────────────────
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: onSurfaceColor,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: onSurfaceColor,
          letterSpacing: -0.4,
          height: 1.2,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurfaceColor,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
          letterSpacing: -0.1,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurfaceColor,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: onSurfaceColor,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: onSurfaceMutedColor,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onSurfaceMutedColor,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: onSurfaceMutedColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
