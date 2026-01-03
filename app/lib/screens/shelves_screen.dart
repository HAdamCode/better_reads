import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/shelf_theme.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
import '../providers/lending_provider.dart';
import '../providers/shelf_theme_provider.dart';
import '../utils/theme.dart';
import '../widgets/book_card.dart';
import '../widgets/bookcase_shelf_row.dart';
import '../widgets/create_shelf_dialog.dart';
import '../widgets/shelf_painters.dart';
import '../widgets/theme_selector_sheet.dart';
import '../widgets/wooden_shelf_divider.dart';

class ShelvesScreen extends StatelessWidget {
  const ShelvesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<BooksProvider, ShelvesProvider, LendingProvider, ShelfThemeProvider>(
      builder: (context, booksProvider, shelvesProvider, lendingProvider, themeProvider, _) {
        final theme = themeProvider.theme;
        final isMinimalist = theme.type == ShelfThemeType.minimalist;

        return Scaffold(
          backgroundColor: isMinimalist ? null : theme.backgroundColor,
          appBar: AppBar(
            title: const Text('My Library'),
            actions: [
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Change theme',
                onPressed: () => ThemeSelectorSheet.show(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await booksProvider.syncFromBackend();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Currently Reading shelf
                SliverToBoxAdapter(
                  child: BookcaseShelfRow(
                    title: 'Currently Reading',
                    subtitle: _bookCountText(booksProvider.currentlyReadingBooks.length),
                    icon: Icons.menu_book,
                    iconColor: AppTheme.currentlyReadingColor,
                    books: booksProvider.currentlyReadingBooks,
                    heroTagPrefix: 'book-shelf-reading',
                    showEmptyState: true,
                    onAddTap: () => context.push('/search'),
                    theme: theme,
                  ),
                ),

                // Want to Read shelf
                SliverToBoxAdapter(
                  child: BookcaseShelfRow(
                    title: 'Want to Read',
                    subtitle: _bookCountText(booksProvider.wantToReadBooks.length),
                    icon: Icons.bookmark_outline,
                    iconColor: AppTheme.wantToReadColor,
                    books: booksProvider.wantToReadBooks,
                    heroTagPrefix: 'book-shelf-want',
                    showEmptyState: true,
                    onAddTap: () => context.push('/search'),
                    theme: theme,
                  ),
                ),

                // Read shelf
                SliverToBoxAdapter(
                  child: BookcaseShelfRow(
                    title: 'Read',
                    subtitle: _bookCountText(booksProvider.readBooks.length),
                    icon: Icons.check_circle_outline,
                    iconColor: AppTheme.readColor,
                    books: booksProvider.readBooks,
                    heroTagPrefix: 'book-shelf-read',
                    showEmptyState: true,
                    onAddTap: () => context.push('/search'),
                    theme: theme,
                  ),
                ),

                // Lent Out shelf (only if there are active loans)
                if (lendingProvider.activeLoans.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildLentOutRow(context, lendingProvider, booksProvider, theme),
                  ),

                // Custom Shelves section header (only if there are custom shelves)
                if (shelvesProvider.sortedShelves.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildCustomShelvesHeader(context, theme),
                  ),

                // Custom Shelves
                ...shelvesProvider.sortedShelves.map((shelf) {
                  final books = booksProvider.getBooksOnCustomShelf(shelf.id);
                  return SliverToBoxAdapter(
                    child: BookcaseShelfRow(
                      title: shelf.name,
                      subtitle: _bookCountText(books.length),
                      books: books,
                      heroTagPrefix: 'book-shelf-${shelf.id}',
                      onTitleTap: () => context.push('/shelf/${shelf.id}'),
                      onAddTap: () => context.push('/search'),
                      showEmptyState: true,
                      theme: theme,
                    ),
                  );
                }),

                // Bottom padding for FAB
                SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    color: isMinimalist ? null : theme.backgroundColor,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => CreateShelfDialog.show(context),
            tooltip: 'Create Shelf',
            elevation: 8,
            backgroundColor: theme.dividerLightColor,
            foregroundColor: theme.type == ShelfThemeType.minimalist
                ? theme.textPrimaryColor
                : theme.sidePanelMiddleColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.sidePanelMiddleColor,
                width: 2,
              ),
            ),
            child: theme.type == ShelfThemeType.fantasy
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      theme.textPrimaryColor, // Gold
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/image.png',
                      width: 24,
                      height: 24,
                    ),
                  )
                : const Icon(Icons.add),
          ),
        );
      },
    );
  }

  String _bookCountText(int count) {
    if (count == 0) return 'Empty';
    return '$count ${count == 1 ? 'book' : 'books'}';
  }

  Widget _buildCustomShelvesHeader(BuildContext context, ShelfTheme theme) {
    return Container(
      color: theme.type == ShelfThemeType.minimalist ? null : theme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: theme.textPrimaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Custom Shelves',
            style: theme.headerStyle(
              fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLentOutRow(
    BuildContext context,
    LendingProvider lendingProvider,
    BooksProvider booksProvider,
    ShelfTheme theme,
  ) {
    final activeLoans = lendingProvider.activeLoans;
    final isMinimalist = theme.type == ShelfThemeType.minimalist;

    // Build list of UserBooks for lent books with borrower overlay
    final lentBooks = <UserBook>[];
    final borrowerNames = <String, String>{}; // bookId -> borrowerName

    for (final loan in activeLoans) {
      final userBook = booksProvider.getUserBook(loan.bookId);
      if (userBook != null && userBook.book != null) {
        lentBooks.add(userBook);
        borrowerNames[loan.bookId] = loan.borrowerName;
      }
    }

    return Container(
      color: theme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.orange.shade300, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lent Out',
                        style: theme.headerStyle(
                          fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                        ),
                      ),
                      Text(
                        _bookCountText(lentBooks.length),
                        style: theme.bodyStyle(
                          fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top shelf (skip for minimalist)
          if (!isMinimalist)
            WoodenShelfDivider(isTop: true, margin: EdgeInsets.zero, theme: theme, seed: 'LentOut'.hashCode.abs()),

          // Bookshelf with side panels and back
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left side panel (skip for minimalist)
                if (!isMinimalist) _buildSidePanel(isLeft: true, theme: theme, seed: 'LentOut'.hashCode.abs()),

                // Back panel with books
                Expanded(
                  child: Container(
                    decoration: isMinimalist
                        ? null
                        : BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.backPanelTopColor,
                                theme.backPanelMiddleColor,
                                theme.backPanelBottomColor,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                    child: Column(
                      children: [
                        if (!isMinimalist)
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: lentBooks.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final userBook = lentBooks[index];
                                final borrowerName = borrowerNames[userBook.bookId] ?? '';
                                final heroTag = 'book-shelf-lent-${userBook.bookId}';

                                return Column(
                                  children: [
                                    Expanded(
                                      child: BookCard(
                                        book: userBook.book!,
                                        heroTag: heroTag,
                                        onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Borrower badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person, size: 12, color: Colors.orange.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            borrowerName.length > 10
                                                ? '${borrowerName.substring(0, 10)}...'
                                                : borrowerName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right side panel (skip for minimalist)
                if (!isMinimalist) _buildSidePanel(isLeft: false, theme: theme, seed: 'LentOut'.hashCode.abs() + 1),
              ],
            ),
          ),

          // Wooden Shelf
          WoodenShelfDivider(margin: EdgeInsets.zero, theme: theme, seed: 'LentOut'.hashCode.abs() + 2),
        ],
      ),
    );
  }

  Widget _buildSidePanel({required bool isLeft, required ShelfTheme theme, int seed = 42}) {
    return Container(
      width: theme.sidePanelWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            theme.sidePanelInnerColor,
            theme.sidePanelMiddleColor,
            theme.sidePanelOuterColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: Offset(isLeft ? 2 : -2, 0),
          ),
        ],
      ),
      child: CustomPaint(
        painter: ShelfPainterFactory.getSidePanelPainter(theme, seed: seed),
      ),
    );
  }
}
