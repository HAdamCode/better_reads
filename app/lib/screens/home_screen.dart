import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/books_provider.dart';
import '../utils/theme.dart';
import '../widgets/book_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksProvider>().loadTrendingBooks();
    });
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
          await context.read<BooksProvider>().loadTrendingBooks();
        },
        child: CustomScrollView(
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

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildCurrentlyReading(context),
                  const SizedBox(height: 28),
                  _buildTrendingBooks(context),
                  const SizedBox(height: 28),
                  _buildRecommendations(context),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentlyReading(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, provider, _) {
        final currentlyReading = provider.currentlyReadingBooks;

        if (currentlyReading.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.secondaryColor.withValues(alpha: 0.15),
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 36,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start your reading journey',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find your next favorite book and add it to your reading list',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Discover Books'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Currently Reading',
              actionText: 'See all',
              onAction: () => context.go('/shelves'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: currentlyReading.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final userBook = currentlyReading[index];
                  final heroTag = 'book-home-reading-${userBook.bookId}';
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

  Widget _buildTrendingBooks(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingTrending) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Trending This Week'),
              const SizedBox(height: 16),
              SizedBox(
                height: 210,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          );
        }

        if (provider.trendingError != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Trending This Week'),
              const SizedBox(height: 16),
              Container(
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
            ],
          );
        }

        if (provider.trendingBooks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Trending This Week'),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.trendingBooks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final book = provider.trendingBooks[index];
                  final heroTag = 'book-home-trending-${book.isbn}';
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

  Widget _buildRecommendations(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, provider, _) {
        if (provider.userBooks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'For You'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.tertiaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 28,
                      color: AppTheme.tertiaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalized picks coming soon',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep reading and rating books!',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
