import 'package:flutter/material.dart';

/// Centralized Material 3 theming for Smart HAS (light and dark variants),
/// following the shared design system (see docs/DESIGN_SYSTEM.md).
class AppTheme {
  const AppTheme._();

  // --- Design tokens --------------------------------------------------------
  static const Color primary = Color(0xFF2563EB); // Smart HAS blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceDark2 = Color(0xFF334155);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  /// Brand gradient used on the login header and primary surfaces.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );

    // For the dark theme, pin the exact background/surface tokens so it looks
    // as polished as the reference design instead of the default M3 greys.
    if (isDark) {
      scheme = scheme.copyWith(
        surface: backgroundDark,
        surfaceContainer: surfaceDark,
        surfaceContainerHigh: surfaceDark,
        surfaceContainerHighest: surfaceDark2,
        outlineVariant: surfaceDark2,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: isDark ? surfaceDark : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? surfaceDark : null,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
