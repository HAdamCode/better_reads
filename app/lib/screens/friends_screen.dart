import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.person_add),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<FriendsProvider>().clearSearch();
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.syncFromBackend(),
            child: CustomScrollView(
              slivers: [
                // Search bar
                if (_showSearch)
                  SliverToBoxAdapter(
                    child: _buildSearchSection(context, provider),
                  ),

                // Friend requests section
                if (provider.friendRequests.isNotEmpty && !_showSearch) ...[
                  SliverToBoxAdapter(
                    child: _buildRequestsSection(context, provider),
                  ),
                ],

                // Search results
                if (_showSearch && provider.searchResults.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSearchResults(context, provider),
                  ),

                // Friends list
                if (!_showSearch) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Your Friends',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  if (provider.friends.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(context),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final friend = provider.friends[index];
                          final user = provider.getUserForFriend(friend);
                          return _buildFriendTile(context, user, friend.friendId);
                        },
                        childCount: provider.friends.length,
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, FriendsProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: provider.isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.clearSearch();
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                provider.searchUsers(value);
              } else if (value.isEmpty) {
                provider.clearSearch();
              }
            },
          ),
          if (provider.searchResults.isEmpty &&
              _searchController.text.length >= 2 &&
              !provider.isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  'No users found',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, FriendsProvider provider) {
    final currentUserId = context.read<AuthProvider>().userId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Search Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...provider.searchResults
            .where((user) => user.userId != currentUserId)
            .map((user) => _buildSearchResultTile(context, user, provider)),
      ],
    );
  }

  Widget _buildSearchResultTile(
      BuildContext context, User user, FriendsProvider provider) {
    final isFriend = provider.isFriend(user.userId);
    final hasPending = provider.hasPendingRequest(user.userId);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? Text(user.displayName.substring(0, 1).toUpperCase())
            : null,
      ),
      title: Text(user.displayName),
      subtitle: Text(user.handle.isNotEmpty ? '@${user.handle}' : user.email),
      trailing: isFriend
          ? Chip(
              label: const Text('Friends'),
              backgroundColor: Colors.green.shade100,
            )
          : hasPending
              ? Chip(
                  label: const Text('Pending'),
                  backgroundColor: Colors.orange.shade100,
                )
              : IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () async {
                    try {
                      await provider.sendFriendRequest(user.userId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Friend request sent to ${user.displayName}'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send request: $e')),
                        );
                      }
                    }
                  },
                ),
    );
  }

  Widget _buildRequestsSection(BuildContext context, FriendsProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.person_add, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Friend Requests (${provider.friendRequests.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          ...provider.friendRequests.map((request) {
            final user = provider.getUserForRequest(request);
            return _buildRequestTile(context, user, request.userId, provider);
          }),
        ],
      ),
    );
  }

  Widget _buildRequestTile(BuildContext context, User? user, String requesterId,
      FriendsProvider provider) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
        child: user?.avatarUrl == null
            ? Text(user?.displayName.substring(0, 1).toUpperCase() ?? '?')
            : null,
      ),
      title: Text(user?.displayName ?? 'Unknown User'),
      subtitle: user?.handle.isNotEmpty == true ? Text('@${user!.handle}') : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () async {
              try {
                await provider.acceptRequest(requesterId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user?.displayName ?? 'User'} is now your friend!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to accept: $e')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () async {
              try {
                await provider.declineRequest(requesterId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to decline: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, User? user, String friendId) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
        child: user?.avatarUrl == null
            ? Text(user?.displayName.substring(0, 1).toUpperCase() ?? '?')
            : null,
      ),
      title: Text(user?.displayName ?? 'Loading...'),
      subtitle: user?.bio != null && user!.bio!.isNotEmpty
          ? Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/user/$friendId');
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find friends to see what they\'re reading',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _showSearch = true;
                });
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Find Friends'),
            ),
          ],
        ),
      ),
    );
  }
}
