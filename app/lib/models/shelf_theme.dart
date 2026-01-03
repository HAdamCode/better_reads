import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ShelfThemeType { minimalist, classicWood, fantasy, romance, pride }

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
        backgroundColor: Color(0xFF4A2530), // Deep burgundy/wine
        backPanelTopColor: Color(0xFF2D1520), // Dark shadow
        backPanelMiddleColor: Color(0xFF3D2028), // Rich mahogany wine
        backPanelBottomColor: Color(0xFF2D1520), // Dark shadow
        sidePanelInnerColor: Color(0xFF2D1520), // Deep shadow
        sidePanelMiddleColor: Color(0xFF5C2D3A), // Dark rose
        sidePanelOuterColor: Color(0xFF8B4A5A), // Muted rose edge
        dividerDarkColor: Color(0xFF5C2D3A), // Dark rose
        dividerMiddleColor: Color(0xFF8B4A5A), // Muted rose
        dividerLightColor: Color(0xFFD4A574), // Candlelight gold highlight
        textPrimaryColor: Color(0xFFE8D4C4), // Warm cream
        textSecondaryColor: Color(0xB3D4A574), // 70% candlelight gold
        iconColor: Color(0xFFD4AF37), // Gold
        sidePanelWidth: 16, // Wider for ornate details
        dividerHeight: 16, // Taller for rose motifs
        textureType: ShelfTextureType.ornateFiligree,
        grainColors: [
          Color(0xFF3D2028), // Dark wine
          Color(0xFF5C2D3A), // Dark rose
          Color(0xFF4A2530), // Deep burgundy
          Color(0xFF6B3A48), // Muted burgundy rose
        ],
        grainHighlightColor: Color(0xFFC9A84C), // Antique gold (warmer, aged)
        accentGlowColor: Color(0xFFE8C87E), // Candlelight gold (warm glow)
        starAccentColor: Color(0xFFFFFAF5), // Shimmer for magical sparkles
      );

  /// Pride theme - LGBTQ+ celebration with rainbow colors
  /// Bold, vibrant, joyful with hearts, sparkles, and rainbow gradients
  factory ShelfTheme.pride() => const ShelfTheme(
        type: ShelfThemeType.pride,
        name: 'Pride',
        description: 'Bold & celebratory',
        backgroundColor: Color(0xFFFFFFFF), // Clean white
        backPanelTopColor: Color(0xFFE53935), // Bold red
        backPanelMiddleColor: Color(0xFFFFEB3B), // Bold yellow
        backPanelBottomColor: Color(0xFF9C27B0), // Bold purple
        sidePanelInnerColor: Color(0xFFE53935), // Red
        sidePanelMiddleColor: Color(0xFF4CAF50), // Green
        sidePanelOuterColor: Color(0xFF2196F3), // Blue
        dividerDarkColor: Color(0xFFE53935), // Red
        dividerMiddleColor: Color(0xFF4CAF50), // Green
        dividerLightColor: Color(0xFF2196F3), // Blue
        textPrimaryColor: Color(0xFF1A1A1A), // Near black for contrast
        textSecondaryColor: Color(0xB31A1A1A), // 70% black
        iconColor: Color(0xFFE91E63), // Hot pink
        sidePanelWidth: 20, // Extra wide for rainbow stripes
        dividerHeight: 22, // Extra tall for rainbow stripes
        textureType: ShelfTextureType.rainbowSparkle,
        grainColors: [
          Color(0xFFE53935), // Red
          Color(0xFFFF9800), // Orange
          Color(0xFFFFEB3B), // Yellow
          Color(0xFF4CAF50), // Green
          Color(0xFF2196F3), // Blue
          Color(0xFF9C27B0), // Purple
        ],
        grainHighlightColor: Color(0xFFFFD700), // Gold shimmer
        accentGlowColor: Color(0xFFFF006E), // Hot pink glow
        starAccentColor: Color(0xFFFFFFFF), // White sparkles
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
      case ShelfThemeType.pride:
        return ShelfTheme.pride();
    }
  }

  static List<ShelfTheme> get allThemes => [
        ShelfTheme.minimalist(),
        ShelfTheme.classicWood(),
        ShelfTheme.fantasy(),
        ShelfTheme.romance(),
        ShelfTheme.pride(),
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

    if (type == ShelfThemeType.pride) {
      return GoogleFonts.pacifico(
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
  /// Pride: Inter (modern, accessible)
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

    if (type == ShelfThemeType.pride) {
      return GoogleFonts.inter(
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
  rainbowSparkle,
}
