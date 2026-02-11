import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_book.dart';
import '../providers/books_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/theme.dart';
import '../widgets/book_card.dart';
import 'reading_wrapped_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late ConfettiController _confettiController;
  bool _hasShownConfetti = false;
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _maybeShowConfetti(StatsProvider stats) {
    // Show confetti on first view if they have achievements
    if (!_hasShownConfetti && stats.unlockedAchievements.length >= 5) {
      _hasShownConfetti = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _confettiController.play();
      });
    }
  }

  void _showShareSheet(BuildContext context, StatsProvider stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Share Your Stats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RepaintBoundary(
                  key: _shareCardKey,
                  child: _ShareCardWidget(stats: stats),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton.icon(
                onPressed: () => _captureAndShare(context),
                icon: const Icon(Icons.share),
                label: const Text('Share Image'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndShare(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to capture stats')),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/reading_stats.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      navigator.pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my reading stats! 📚',
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        _maybeShowConfetti(stats);

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: const Text('Reading Stats'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Stats',
                    onPressed: stats.booksRead > 0
                        ? () => _showShareSheet(context, stats)
                        : null,
                  ),
                  _buildYearPicker(context, stats),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () => context.read<BooksProvider>().syncFromBackend(),
                child: stats.booksRead == 0
                    ? _buildEmptyState(context, stats)
                    : CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPersonalityCard(context, stats),
                                  const SizedBox(height: 24),
                                  _buildReadingGoals(context, stats),
                                  const SizedBox(height: 24),
                                  _buildOverviewCards(context, stats),
                                  const SizedBox(height: 24),
                                  _buildDidYouKnow(context, stats),
                                  const SizedBox(height: 24),
                                  _buildCoverCollage(context, stats),
                                  const SizedBox(height: 24),
                                  _buildTrophyCase(context, stats),
                                  const SizedBox(height: 24),
                                  _buildProgressTimeline(context, stats),
                                  const SizedBox(height: 24),
                                  _buildBookSpineStack(context, stats),
                                  const SizedBox(height: 24),
                                  _buildTopBooksGallery(context, stats),
                                  const SizedBox(height: 24),
                                  _buildSpeedStats(context, stats),
                                  const SizedBox(height: 24),
                                  _buildRatingSection(context, stats),
                                  const SizedBox(height: 24),
                                  _buildGenreStats(context, stats),
                                  const SizedBox(height: 24),
                                  _buildAuthorStats(context, stats),
                                  if (stats.totalRereadCount > 0) ...[
                                    const SizedBox(height: 24),
                                    _buildRereadStats(context, stats),
                                  ],
                                  const SizedBox(height: 24),
                                  _buildWrappedButton(context, stats),
                                  const SizedBox(height: 24),
                                  _buildSpinTheWheel(context),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.readColor,
                  Colors.amber,
                  Colors.pink,
                  Colors.purple,
                ],
                numberOfParticles: 30,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalityCard(BuildContext context, StatsProvider stats) {
    final personality = stats.readingPersonality;

    return Card(
      elevation: 0,
      color: personality.color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: personality.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  personality.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are a',
                    style: TextStyle(
                      color: personality.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    personality.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: personality.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    personality.subtitle,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingGoals(BuildContext context, StatsProvider stats) {
    final goal = stats.currentYearGoal;
    final year = stats.selectedYear ?? DateTime.now().year;
    final hasGoal = goal != null && (goal.bookGoal != null || goal.pageGoal != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              '$year Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showSetGoalDialog(context, stats, year),
              icon: Icon(hasGoal ? Icons.edit : Icons.add, size: 18),
              label: Text(hasGoal ? 'Edit' : 'Set Goal'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasGoal)
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: InkWell(
              onTap: () => _showSetGoalDialog(context, stats, year),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: AppTheme.textMuted,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set a reading goal for $year',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your progress and stay motivated!',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              if (goal.bookGoal != null)
                Expanded(
                  child: _GoalProgressRing(
                    current: stats.booksRead,
                    goal: goal.bookGoal!,
                    label: 'Books',
                    icon: Icons.menu_book,
                    color: AppTheme.readColor,
                  ),
                ),
              if (goal.bookGoal != null && goal.pageGoal != null)
                const SizedBox(width: 16),
              if (goal.pageGoal != null)
                Expanded(
                  child: _GoalProgressRing(
                    current: stats.pagesRead,
                    goal: goal.pageGoal!,
                    label: 'Pages',
                    icon: Icons.description_outlined,
                    color: AppTheme.currentlyReadingColor,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDidYouKnow(BuildContext context, StatsProvider stats) {
    final facts = stats.funFacts;
    if (stats.booksRead == 0) return const SizedBox.shrink();

    final funFactsList = <Map<String, String>>[];

    // Stack height
    final heightFeet = facts['stackHeightFeet'] as double;
    if (heightFeet >= 0.1) {
      funFactsList.add({
        'icon': '📏',
        'fact': 'Your books stacked would be ${heightFeet.toStringAsFixed(1)} feet tall!',
      });
    }

    // Words read
    final words = facts['wordsRead'] as int;
    if (words >= 10000) {
      final formatted = words >= 1000000
          ? '${(words / 1000000).toStringAsFixed(1)} million'
          : '${(words / 1000).toStringAsFixed(0)}K';
      funFactsList.add({
        'icon': '📝',
        'fact': 'You\'ve read approximately $formatted words!',
      });
    }

    // Harry Potter comparison
    final hp = facts['harryPotters'] as double;
    if (hp >= 0.5) {
      funFactsList.add({
        'icon': '⚡',
        'fact': 'That\'s ${hp.toStringAsFixed(1)}x the entire Harry Potter series!',
      });
    }

    // Hours reading
    final hours = facts['hoursReading'] as double;
    if (hours >= 10) {
      funFactsList.add({
        'icon': '⏰',
        'fact': 'You\'ve spent ~${hours.toStringAsFixed(0)} hours reading!',
      });
    }

    // Lord of the Rings
    final lotr = facts['lotrCount'] as double;
    if (lotr >= 1) {
      funFactsList.add({
        'icon': '💍',
        'fact': 'That\'s ${lotr.toStringAsFixed(1)}x the Lord of the Rings trilogy!',
      });
    }

    // War and Peace
    final wap = facts['warAndPeace'] as double;
    if (wap >= 1) {
      funFactsList.add({
        'icon': '📖',
        'fact': 'You could have read War and Peace ${wap.toStringAsFixed(1)} times!',
      });
    }

    if (funFactsList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Did You Know?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: funFactsList.length,
            itemBuilder: (context, index) {
              final fact = funFactsList[index];
              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                      AppTheme.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(fact['icon']!, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fact['fact']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoverCollage(BuildContext context, StatsProvider stats) {
    final allBooks = stats.topRatedBooks.where((b) => b.book?.coverUrl != null).toList();
    if (allBooks.isEmpty) return const SizedBox.shrink();

    // Sort by rating (highest first)
    allBooks.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    final books = allBooks.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_mosaic, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Reading Mosaic',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Horizontally scrollable book mosaic
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.08),
                Colors.amber.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < books.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  _buildMosaicBook(context, books[i], i),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMosaicBook(BuildContext context, UserBook book, int index) {
    final rating = book.rating ?? 3;
    final heroTag = 'mosaic-${book.bookId}';

    // Size based on rating - higher rated = bigger
    final width = switch (rating) {
      5 => 90.0,
      4 => 80.0,
      3 => 70.0,
      _ => 60.0,
    };
    final height = switch (rating) {
      5 => 140.0,
      4 => 120.0,
      3 => 100.0,
      _ => 85.0,
    };

    // Slight rotation for visual interest
    final rotation = (index % 3 - 1) * 0.03;

    return Transform.rotate(
      angle: rotation,
      child: _AnimatedBookTile(
        book: book,
        heroTag: heroTag,
        width: width,
        height: height,
        rating: rating,
      ),
    );
  }

  Widget _buildTrophyCase(BuildContext context, StatsProvider stats) {
    final unlocked = stats.unlockedAchievements;
    if (unlocked.isEmpty) return const SizedBox.shrink();

    // Group achievements and take the most impressive ones
    final displayAchievements = unlocked.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Trophy Case',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${unlocked.length} unlocked',
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade50,
                Colors.amber.shade100.withValues(alpha: 0.5),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: displayAchievements.map((achievement) {
              return _TrophyBadge(
                achievement: achievement,
                onTap: () => _showAchievementDetails(context, achievement),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => _showAllAchievements(context, stats),
            icon: const Icon(Icons.emoji_events_outlined, size: 18),
            label: Text(
              'View All Achievements (${unlocked.length}/${stats.allPossibleAchievements.length})',
            ),
          ),
        ),
      ],
    );
  }

  void _showAllAchievements(BuildContext context, StatsProvider stats) {
    final allAchievements = stats.allPossibleAchievements;
    final achievementsByCategory = stats.achievementsByCategory;
    final unlockedCount = allAchievements.where((a) => a.isUnlocked).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with overall progress
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 48), // Balance for close button
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 8),
                            Text(
                              'Achievement Hall',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Overall progress card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade50,
                          Colors.orange.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        // Circular progress
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: unlockedCount / allAchievements.length,
                                strokeWidth: 6,
                                backgroundColor: Colors.amber.shade100,
                                valueColor: AlwaysStoppedAnimation(Colors.amber.shade600),
                              ),
                              Text(
                                '${((unlockedCount / allAchievements.length) * 100).round()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$unlockedCount of ${allAchievements.length} Unlocked',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                unlockedCount == allAchievements.length
                                    ? '🎉 You\'ve unlocked them all!'
                                    : 'Keep reading to unlock more!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable categories
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: achievementsByCategory.length,
                itemBuilder: (context, index) {
                  final category = achievementsByCategory.keys.elementAt(index);
                  final achievements = achievementsByCategory[category]!;
                  final categoryUnlocked = achievements.where((a) => a.isUnlocked).length;

                  return _AchievementCategorySection(
                    category: category,
                    achievements: achievements,
                    unlockedCount: categoryUnlocked,
                    onAchievementTap: (achievement) =>
                        _showAchievementDetails(context, achievement),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTimeline(BuildContext context, StatsProvider stats) {
    final milestones = stats.readingMilestones;
    if (milestones.isEmpty) return const SizedBox.shrink();

    // Filter to selected year if applicable
    final year = stats.selectedYear;
    final filtered = year != null
        ? milestones.where((m) => (m['date'] as DateTime).year == year).toList()
        : milestones;

    if (filtered.isEmpty) return const SizedBox.shrink();

    // Take last 10 milestones for display, reversed (newest first)
    final displayMilestones = filtered.reversed.take(10).toList();
    final hasMore = filtered.length > 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading Journey',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${filtered.length} memorable moments',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasMore)
              TextButton(
                onPressed: () => _showAllMilestones(context, filtered),
                child: const Text('See All'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Journey Path - Fixed height, scrollable
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade50,
                Colors.purple.shade50,
                Colors.pink.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Decorative path
                Positioned(
                  left: 28,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.indigo.shade300,
                          Colors.purple.shade300,
                          Colors.pink.shade300,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Scrollable milestones
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: displayMilestones.asMap().entries.map((entry) {
                      final index = entry.key;
                      final milestone = entry.value;
                      return _JourneyMilestoneCard(
                        milestone: milestone,
                        index: index,
                        isFirst: index == 0,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAllMilestones(BuildContext context, List<Map<String, dynamic>> milestones) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade400, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Reading Journey',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${milestones.length} memorable moments',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: milestones.reversed.length,
                itemBuilder: (context, index) {
                  final milestone = milestones.reversed.toList()[index];
                  return _JourneyMilestoneCard(
                    milestone: milestone,
                    index: index,
                    isFirst: index == 0,
                    expanded: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrappedButton(BuildContext context, StatsProvider stats) {
    if (stats.booksRead == 0) return const SizedBox.shrink();

    final year = stats.selectedYear ?? DateTime.now().year;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ReadingWrappedScreen(year: year),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade600,
              Colors.pink.shade500,
              Colors.orange.shade400,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🎁', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your $year Wrapped',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Relive your reading journey',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill,
              color: Colors.white.withValues(alpha: 0.9),
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinTheWheel(BuildContext context) {
    final booksProvider = context.read<BooksProvider>();
    final tbrBooks = booksProvider.wantToReadBooks;

    if (tbrBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎰', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'What to Read Next?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Spin the wheel to pick from your ${tbrBooks.length} TBR books!',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Center(
          child: _SpinWheelButton(
            books: tbrBooks,
            onBookSelected: (book) {
              context.push('/book/${book.bookId}');
            },
          ),
        ),
      ],
    );
  }

  void _showSetGoalDialog(BuildContext context, StatsProvider stats, int year) {
    final goal = stats.getGoalForYear(year);
    final bookController = TextEditingController(
      text: goal?.bookGoal?.toString() ?? '',
    );
    final pageController = TextEditingController(
      text: goal?.pageGoal?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$year Reading Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bookController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Book Goal',
                hintText: 'e.g., 24',
                prefixIcon: Icon(Icons.menu_book),
                helperText: 'How many books do you want to read?',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Page Goal',
                hintText: 'e.g., 10000',
                prefixIcon: Icon(Icons.description_outlined),
                helperText: 'How many pages do you want to read?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final bookGoal = int.tryParse(bookController.text);
              final pageGoal = int.tryParse(pageController.text);

              if (bookGoal == null && pageGoal == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please set at least one goal')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await stats.setGoal(
                  year: year,
                  bookGoal: bookGoal,
                  pageGoal: pageGoal,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal saved!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save goal: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookSpineStack(BuildContext context, StatsProvider stats) {
    final readBooks = stats.topRatedBooks;
    if (readBooks.isEmpty) return const SizedBox.shrink();

    // Get actual books with page counts
    final booksWithPages = readBooks
        .where((b) => b.book != null)
        .take(12)
        .toList();

    if (booksWithPages.isEmpty) return const SizedBox.shrink();

    // Find max pages for scaling
    final maxPages = booksWithPages
        .map((b) => b.effectivePageCount ?? 250)
        .reduce((a, b) => a > b ? a : b);

    // Spine colors based on rating
    Color getSpineColor(int? rating) {
      switch (rating) {
        case 5: return Colors.amber.shade700;
        case 4: return Colors.green.shade700;
        case 3: return Colors.blue.shade700;
        case 2: return Colors.orange.shade700;
        case 1: return Colors.red.shade700;
        default: return Colors.grey.shade600;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown.shade400, Colors.brown.shade600],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Books by Page Count',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Taller = more pages • Color = your rating',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bookshelf visualization
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.amber.shade50,
                Colors.orange.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.brown.shade200),
          ),
          child: Column(
            children: [
              // Books row
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: booksWithPages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final userBook = entry.value;
                    final pages = userBook.effectivePageCount ?? 250;
                    final rating = userBook.rating;
                    final title = userBook.book?.title ?? 'Book';

                    // Height based on page count (min 50, max 120)
                    final height = 50.0 + (pages / maxPages) * 70;
                    final color = getSpineColor(rating);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
                          onTap: () => _showBookSpineDetail(context, userBook),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: height),
                            duration: Duration(milliseconds: 300 + index * 60),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Tooltip(
                                message: '$title\n$pages pages',
                                child: Container(
                                  height: value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        color,
                                        color.withValues(alpha: 0.7),
                                        color,
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 2,
                                        offset: const Offset(1, 0),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Spine highlight
                                      Positioned(
                                        left: 1,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 2,
                                          color: Colors.white.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      // Rating star for 5-star books
                                      if (rating == 5)
                                        const Positioned(
                                          top: 4,
                                          left: 0,
                                          right: 0,
                                          child: Icon(
                                            Icons.star,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Shelf
              Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.brown.shade400,
                      Colors.brown.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.shade900.withValues(alpha: 0.4),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem('5★', Colors.amber.shade700),
                  _buildLegendItem('4★', Colors.green.shade700),
                  _buildLegendItem('3★', Colors.blue.shade700),
                  _buildLegendItem('2★', Colors.orange.shade700),
                  _buildLegendItem('1★', Colors.red.shade700),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.brown.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showBookSpineDetail(BuildContext context, UserBook userBook) {
    final book = userBook.book;
    if (book == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (book.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.coverUrl!,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (book.authors.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                book.authors.join(', '),
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  Icons.menu_book,
                  '${userBook.effectivePageCount ?? "?"} pages',
                ),
                const SizedBox(width: 12),
                if (userBook.rating != null)
                  _buildStatChip(
                    Icons.star,
                    '${userBook.rating}/5',
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/book/${userBook.bookId}');
            },
            child: const Text('View Book'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progress ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge with status
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: isUnlocked
                        ? LinearGradient(
                            colors: [Colors.amber.shade200, Colors.amber.shade400],
                          )
                        : null,
                    color: isUnlocked ? null : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: TextStyle(
                        fontSize: 40,
                        color: isUnlocked ? null : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                if (isUnlocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isUnlocked ? '✓ UNLOCKED' : '🔒 LOCKED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            // Progress bar for locked achievements
            if (!isUnlocked && progress > 0) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.amber),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
            // How to unlock hint for locked achievements
            if (!isUnlocked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 20, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getUnlockHint(achievement),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isUnlocked ? 'Nice!' : 'Got it'),
          ),
        ],
      ),
    );
  }

  String _getUnlockHint(Achievement achievement) {
    // Category-specific hints
    switch (achievement.category) {
      case AchievementCategory.bookCount:
        return 'Keep reading! Mark books as "Read" to unlock this.';
      case AchievementCategory.pageCount:
        return 'Track your reading progress. Pages add up quickly!';
      case AchievementCategory.ratings:
        return 'Rate the books you finish to unlock this achievement.';
      case AchievementCategory.bookLength:
        return 'Try books of different lengths - short novellas to epic tomes!';
      case AchievementCategory.speed:
        return 'Set start and finish dates on your books to track reading speed.';
      case AchievementCategory.authors:
        return 'Found an author you love? Read more of their books!';
      case AchievementCategory.genres:
        return 'Explore different genres to become a well-rounded reader.';
      case AchievementCategory.rereads:
        return 'Some books deserve a second read. Re-read a favorite!';
      case AchievementCategory.yearly:
        return 'Set a reading goal and track your yearly progress.';
      case AchievementCategory.special:
        return 'This is a special achievement. Keep exploring!';
    }
  }

  Widget _buildYearPicker(BuildContext context, StatsProvider stats) {
    final years = stats.availableYears;
    const int allTimeValue = 0;

    return PopupMenuButton<int>(
      initialValue: stats.selectedYear ?? allTimeValue,
      onSelected: (year) => stats.setYear(year == allTimeValue ? null : year),
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stats.selectedYearLabel,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: allTimeValue,
          child: Row(
            children: [
              if (stats.selectedYear == null)
                Icon(Icons.check, size: 18, color: AppTheme.primaryColor)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              const Text('All Time'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...years.map((year) => PopupMenuItem<int>(
              value: year,
              child: Row(
                children: [
                  if (stats.selectedYear == year)
                    Icon(Icons.check, size: 18, color: AppTheme.primaryColor)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(year.toString()),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, StatsProvider stats) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_graph,
                  size: 80,
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No reading stats yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  stats.selectedYear != null
                      ? 'You haven\'t finished any books in ${stats.selectedYear}'
                      : 'Finish your first book to see your reading stats',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search),
                  label: const Text('Find Books'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, StatsProvider stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                value: stats.booksRead,
                label: 'Books Read',
                icon: Icons.menu_book,
                color: AppTheme.readColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatCard(
                value: stats.pagesRead,
                label: 'Pages',
                icon: Icons.description_outlined,
                color: AppTheme.currentlyReadingColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                value: stats.avgBookLength,
                label: 'Avg Pages',
                icon: Icons.straighten,
                color: AppTheme.wantToReadColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatCard(
                value: 0,
                decimalValue: stats.avgRating,
                label: 'Avg Rating',
                icon: Icons.star,
                color: Colors.amber,
                suffix: stats.avgRating > 0 ? '★' : null,
                isDecimal: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBooksGallery(BuildContext context, StatsProvider stats) {
    final books = stats.topRatedBooks;
    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Text(
              'Top Books',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Higher rated books appear larger',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final scale = stats.getBookScale(book);
              const baseWidth = 90.0;
              const baseHeight = 135.0;
              final heroTag = 'stats-book-${book.bookId}';

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.push('/book/${book.bookId}', extra: heroTag),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: baseWidth * scale,
                        height: baseHeight * scale,
                        child: BookCard(
                          book: book.book!,
                          heroTag: heroTag,
                          width: baseWidth * scale,
                          height: baseHeight * scale,
                        ),
                      ),
                      if (book.rating != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            book.rating!,
                            (_) => Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedStats(BuildContext context, StatsProvider stats) {
    final fastest = stats.fastestRead;
    final slowest = stats.slowestRead;
    final shortest = stats.shortestBook;
    final longest = stats.longestBook;

    if (fastest == null && shortest == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Reading Speed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (fastest != null)
                  _SpeedStatRow(
                    icon: Icons.bolt,
                    iconColor: Colors.orange,
                    label: 'Fastest Read',
                    bookTitle: fastest.book?.title ?? 'Unknown',
                    value: stats.getReadingDuration(fastest),
                  ),
                if (slowest != null && slowest != fastest) ...[
                  const Divider(height: 24),
                  _SpeedStatRow(
                    icon: Icons.hourglass_bottom,
                    iconColor: Colors.blue,
                    label: 'Slowest Read',
                    bookTitle: slowest.book?.title ?? 'Unknown',
                    value: stats.getReadingDuration(slowest),
                  ),
                ],
                if (shortest != null) ...[
                  const Divider(height: 24),
                  _SpeedStatRow(
                    icon: Icons.short_text,
                    iconColor: AppTheme.wantToReadColor,
                    label: 'Shortest Book',
                    bookTitle: shortest.book?.title ?? 'Unknown',
                    value: '${shortest.effectivePageCount} pages',
                  ),
                ],
                if (longest != null && longest != shortest) ...[
                  const Divider(height: 24),
                  _SpeedStatRow(
                    icon: Icons.menu_book,
                    iconColor: AppTheme.readColor,
                    label: 'Longest Book',
                    bookTitle: longest.book?.title ?? 'Unknown',
                    value: '${longest.effectivePageCount} pages',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context, StatsProvider stats) {
    final distribution = stats.ratingDistribution;
    final hasRatings = distribution.values.any((v) => v > 0);

    if (!hasRatings) return const SizedBox.shrink();

    final totalRatings = distribution.values.fold(0, (a, b) => a + b);
    final maxCount = distribution.values.reduce((a, b) => a > b ? a : b);
    final fiveStarBooks = stats.userHighestRated;
    final avgRating = stats.avgRating;

    // Calculate rating personality
    String getRatingPersonality() {
      if (avgRating >= 4.5) return '😍 Enthusiast';
      if (avgRating >= 4.0) return '😊 Optimist';
      if (avgRating >= 3.5) return '🤔 Balanced';
      if (avgRating >= 3.0) return '🧐 Discerning';
      return '😤 Tough Critic';
    }

    // Get color for each rating
    Color getRatingColor(int rating) {
      switch (rating) {
        case 5: return Colors.amber.shade500;
        case 4: return Colors.green.shade500;
        case 3: return Colors.blue.shade500;
        case 2: return Colors.orange.shade500;
        case 1: return Colors.red.shade500;
        default: return Colors.grey;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade400],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Your Ratings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Average rating showcase
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade50,
                Colors.orange.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              // Big average rating
              Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: avgRating),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final filled = i < avgRating.floor();
                      final partial = i == avgRating.floor() && avgRating % 1 > 0;
                      return Icon(
                        filled || partial ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber.shade600,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'avg rating',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Rating personality & stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        getRatingPersonality(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalRatings books rated',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fiveStarBooks.length} five-star favorites',
                      style: TextStyle(
                        color: Colors.amber.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rating distribution with colored bars
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Rating Breakdown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    'tap bars for details',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(5, (index) {
                final rating = 5 - index;
                final count = distribution[rating] ?? 0;
                final percentage = maxCount > 0 ? count / maxCount : 0.0;
                final color = getRatingColor(rating);
                final percent = totalRatings > 0
                    ? (count / totalRatings * 100).toStringAsFixed(0)
                    : '0';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: count > 0
                        ? () => _showBooksWithRating(context, stats, rating)
                        : null,
                    child: Row(
                      children: [
                        // Star icons
                        SizedBox(
                          width: 70,
                          child: Row(
                            children: List.generate(rating, (_) => Icon(
                              Icons.star,
                              size: 12,
                              color: color,
                            )),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Animated bar
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: percentage),
                            duration: Duration(milliseconds: 500 + index * 100),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Stack(
                                  children: [
                                    FractionallySizedBox(
                                      widthFactor: value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              color,
                                              color.withValues(alpha: 0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                    // Count inside bar
                                    if (count > 0)
                                      Positioned(
                                        left: 12,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: Text(
                                            '$count books',
                                            style: TextStyle(
                                              color: percentage > 0.3
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Percentage
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$percent%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: color,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // 5-star favorites - Hall of Fame
        if (fiveStarBooks.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade100,
                  Colors.orange.shade50,
                  Colors.amber.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade400, Colors.orange.shade400],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hall of Fame',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${fiveStarBooks.length} five-star favorites',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total pages in favorites
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${fiveStarBooks.fold<int>(0, (sum, b) => sum + (b.effectivePageCount ?? 0))}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                            Text(
                              'pages',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Featured book (first/most recent 5-star)
                if (fiveStarBooks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => context.push(
                        '/book/${fiveStarBooks.first.bookId}',
                        extra: 'stats-featured-${fiveStarBooks.first.bookId}',
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            // Book cover with crown
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Hero(
                                  tag: 'stats-featured-${fiveStarBooks.first.bookId}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: fiveStarBooks.first.book?.coverUrl != null
                                        ? Image.network(
                                            fiveStarBooks.first.book!.coverUrl!,
                                            width: 70,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 70,
                                            height: 100,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.book),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: -10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      '👑',
                                      style: TextStyle(
                                        fontSize: 20,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.amber.shade400, Colors.orange.shade400],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      '★ TOP PICK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    fiveStarBooks.first.book?.title ?? 'Unknown',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (fiveStarBooks.first.book?.authors.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      fiveStarBooks.first.book!.authors.first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ...List.generate(5, (_) => const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      )),
                                      if (fiveStarBooks.first.effectivePageCount != null) ...[
                                        const SizedBox(width: 12),
                                        Text(
                                          '${fiveStarBooks.first.effectivePageCount} pages',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.amber.shade400),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Other favorites
                if (fiveStarBooks.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: fiveStarBooks.length - 1,
                      itemBuilder: (context, index) {
                        final book = fiveStarBooks[index + 1];
                        final heroTag = 'stats-5star-${book.bookId}';
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => context.push('/book/${book.bookId}', extra: heroTag),
                            child: SizedBox(
                              width: 90,
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: book.book?.coverUrl != null
                                              ? Image.network(
                                                  book.book!.coverUrl!,
                                                  width: 80,
                                                  height: 110,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 80,
                                                  height: 110,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(Icons.book),
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.star, size: 10, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    book.book?.title ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showBooksWithRating(BuildContext context, StatsProvider stats, int rating) {
    final books = stats.topRatedBooks
        .where((b) => b.rating == rating && b.book != null)
        .toList();

    if (books.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ...List.generate(rating, (_) => Icon(
                    Icons.star,
                    color: Colors.amber.shade600,
                    size: 24,
                  )),
                  const SizedBox(width: 12),
                  Text(
                    '${books.length} Books',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final userBook = books[index];
                  final book = userBook.book!;
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: book.coverUrl != null
                          ? Image.network(
                              book.coverUrl!,
                              width: 40,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 40,
                              height: 60,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.book, size: 20),
                            ),
                    ),
                    title: Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      book.authors.isNotEmpty ? book.authors.first : '',
                      maxLines: 1,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/book/${userBook.bookId}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreStats(BuildContext context, StatsProvider stats) {
    final genres = stats.genreBreakdown;
    if (genres.isEmpty) return const SizedBox.shrink();

    final maxCount = genres.values.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Genres',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: genres.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final genreEntry = entry.value;
                final percentage = maxCount > 0 ? genreEntry.value / maxCount : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          genreEntry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: percentage),
                          duration: Duration(milliseconds: 500 + index * 80),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 16,
                                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${genreEntry.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorStats(BuildContext context, StatsProvider stats) {
    final authors = stats.authorBreakdown;
    if (authors.isEmpty) return const SizedBox.shrink();

    final filteredAuthors = authors.entries
        .where((e) => e.value > 1 || authors.length <= 5)
        .take(5)
        .toList();

    if (filteredAuthors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Favorite Authors',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Column(
            children: filteredAuthors.asMap().entries.map((entry) {
              final index = entry.key;
              final author = entry.value;
              final isFirst = index == 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isFirst
                      ? Colors.amber.shade100
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: isFirst
                      ? Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 20)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                title: Text(
                  author.key,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${author.value} books',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRereadStats(BuildContext context, StatsProvider stats) {
    final mostReread = stats.mostRereadBook;
    final rereadCount = stats.getMostRereadCount();
    final totalRereads = stats.totalRereadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Re-reads',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Simple stat row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Total re-reads
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$totalRereads',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade600,
                          ),
                    ),
                    Text(
                      'total re-reads',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              // Most re-read count
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${rereadCount}x',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade600,
                          ),
                    ),
                    Text(
                      'most re-read',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Most re-read book
        if (mostReread != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push(
              '/book/${mostReread.bookId}',
              extra: 'stats-reread-${mostReread.bookId}',
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: mostReread.book?.coverUrl != null
                        ? Image.network(
                            mostReread.book!.coverUrl!,
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 50,
                            height: 75,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.book, size: 24),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your go-to book',
                          style: TextStyle(
                            color: Colors.purple.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mostReread.book?.title ?? 'Unknown',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (mostReread.book?.authors.isNotEmpty == true)
                          Text(
                            mostReread.book!.authors.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Animated stat card with counting animation
class _AnimatedStatCard extends StatefulWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final String? suffix;
  final bool isDecimal;
  final double? decimalValue;

  const _AnimatedStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.suffix,
    this.isDecimal = false,
    this.decimalValue,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.decimalValue != widget.decimalValue) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedValue = widget.isDecimal
            ? (widget.decimalValue ?? 0) * _animation.value
            : (widget.value * _animation.value).round();

        final displayValue = widget.isDecimal
            ? (animatedValue as double).toStringAsFixed(1)
            : _formatNumber(animatedValue as int);

        return Card(
          elevation: 0,
          color: widget.color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: widget.color, size: 20),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayValue,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                    ),
                    if (widget.suffix != null) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          widget.suffix!,
                          style: TextStyle(
                            color: widget.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpeedStatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String bookTitle;
  final String value;

  const _SpeedStatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.bookTitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                bookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalProgressRing extends StatelessWidget {
  final int current;
  final int goal;
  final String label;
  final IconData icon;
  final Color color;

  const _GoalProgressRing({
    required this.current,
    required this.goal,
    required this.label,
    required this.icon,
    required this.color,
  });

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();
    final isComplete = current >= goal;

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComplete)
                        Icon(Icons.check_circle, color: color, size: 28)
                      else
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatNumber(current)} / ${_formatNumber(goal)}',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            if (isComplete) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Complete!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareCardWidget extends StatelessWidget {
  final StatsProvider stats;

  const _ShareCardWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    final personality = stats.readingPersonality;
    final topGenres = stats.genreBreakdown.entries.take(3).toList();
    final year = stats.selectedYear ?? DateTime.now().year;

    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            personality.color.withValues(alpha: 0.15),
            personality.color.withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: personality.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with personality
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: personality.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    personality.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personality.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: personality.color,
                      ),
                    ),
                    Text(
                      personality.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Year label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: personality.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stats.selectedYear != null ? '$year Stats' : 'All Time Stats',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: personality.color,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(
                value: stats.booksRead.toString(),
                label: 'Books',
                icon: Icons.menu_book,
                color: AppTheme.readColor,
              ),
              _StatColumn(
                value: _formatNumber(stats.pagesRead),
                label: 'Pages',
                icon: Icons.description_outlined,
                color: AppTheme.currentlyReadingColor,
              ),
              _StatColumn(
                value: stats.avgRating > 0
                    ? stats.avgRating.toStringAsFixed(1)
                    : '-',
                label: 'Avg Rating',
                icon: Icons.star,
                color: Colors.amber,
              ),
            ],
          ),
          if (topGenres.isNotEmpty) ...[
            const SizedBox(height: 24),
            // Top genres
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Top Genres',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: topGenres.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: personality.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.key} (${entry.value})',
                          style: TextStyle(
                            fontSize: 12,
                            color: personality.color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          // Achievements count
          if (stats.unlockedAchievements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${stats.unlockedAchievements.length} achievements unlocked',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          // Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                'Better Reads',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _JourneyMilestoneCard extends StatelessWidget {
  final Map<String, dynamic> milestone;
  final int index;
  final bool isFirst;
  final bool expanded;

  const _JourneyMilestoneCard({
    required this.milestone,
    required this.index,
    this.isFirst = false,
    this.expanded = false,
  });

  Color _getMilestoneColor(String type) {
    switch (type) {
      case 'book':
        return Colors.green;
      case 'pages':
        return Colors.blue;
      case 'rating':
        return Colors.amber;
      case 'length':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = milestone['date'] as DateTime;
    final type = milestone['type'] as String;
    final color = _getMilestoneColor(type);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: expanded ? 8 : 6,
      ),
      child: Row(
        children: [
          // Timeline node
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect for first item
              if (isFirst)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.8),
                      color,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    milestone['icon'] as String,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Content card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(expanded ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isFirst)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LATEST',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                milestone['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: expanded ? 16 : 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          milestone['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: expanded ? 14 : 12,
                          ),
                          maxLines: expanded ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getMonthAbbr(date.month),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (expanded)
                          Text(
                            '${date.year}',
                            style: TextStyle(
                              fontSize: 10,
                              color: color.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _TrophyBadge extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _TrophyBadge({
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade200,
                    Colors.amber.shade400,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 4,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCategorySection extends StatelessWidget {
  final AchievementCategory category;
  final List<Achievement> achievements;
  final int unlockedCount;
  final Function(Achievement) onAchievementTap;

  const _AchievementCategorySection({
    required this.category,
    required this.achievements,
    required this.unlockedCount,
    required this.onAchievementTap,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = unlockedCount == achievements.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.amber.shade50.withValues(alpha: 0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? Colors.amber.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isComplete
                  ? Colors.amber.shade100.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Text(
                  category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (isComplete) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '✓ COMPLETE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        category.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unlockedCount/${achievements.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isComplete ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hint for incomplete categories
          if (!isComplete)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getCategoryHint(category),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Achievement badges
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: achievements.map((achievement) {
                return _AllAchievementBadge(
                  achievement: achievement,
                  onTap: () => onAchievementTap(achievement),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryHint(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.bookCount:
        return '📖 Mark books as "Read" when you finish them';
      case AchievementCategory.pageCount:
        return '📄 Make sure your books have page counts set';
      case AchievementCategory.ratings:
        return '⭐ Tap on a book and rate it 1-5 stars';
      case AchievementCategory.bookLength:
        return '📏 Read short novellas AND epic tomes!';
      case AchievementCategory.speed:
        return '📅 Set start & finish dates to track reading speed';
      case AchievementCategory.authors:
        return '✍️ Find an author you love and read their catalog';
      case AchievementCategory.genres:
        return '🗺️ Branch out! Try new genres to unlock these';
      case AchievementCategory.rereads:
        return '🔄 Re-read an old favorite to unlock these';
      case AchievementCategory.yearly:
        return '📆 Keep reading consistently throughout the year';
      case AchievementCategory.special:
        return '🎭 These unlock through unique reading habits';
    }
  }
}

class _AllAchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _AllAchievementBadge({
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.progress ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring for locked achievements
              if (!isUnlocked && progress > 0)
                SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.amber.shade300),
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade200,
                            Colors.amber.shade400,
                          ],
                        )
                      : null,
                  color: isUnlocked ? null : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: 22,
                      color: isUnlocked ? null : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              // Lock icon for completely locked achievements
              if (!isUnlocked && progress == 0)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              // Checkmark for unlocked
              if (isUnlocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? null : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinWheelButton extends StatefulWidget {
  final List<UserBook> books;
  final Function(UserBook) onBookSelected;

  const _SpinWheelButton({
    required this.books,
    required this.onBookSelected,
  });

  @override
  State<_SpinWheelButton> createState() => _SpinWheelButtonState();
}

class _SpinWheelButtonState extends State<_SpinWheelButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSpinning = false;
  UserBook? _selectedBook;
  double _currentRotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning || widget.books.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _selectedBook = null;
    });

    // Pick a random book
    final random = math.Random();
    final selectedIndex = random.nextInt(widget.books.length);
    _selectedBook = widget.books[selectedIndex];

    // Calculate rotation (multiple full spins + landing position)
    final spins = 3 + random.nextDouble() * 2;
    final targetRotation = _currentRotation + (spins * 2 * math.pi);

    _controller.reset();

    final animation = Tween<double>(
      begin: _currentRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    animation.addListener(() {
      setState(() {
        _currentRotation = animation.value;
      });
    });

    _controller.forward().then((_) {
      setState(() {
        _isSpinning = false;
      });
      _showResult();
    });
  }

  void _showResult() {
    if (_selectedBook == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'You should read...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedBook!.book?.title ?? 'Unknown',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedBook!.book?.authors.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                'by ${_selectedBook!.book!.authors.join(", ")}',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
            if (_selectedBook!.book?.coverUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedBook!.book!.coverUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBookSelected(_selectedBook!);
            },
            child: const Text('View Book'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayBooks = widget.books.take(8).toList();
    final colors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.amber.shade400,
      Colors.green.shade400,
      Colors.teal.shade400,
      Colors.blue.shade400,
      Colors.indigo.shade400,
      Colors.purple.shade400,
    ];

    return Column(
      children: [
        GestureDetector(
          onTap: _spin,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wheel
                Transform.rotate(
                  angle: _currentRotation,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CustomPaint(
                        size: const Size(180, 180),
                        painter: _WheelPainter(
                          segments: displayBooks.length,
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
                ),
                // Center button
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSpinning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'SPIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                // Pointer
                Positioned(
                  top: 0,
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isSpinning ? 'Spinning...' : 'Tap to spin!',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final int segments;
  final List<Color> colors;

  _WheelPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * math.pi / segments;

    for (int i = 0; i < segments; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + (i * sweepAngle),
        sweepAngle,
        true,
        paint,
      );

      // Draw segment border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + (i * sweepAngle),
        sweepAngle,
        true,
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedBookTile extends StatefulWidget {
  final UserBook book;
  final String heroTag;
  final double width;
  final double height;
  final int rating;

  const _AnimatedBookTile({
    required this.book,
    required this.heroTag,
    required this.width,
    required this.height,
    required this.rating,
  });

  @override
  State<_AnimatedBookTile> createState() => _AnimatedBookTileState();
}

class _AnimatedBookTileState extends State<_AnimatedBookTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _liftAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _liftAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() async {
    // Play the "lift and scale" animation
    await _controller.forward();

    // Small delay for effect
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      // Navigate with Hero animation
      context.push('/book/${widget.book.bookId}', extra: widget.heroTag);
    }

    // Reset after navigation returns
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _liftAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _glowAnimation.value),
                      blurRadius: 8 + (_controller.value * 12),
                      offset: Offset(2, 4 + (_controller.value * 6)),
                      spreadRadius: _controller.value * 2,
                    ),
                  ],
                ),
                child: Hero(
                  tag: widget.heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.book.book!.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            child: const Icon(Icons.book, size: 24, color: Colors.white54),
                          ),
                        ),
                        // Star badge for 5-star books
                        if (widget.rating == 5)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.star, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
