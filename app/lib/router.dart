import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/shelves_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/isbn_scanner_screen.dart';
import 'widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation.startsWith('/verify-email');

      // If not authenticated and not on auth route, redirect to sign in
      if (!isAuthenticated && !isAuthRoute) {
        return '/sign-in';
      }

      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/verify-email/:email',
        builder: (context, state) {
          final email = Uri.decodeComponent(state.pathParameters['email']!);
          return VerifyEmailScreen(email: email);
        },
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/shelves',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ShelvesScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Book detail (outside shell for full screen)
      GoRoute(
        path: '/book/:isbn',
        builder: (context, state) {
          final isbn = state.pathParameters['isbn']!;
          return BookDetailScreen(isbn: isbn);
        },
      ),

      // ISBN Scanner
      GoRoute(
        path: '/scan',
        builder: (context, state) => const IsbnScannerScreen(),
      ),
    ],
  );
}
