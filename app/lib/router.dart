import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/discover_screen.dart';
import 'screens/search_screen.dart';
import 'screens/shelves_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/isbn_scanner_screen.dart';
import 'screens/shelf_contents_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/import_screen.dart';

GoRouter createRouter(AuthProvider authProvider, bool initiallyAuthenticated) {
  return GoRouter(
    initialLocation: initiallyAuthenticated ? '/' : '/sign-in',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation.startsWith('/verify-email');

      if (!isAuthenticated && !isAuthRoute) {
        return '/sign-in';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/sign-up',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email/:email',
        pageBuilder: (context, state) {
          final email = Uri.decodeComponent(state.pathParameters['email']!);
          return MaterialPage(
            key: state.pageKey,
            child: VerifyEmailScreen(email: email),
          );
        },
      ),

      // Main app with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavBar(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/shelves',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ShelvesScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // Book detail (outside shell for full screen)
      GoRoute(
        path: '/book/:isbn',
        pageBuilder: (context, state) {
          final isbn = state.pathParameters['isbn']!;
          final heroTag = state.extra as String?;
          return MaterialPage(
            key: state.pageKey,
            child: BookDetailScreen(isbn: isbn, heroTag: heroTag),
          );
        },
      ),

      // ISBN Scanner
      GoRoute(
        path: '/scan',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const IsbnScannerScreen(),
        ),
      ),

      // Custom Shelf Contents
      GoRoute(
        path: '/shelf/:shelfId',
        pageBuilder: (context, state) {
          final shelfId = state.pathParameters['shelfId']!;
          return MaterialPage(
            key: state.pageKey,
            child: ShelfContentsScreen(shelfId: shelfId),
          );
        },
      ),

      // Edit Profile
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),

      // Import from Goodreads
      GoRoute(
        path: '/import',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ImportScreen(),
        ),
      ),
    ],
  );
}

/// Scaffold with bottom navigation bar - used by ShellRoute
class ScaffoldWithNavBar extends StatelessWidget {
  final String location;
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.location,
    required this.child,
  });

  int _getCurrentIndex() {
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/shelves')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getCurrentIndex(),
        onDestinationSelected: (index) {
          FocusScope.of(context).unfocus();
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/shelves');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Shelves',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
