import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warm, literary color palette
  static const Color primaryColor = Color(0xFF8B4513); // Saddle brown - leather/wood
  static const Color secondaryColor = Color(0xFFD4A574); // Warm tan
  static const Color accentColor = Color(0xFFD4AF37); // Old gold - for ratings/highlights
  static const Color tertiaryColor = Color(0xFF2D4A3E); // Deep forest green - classic

  // Light theme backgrounds
  static const Color backgroundColor = Color(0xFFFAF7F2); // Warm cream/parchment
  static const Color surfaceColor = Color(0xFFFFFDF8); // Slightly warmer white
  static const Color cardColor = Colors.white;

  // Status colors
  static const Color errorColor = Color(0xFFC53030);
  static const Color successColor = Color(0xFF2D6A4F);

  // Text colors
  static const Color textPrimary = Color(0xFF2C1810); // Dark brown
  static const Color textSecondary = Color(0xFF5C4033); // Medium brown
  static const Color textMuted = Color(0xFF8B7355); // Light brown

  // Shelf status colors
  static const Color wantToReadColor = Color(0xFF3B82F6); // Blue
  static const Color currentlyReadingColor = Color(0xFFD97706); // Amber
  static const Color readColor = Color(0xFF059669); // Green

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: textPrimary,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceColor,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: primaryColor.withValues(alpha: 0.1),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: secondaryColor.withValues(alpha: 0.2)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7)),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 26);
          }
          return IconThemeData(color: textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryColor.withValues(alpha: 0.15),
        selectedColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(fontSize: 13, color: textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: secondaryColor.withValues(alpha: 0.2),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      textTheme: _buildTextTheme(Brightness.light),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primary = isLight ? textPrimary : const Color(0xFFF5EDE4);
    final secondary = isLight ? textSecondary : const Color(0xFFBEB3A6);
    final muted = isLight ? textMuted : const Color(0xFF8C8279);

    // Serif font for headings - literary feel
    final headingFont = GoogleFonts.sourceSerif4TextTheme();
    // Clean sans-serif for body
    final bodyFont = GoogleFonts.sourceSans3TextTheme();

    return TextTheme(
      displayLarge: headingFont.displayLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: headingFont.displayMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      displaySmall: headingFont.displaySmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: headingFont.headlineLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: headingFont.headlineMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: headingFont.headlineSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: headingFont.titleLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: bodyFont.titleMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: bodyFont.titleSmall?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyFont.bodyLarge?.copyWith(
        color: primary,
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: bodyFont.bodyMedium?.copyWith(
        color: secondary,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: bodyFont.bodySmall?.copyWith(
        color: muted,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: bodyFont.labelLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelMedium: bodyFont.labelMedium?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: bodyFont.labelSmall?.copyWith(
        color: muted,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF1A1410); // Very dark brown
    const darkSurface = Color(0xFF252019); // Dark warm surface
    const darkCard = Color(0xFF2E2820); // Slightly lighter card

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: secondaryColor, // Use lighter tan as primary in dark mode
        onPrimary: darkBackground,
        secondary: accentColor,
        tertiary: const Color(0xFF5D8A6B), // Lighter forest green
        error: const Color(0xFFFF6B6B),
        surface: darkSurface,
        onSurface: const Color(0xFFF5EDE4),
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Color(0xFFF5EDE4),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          color: Color(0xFFF5EDE4),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: secondaryColor.withValues(alpha: 0.15)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: secondaryColor.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: secondaryColor, size: 26);
          }
          return IconThemeData(color: Colors.grey.shade500, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: secondaryColor,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: secondaryColor.withValues(alpha: 0.15),
        thickness: 1,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
    );
  }
}
