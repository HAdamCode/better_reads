import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ShelfThemeType { minimalist, classicWood, fantasy, romance }

class ShelfTheme {
  final ShelfThemeType type;
  final String name;
  final String description;

  // Background colors
  final Color backgroundColor;
  final Color backPanelTopColor;
  final Color backPanelMiddleColor;
  final Color backPanelBottomColor;

  // Side panel colors
  final Color sidePanelInnerColor;
  final Color sidePanelMiddleColor;
  final Color sidePanelOuterColor;

  // Divider colors (for top shelf - inverted for bottom)
  final Color dividerDarkColor;
  final Color dividerMiddleColor;
  final Color dividerLightColor;

  // Text colors
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color iconColor;

  // Dimensions
  final double sidePanelWidth;
  final double dividerHeight;

  // Texture settings
  final ShelfTextureType textureType;
  final List<Color>? grainColors;
  final Color? grainHighlightColor;
  final Color? accentGlowColor;
  final Color? starAccentColor; // For fantasy sparkles/stars

  const ShelfTheme({
    required this.type,
    required this.name,
    required this.description,
    required this.backgroundColor,
    required this.backPanelTopColor,
    required this.backPanelMiddleColor,
    required this.backPanelBottomColor,
    required this.sidePanelInnerColor,
    required this.sidePanelMiddleColor,
    required this.sidePanelOuterColor,
    required this.dividerDarkColor,
    required this.dividerMiddleColor,
    required this.dividerLightColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.iconColor,
    required this.sidePanelWidth,
    required this.dividerHeight,
    required this.textureType,
    this.grainColors,
    this.grainHighlightColor,
    this.accentGlowColor,
    this.starAccentColor,
  });

  factory ShelfTheme.minimalist() => const ShelfTheme(
        type: ShelfThemeType.minimalist,
        name: 'Minimalist',
        description: 'Clean and simple',
        backgroundColor: Colors.transparent,
        backPanelTopColor: Color(0xFFF5F5F5),
        backPanelMiddleColor: Color(0xFFFAFAFA),
        backPanelBottomColor: Color(0xFFF5F5F5),
        sidePanelInnerColor: Color(0xFFE0E0E0),
        sidePanelMiddleColor: Color(0xFFEEEEEE),
        sidePanelOuterColor: Color(0xFFF5F5F5),
        dividerDarkColor: Color(0xFFBDBDBD),
        dividerMiddleColor: Color(0xFFE0E0E0),
        dividerLightColor: Color(0xFFEEEEEE),
        textPrimaryColor: Color(0xFF212121),
        textSecondaryColor: Color(0xFF757575),
        iconColor: Color(0xFF616161),
        sidePanelWidth: 2,
        dividerHeight: 4,
        textureType: ShelfTextureType.none,
      );

  factory ShelfTheme.classicWood() => const ShelfTheme(
        type: ShelfThemeType.classicWood,
        name: 'Classic Wood',
        description: 'Rustic library bookshelf',
        backgroundColor: Color(0xFF4A2E1C), // Deeper, richer brown
        backPanelTopColor: Color(0xFF2D1A10), // Darker shadow at top
        backPanelMiddleColor: Color(0xFF3D2517), // Rich walnut center
        backPanelBottomColor: Color(0xFF2D1A10), // Darker at bottom
        sidePanelInnerColor: Color(0xFF3D2517), // Deep inner shadow
        sidePanelMiddleColor: Color(0xFF6B4423), // Warm mahogany
        sidePanelOuterColor: Color(0xFFB8875A), // Honey oak edge
        dividerDarkColor: Color(0xFF5C3A22), // Rich shelf dark
        dividerMiddleColor: Color(0xFF8B5A3C), // Warm shelf body
        dividerLightColor: Color(0xFFD4A574), // Polished highlight
        textPrimaryColor: Color(0xFFE8D4B8), // Warm cream text
        textSecondaryColor: Color(0xB3D4A574), // 70% opacity amber
        iconColor: Color(0xFFD4A574),
        sidePanelWidth: 16, // Slightly thicker for more presence
        dividerHeight: 16, // Thicker shelves for rustic feel
        textureType: ShelfTextureType.woodGrain,
        grainColors: [
          Color(0xFF3D2517), // Deep walnut
          Color(0xFF4A2E1C), // Rich brown
          Color(0xFF5C3A22), // Warm mahogany
          Color(0xFF4A3222), // Medium brown
          Color(0xFF6B4423), // Amber brown
        ],
        grainHighlightColor: Color(0xFFD4A574), // Warm honey highlight
      );

  factory ShelfTheme.fantasy() => const ShelfTheme(
        type: ShelfThemeType.fantasy,
        name: 'Fantasy',
        description: 'Enchanted stone library',
        backgroundColor: Color(0xFF2D2438),
        backPanelTopColor: Color(0xFF1A1620),
        backPanelMiddleColor: Color(0xFF2D2438),
        backPanelBottomColor: Color(0xFF1A1620),
        sidePanelInnerColor: Color(0xFF1A1620),
        sidePanelMiddleColor: Color(0xFF2D2438),
        sidePanelOuterColor: Color(0xFF4A3F5C),
        dividerDarkColor: Color(0xFF1A1620),
        dividerMiddleColor: Color(0xFF3D3548),
        dividerLightColor: Color(0xFF4A3F5C),
        textPrimaryColor: Color(0xFFD4AF37), // Gold
        textSecondaryColor: Color(0xB3D4AF37), // 70% opacity gold
        iconColor: Color(0xFFD4AF37),
        sidePanelWidth: 16,
        dividerHeight: 16,
        textureType: ShelfTextureType.stoneRune,
        grainColors: [
          Color(0xFF3D3548),
          Color(0xFF2D2438),
          Color(0xFF4A3F5C),
        ],
        grainHighlightColor: Color(0xFFD4AF37), // Gold runes
        accentGlowColor: Color(0xFF7B68EE), // Magic glow
        starAccentColor: Color(0xFFE8F4FF), // Bright silvery starlight
      );

  /// Romance theme - Beauty and the Beast, Bridgerton, classic romantic era
  /// Enchanted library with rose motifs, baroque gilded details, magical sparkles
  factory ShelfTheme.romance() => const ShelfTheme(
        type: ShelfThemeType.romance,
        name: 'Romance',
        description: 'Elegant & enchanting',
        backgroundColor: Color(0xFFFDF6F0), // Soft cream
        backPanelTopColor: Color(0xFFF5DFD7), // Champagne rose (warmer)
        backPanelMiddleColor: Color(0xFFFAF0EA), // Warm cream
        backPanelBottomColor: Color(0xFFF5E6E0), // Blush tint
        sidePanelInnerColor: Color(0xFFC9A090), // Deeper dusty rose
        sidePanelMiddleColor: Color(0xFFB76E79), // Rose gold
        sidePanelOuterColor: Color(0xFFE8C4C4), // Soft blush
        dividerDarkColor: Color(0xFF8B2942), // Enchanted rose (dramatic)
        dividerMiddleColor: Color(0xFFB76E79), // Rose gold
        dividerLightColor: Color(0xFFF5DFD7), // Champagne rose
        textPrimaryColor: Color(0xFF5C1A2B), // Velvet burgundy (richer)
        textSecondaryColor: Color(0xB35C1A2B), // 70% opacity velvet burgundy
        iconColor: Color(0xFFB76E79), // Rose gold
        sidePanelWidth: 16, // Wider for ornate details
        dividerHeight: 16, // Taller for rose motifs
        textureType: ShelfTextureType.ornateFiligree,
        grainColors: [
          Color(0xFFD4A5A5), // Dusty rose
          Color(0xFFE8C4C4), // Soft blush
          Color(0xFFC9A0A0), // Muted rose
          Color(0xFFF5DFD7), // Champagne rose
        ],
        grainHighlightColor: Color(0xFFC9A84C), // Antique gold (warmer, aged)
        accentGlowColor: Color(0xFFE8C87E), // Candlelight gold (warm glow)
        starAccentColor: Color(0xFFFFFAF5), // Shimmer for magical sparkles
      );

  static ShelfTheme fromType(ShelfThemeType type) {
    switch (type) {
      case ShelfThemeType.minimalist:
        return ShelfTheme.minimalist();
      case ShelfThemeType.classicWood:
        return ShelfTheme.classicWood();
      case ShelfThemeType.fantasy:
        return ShelfTheme.fantasy();
      case ShelfThemeType.romance:
        return ShelfTheme.romance();
    }
  }

  static List<ShelfTheme> get allThemes => [
        ShelfTheme.minimalist(),
        ShelfTheme.classicWood(),
        ShelfTheme.fantasy(),
        ShelfTheme.romance(),
      ];

  /// Returns header text style appropriate for this theme.
  /// Classic Wood: Bitter (sturdy slab-serif, rustic library feel)
  /// Fantasy: Cinzel (Roman-inspired)
  /// Romance: Great Vibes (romantic flowing script)
  TextStyle headerStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final effectiveColor = color ?? textPrimaryColor;
    final effectiveFontWeight = fontWeight ?? FontWeight.w700;

    if (type == ShelfThemeType.classicWood) {
      return GoogleFonts.bitter(
        fontSize: fontSize,
        fontWeight: effectiveFontWeight,
        color: effectiveColor,
      );
    }

    if (type == ShelfThemeType.fantasy) {
      return GoogleFonts.cinzel(
        fontSize: fontSize,
        fontWeight: effectiveFontWeight,
        color: effectiveColor,
      );
    }

    if (type == ShelfThemeType.romance) {
      return GoogleFonts.greatVibes(
        fontSize: fontSize,
        fontWeight: effectiveFontWeight,
        color: effectiveColor,
      );
    }

    // Default system font for other themes
    return TextStyle(
      fontSize: fontSize,
      fontWeight: effectiveFontWeight,
      color: effectiveColor,
    );
  }

  /// Returns body text style appropriate for this theme.
  /// Classic Wood: Crimson Text (warm classic book feel)
  /// Fantasy: Cardo (medieval)
  /// Romance: Lora (elegant with calligraphic roots)
  TextStyle bodyStyle({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
  }) {
    final effectiveColor = color ?? textSecondaryColor;
    final effectiveFontWeight = fontWeight ?? FontWeight.normal;

    if (type == ShelfThemeType.classicWood) {
      return GoogleFonts.crimsonText(
        fontSize: fontSize,
        fontWeight: effectiveFontWeight,
        fontStyle: fontStyle,
        color: effectiveColor,
      );
    }

    if (type == ShelfThemeType.fantasy) {
      return GoogleFonts.cardo(
        fontSize: fontSize,
        fontWeight: effectiveFontWeight,
        fontStyle: fontStyle,
        color: effectiveColor,
      );
    }

    if (type == ShelfThemeType.romance) {
      return GoogleFonts.lora(
        fontSize: fontSize,
        fontWeight: effectiveFontWeight,
        fontStyle: fontStyle,
        color: effectiveColor,
      );
    }

    // Default system font for other themes
    return TextStyle(
      fontSize: fontSize,
      fontWeight: effectiveFontWeight,
      fontStyle: fontStyle,
      color: effectiveColor,
    );
  }
}

enum ShelfTextureType {
  none,
  woodGrain,
  stoneRune,
  ornateFiligree,
}
