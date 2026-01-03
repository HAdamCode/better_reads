import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browse_provider.dart';
import '../utils/theme.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BrowseProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: BrowseProvider.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = BrowseProvider.categories[index];
              final isSelected = provider.selectedCategoryId == category.id;

              return GestureDetector(
                onTap: () => provider.selectCategory(category.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
