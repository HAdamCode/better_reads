import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/user_book.dart';
import '../providers/friends_provider.dart';
import '../services/book_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  List<UserBook> _books = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<FriendsProvider>();

      // Fetch user details
      final user = await provider.fetchUser(widget.userId);
      if (user == null) {
        throw Exception('User not found');
      }

      // Fetch user's books
      final books = await provider.fetchUserBooks(widget.userId);

      // Enrich books with metadata from book service
      final bookService = BookService();
      for (int i = 0; i < books.length; i++) {
        if (books[i].book == null) {
          try {
            final bookData = await bookService.getBookByIsbn(books[i].bookId);
            if (bookData != null) {
              books[i] = books[i].copyWith(book: bookData);
            }
          } catch (e) {
            // Ignore errors fetching individual book metadata
          }
        }
      }

      if (mounted) {
        setState(() {
          _user = user;
          _books = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.displayName ?? 'Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Could not load profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadUserData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final readBooks = _books.where((b) => b.readingStatus == ReadingStatus.read).toList();
    final currentlyReading = _books.where((b) => b.readingStatus == ReadingStatus.currentlyReading).toList();
    final wantToRead = _books.where((b) => b.readingStatus == ReadingStatus.wantToRead).toList();

    final totalPages = readBooks.fold<int>(
      0,
      (sum, book) => sum + (book.effectivePageCount ?? 0),
    );

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            _buildProfileHeader(),

            // Stats row
            _buildStatsRow(readBooks.length, currentlyReading.length, totalPages),

            // Recently read section
            if (readBooks.isNotEmpty) ...[
              _buildSectionHeader('Recently Read'),
              _buildBookRow(readBooks.take(10).toList()),
            ],

            // Currently reading section
            if (currentlyReading.isNotEmpty) ...[
              _buildSectionHeader('Currently Reading'),
              _buildBookRow(currentlyReading),
            ],

            // Want to read section
            if (wantToRead.isNotEmpty) ...[
              _buildSectionHeader('Want to Read'),
              _buildBookRow(wantToRead.take(10).toList()),
            ],

            // Empty state
            if (_books.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_user?.displayName} hasn\'t added any books yet',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Remove friend button
            _buildRemoveFriendButton(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                _user?.avatarUrl != null ? NetworkImage(_user!.avatarUrl!) : null,
            child: _user?.avatarUrl == null
                ? Text(
                    _user?.displayName.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.displayName ?? 'Unknown',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_user?.handle.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '@${_user!.handle}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (_user?.bio != null && _user!.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _user!.bio!,
                      style: TextStyle(color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int booksRead, int currentlyReading, int totalPages) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              booksRead.toString(),
              'Books Read',
              Icons.book,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildStatItem(
              currentlyReading.toString(),
              'Reading',
              Icons.auto_stories,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildStatItem(
              _formatNumber(totalPages),
              'Pages',
              Icons.description,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildBookRow(List<UserBook> books) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final userBook = books[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                context.push('/book/${userBook.bookId}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: userBook.book?.coverUrl != null
                        ? Image.network(
                            userBook.book!.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(userBook),
                          )
                        : _buildPlaceholder(userBook),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(UserBook userBook) {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            userBook.book?.title ?? 'Book',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveFriendButton() {
    final provider = context.read<FriendsProvider>();
    final isFriend = provider.isFriend(widget.userId);

    if (!isFriend) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: OutlinedButton.icon(
        onPressed: () => _showRemoveFriendDialog(),
        icon: const Icon(Icons.person_remove, color: Colors.red),
        label: const Text('Remove Friend', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showRemoveFriendDialog() {
    final provider = context.read<FriendsProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${_user?.displayName ?? 'this user'} as a friend?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await provider.removeFriend(widget.userId);
                if (mounted) {
                  context.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Friend removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to remove friend: $e')),
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
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
