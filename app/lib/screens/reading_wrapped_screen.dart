import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../providers/books_provider.dart';
import '../utils/theme.dart';

class ReadingWrappedScreen extends StatefulWidget {
  final int year;

  const ReadingWrappedScreen({super.key, required this.year});

  @override
  State<ReadingWrappedScreen> createState() => _ReadingWrappedScreenState();
}

class _ReadingWrappedScreenState extends State<ReadingWrappedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int? _originalYear;

  @override
  void initState() {
    super.initState();
    // Set the year filter after the first frame to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stats = context.read<StatsProvider>();
      _originalYear = stats.selectedYear;
      stats.setYear(widget.year);
    });
  }

  @override
  void dispose() {
    // Restore original year when leaving
    if (_originalYear != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) return;
        // Use a delayed callback to restore after dispose
      });
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StatsProvider, BooksProvider>(
      builder: (context, stats, books, _) {
        final pages = _buildWrappedPages(context, stats, books);

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: GestureDetector(
              onTap: () => _nextPage(pages.length),
              child: Stack(
                children: [
                  // Page content
                  PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    itemBuilder: (context, index) => pages[index],
                  ),
                  // Progress indicators
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: List.generate(
                        pages.length,
                        (index) => Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: index <= _currentPage
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 32,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        if (_originalYear != null) {
                          stats.setYear(_originalYear);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  // Navigation hints
                  if (_currentPage < pages.length - 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Tap to continue',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  // Done button on last page
                  if (_currentPage == pages.length - 1)
                    Positioned(
                      bottom: 40,
                      left: 40,
                      right: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_originalYear != null) {
                            stats.setYear(_originalYear);
                          }
                          Navigator.pop(context);
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildWrappedPages(
    BuildContext context,
    StatsProvider stats,
    BooksProvider books,
  ) {
    final pages = <Widget>[];
    final personality = stats.readingPersonality;
    final booksRead = stats.booksRead;
    final pagesRead = stats.pagesRead;
    final topGenres = stats.genreBreakdown.entries.take(3).toList();
    final topAuthors = stats.authorBreakdown.entries.take(3).toList();
    final topBooks = stats.topRatedBooks.take(5).toList();
    final funFacts = stats.funFacts;

    // Page 1: Introduction
    pages.add(_WrappedPage(
      gradient: [Colors.purple.shade900, Colors.purple.shade700],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.5 + (value * 0.5),
                  child: child,
                ),
              );
            },
            child: Text(
              '${widget.year}',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: const Interval(0.3, 1.0),
            builder: (context, value, child) {
              return Opacity(opacity: value, child: child);
            },
            child: const Text(
              'Your Reading Wrapped',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    ));

    // Page 2: Books Read
    if (booksRead > 0) {
      pages.add(_WrappedPage(
        gradient: [AppTheme.readColor, Colors.green.shade900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You read',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: booksRead),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            Text(
              booksRead == 1 ? 'book' : 'books',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'That\'s ${(booksRead / 12).toStringAsFixed(1)} books per month!',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ));
    }

    // Page 3: Pages Read
    if (pagesRead > 0) {
      pages.add(_WrappedPage(
        gradient: [Colors.blue.shade900, Colors.cyan.shade700],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You turned',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: pagesRead),
              duration: const Duration(milliseconds: 2000),
              builder: (context, value, child) {
                return Text(
                  _formatNumber(value),
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const Text(
              'pages',
              style: TextStyle(fontSize: 32, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'That\'s ${(funFacts['stackHeightFeet'] as double).toStringAsFixed(1)} feet of books stacked!',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ));
    }

    // Page 4: Top Genre
    if (topGenres.isNotEmpty) {
      pages.add(_WrappedPage(
        gradient: [Colors.orange.shade900, Colors.deepOrange.shade700],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your top genre was',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Text(
                topGenres.first.key,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${topGenres.first.value} books',
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
            if (topGenres.length > 1) ...[
              const SizedBox(height: 32),
              Text(
                'Also: ${topGenres.skip(1).map((e) => e.key).join(", ")}',
                style: const TextStyle(fontSize: 16, color: Colors.white54),
              ),
            ],
          ],
        ),
      ));
    }

    // Page 5: Top Author
    if (topAuthors.isNotEmpty && topAuthors.first.value > 1) {
      pages.add(_WrappedPage(
        gradient: [Colors.indigo.shade900, Colors.purple.shade700],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your favorite author',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Text(
              topAuthors.first.key,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${topAuthors.first.value} books read',
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ],
        ),
      ));
    }

    // Page 6: Top Books
    if (topBooks.isNotEmpty) {
      pages.add(_WrappedPage(
        gradient: [Colors.amber.shade900, Colors.orange.shade700],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your Top Rated Books',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 32),
            ...topBooks.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final book = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        book.book?.title ?? 'Unknown',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (book.rating != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          book.rating!,
                          (_) => const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ));
    }

    // Page 7: Personality
    pages.add(_WrappedPage(
      gradient: [personality.color.withValues(alpha: 0.8), personality.color],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Your reading personality',
            style: TextStyle(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Text(
              personality.icon,
              style: const TextStyle(fontSize: 80),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            personality.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            personality.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    ));

    // Page 8: Summary
    pages.add(_WrappedPage(
      gradient: [Colors.pink.shade900, Colors.purple.shade900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${widget.year} Recap',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          _SummaryItem(icon: '📚', label: 'Books', value: '$booksRead'),
          _SummaryItem(
            icon: '📄',
            label: 'Pages',
            value: _formatNumber(pagesRead),
          ),
          if (stats.avgRating > 0)
            _SummaryItem(
              icon: '⭐',
              label: 'Avg Rating',
              value: stats.avgRating.toStringAsFixed(1),
            ),
          if (topGenres.isNotEmpty)
            _SummaryItem(
              icon: '🎭',
              label: 'Top Genre',
              value: topGenres.first.key,
            ),
          const SizedBox(height: 40),
          const Text(
            'See you next year!',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    ));

    return pages;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _WrappedPage extends StatelessWidget {
  final List<Color> gradient;
  final Widget child;

  const _WrappedPage({
    required this.gradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: child,
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
