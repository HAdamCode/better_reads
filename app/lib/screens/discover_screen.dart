import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/books_provider.dart';
import '../providers/browse_provider.dart';
import '../utils/theme.dart';
import '../widgets/book_card.dart';
import '../widgets/category_chips.dart';
import '../widgets/section_header.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booksProvider = context.read<BooksProvider>();
      booksProvider.loadTrendingBooks();
      booksProvider.loadForYouBooks();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BrowseProvider>().loadMore();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firstName = authProvider.displayName?.split(' ').first ?? 'Reader';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final booksProvider = context.read<BooksProvider>();
          final browseProvider = context.read<BrowseProvider>();

          // Refresh everything in parallel
          final futures = <Future>[];

          // Refresh For You
          futures.add(booksProvider.loadForYouBooks(forceRefresh: true));

          // Refresh Trending
          futures.add(booksProvider.loadTrendingBooks(forceRefresh: true));

          // Refresh category if selected
          if (browseProvider.selectedCategoryId != null) {
            futures.add(browseProvider.refresh());
          }

          await Future.wait(futures);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom App Bar with greeting
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      firstName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search, size: 22),
                  ),
                  onPressed: () => context.go('/search'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Currently Reading Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildCurrentlyReading(context),
              ),
            ),

            // For You Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildForYouSection(context),
              ),
            ),

            // Browse by Genre Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Browse by Genre',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ),
            ),

            // Category Chips
            const SliverToBoxAdapter(
              child: CategoryChips(),
            ),

            // Category Books or Trending
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: _buildCategoryHeader(context),
              ),
            ),

            // Books Grid
            _buildBooksGrid(context),

            // Loading indicator for pagination
            SliverToBoxAdapter(
              child: Consumer<BrowseProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.currentBooks.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 20);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context) {
    return Consumer<BrowseProvider>(
      builder: (context, provider, _) {
        final category = provider.selectedCategory;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category != null ? '${category.name} Books' : 'Trending This Week',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
            ),
            if (category != null)
              TextButton(
                onPressed: () => provider.clearSelection(),
                child: Text(
                  'Show Trending',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBooksGrid(BuildContext context) {
    return Consumer2<BrowseProvider, BooksProvider>(
      builder: (context, browseProvider, booksProvider, _) {
        // Show category books if a category is selected
        if (browseProvider.selectedCategoryId != null) {
          return _buildCategoryBooksGrid(context, browseProvider);
        }

        // Otherwise show trending books
        return _buildTrendingGrid(context, booksProvider);
      },
    );
  }

  Widget _buildCategoryBooksGrid(BuildContext context, BrowseProvider provider) {
    if (provider.isLoading && provider.currentBooks.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    if (provider.error != null && provider.currentBooks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: AppTheme.errorColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Could not load books',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => provider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.currentBooks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No books found in this category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = provider.currentBooks[index];
            final heroTag = 'book-discover-category-${book.isbn}';
            return BookCard(
              book: book,
              heroTag: heroTag,
              onTap: () => context.push('/book/${book.isbn}', extra: heroTag),
            );
          },
          childCount: provider.currentBooks.length,
        ),
      ),
    );
  }

  Widget _buildTrendingGrid(BuildContext context, BooksProvider provider) {
    if (provider.isLoadingTrending) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    if (provider.trendingError != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: AppTheme.errorColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Could not load trending books',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => provider.loadTrendingBooks(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.trendingBooks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = provider.trendingBooks[index];
            final heroTag = 'book-discover-trending-${book.isbn}';
            return BookCard(
              book: book,
              heroTag: heroTag,
              onTap: () => context.push('/book/${book.isbn}', extra: heroTag),
            );
          },
          childCount: provider.trendingBooks.length,
        ),
      ),
    );
  }

  Widget _buildCurrentlyReading(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, provider, _) {
        final currentlyReading = provider.currentlyReadingBooks;

        if (currentlyReading.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Continue Reading',
              actionText: 'See all',
              onAction: () => context.go('/shelves'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: currentlyReading.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final userBook = currentlyReading[index];
                  final heroTag = 'book-discover-reading-${userBook.bookId}';
                  return BookCard(
                    book: userBook.book!,
                    heroTag: heroTag,
                    onTap: () => context.push('/book/${userBook.bookId}', extra: heroTag),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForYouSection(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingForYou) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'For You'),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          );
        }

        if (provider.forYouBooks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'For You',
              subtitle: provider.readBooks.isNotEmpty
                  ? 'Based on your reading history'
                  : 'Popular picks to get you started',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.forYouBooks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final book = provider.forYouBooks[index];
                  final heroTag = 'book-discover-foryou-${book.isbn}';
                  return BookCard(
                    book: book,
                    heroTag: heroTag,
                    onTap: () => context.push('/book/${book.isbn}', extra: heroTag),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
