import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shelf_theme.dart';
import '../providers/shelf_theme_provider.dart';

class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShelfThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Bookshelf Theme',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

              // Theme options - first row (Minimalist, Classic Wood, Fantasy)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ShelfTheme.allThemes.take(3).map((theme) {
                    final isSelected = themeProvider.currentThemeType == theme.type;
                    return _ThemeOption(
                      theme: theme,
                      isSelected: isSelected,
                      onTap: () {
                        themeProvider.setTheme(theme.type);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Theme options - second row (Romance, Pride)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ShelfTheme.allThemes.skip(3).map((theme) {
                    final isSelected = themeProvider.currentThemeType == theme.type;
                    return _ThemeOption(
                      theme: theme,
                      isSelected: isSelected,
                      onTap: () {
                        themeProvider.setTheme(theme.type);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ShelfTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Theme preview
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildThemePreview(theme),
            ),

            const SizedBox(height: 8),

            // Theme name
            SizedBox(
              width: 80,
              child: Text(
                theme.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
              ),
            ),

            // Check mark if selected
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(ShelfTheme theme) {
    return Container(
      color: theme.backgroundColor == Colors.transparent
          ? Colors.grey.shade100
          : theme.backgroundColor,
      child: Column(
        children: [
          // Mini header
          Container(
            height: 16,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            alignment: Alignment.centerLeft,
            child: Container(
              width: 30,
              height: 6,
              decoration: BoxDecoration(
                color: theme.textPrimaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Top divider
          if (theme.type != ShelfThemeType.minimalist)
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.dividerDarkColor,
                    theme.dividerLightColor,
                  ],
                ),
              ),
            ),

          // Book area with side panels
          Expanded(
            child: Row(
              children: [
                // Left panel
                if (theme.type != ShelfThemeType.minimalist)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.sidePanelInnerColor,
                          theme.sidePanelOuterColor,
                        ],
                      ),
                    ),
                  ),

                // Back panel with mini books
                Expanded(
                  child: Container(
                    color: theme.backPanelMiddleColor,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _miniBook(Colors.red.shade400),
                        const SizedBox(width: 1),
                        _miniBook(Colors.blue.shade400),
                        const SizedBox(width: 1),
                        _miniBook(Colors.green.shade400),
                      ],
                    ),
                  ),
                ),

                // Right panel
                if (theme.type != ShelfThemeType.minimalist)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.sidePanelOuterColor,
                          theme.sidePanelInnerColor,
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom divider
          Container(
            height: theme.type == ShelfThemeType.minimalist ? 2 : 4,
            decoration: BoxDecoration(
              gradient: theme.type == ShelfThemeType.minimalist
                  ? null
                  : LinearGradient(
                      colors: [
                        theme.dividerLightColor,
                        theme.dividerDarkColor,
                      ],
                    ),
              color: theme.type == ShelfThemeType.minimalist
                  ? theme.dividerMiddleColor
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBook(Color color) {
    return Container(
      width: 10,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }
}
