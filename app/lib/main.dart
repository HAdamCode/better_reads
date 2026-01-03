import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'amplifyconfiguration.dart';

import 'providers/auth_provider.dart' as app_auth;
import 'providers/books_provider.dart';
import 'providers/shelves_provider.dart';
import 'providers/lending_provider.dart';
import 'router.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await _configureAmplify();

  // Check auth status before starting the app
  final isAuthenticated = await _checkInitialAuthStatus();

  runApp(BetterReadsApp(initiallyAuthenticated: isAuthenticated));
}

Future<void> _configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    final api = AmplifyAPI();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugins([auth, api, storage]);
    await Amplify.configure(amplifyconfig);
    debugPrint('Amplify configured successfully');
  } on AmplifyAlreadyConfiguredException {
    debugPrint('Amplify was already configured');
  } catch (e) {
    debugPrint('Error configuring Amplify: $e');
  }
}

Future<bool> _checkInitialAuthStatus() async {
  try {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  } catch (e) {
    return false;
  }
}

class BetterReadsApp extends StatefulWidget {
  final bool initiallyAuthenticated;

  const BetterReadsApp({super.key, required this.initiallyAuthenticated});

  @override
  State<BetterReadsApp> createState() => _BetterReadsAppState();
}

class _BetterReadsAppState extends State<BetterReadsApp> {
  late final app_auth.AuthProvider _authProvider;
  late final BooksProvider _booksProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = app_auth.AuthProvider();
    _booksProvider = BooksProvider();
    _router = createRouter(_authProvider, widget.initiallyAuthenticated);

    // Listen for auth changes to navigate and sync data
    _authProvider.addListener(_onAuthStateChanged);

    // If already authenticated, sync books from backend
    if (widget.initiallyAuthenticated) {
      _booksProvider.syncFromBackend();
    }
  }

  void _onAuthStateChanged() {
    // Navigate based on new auth state
    if (_authProvider.isAuthenticated) {
      _router.go('/');
      // Sync books from backend when user logs in
      _booksProvider.syncFromBackend();
    } else if (_authProvider.status == app_auth.AuthStatus.unauthenticated) {
      _router.go('/sign-in');
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    _authProvider.dispose();
    _booksProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _booksProvider),
        ChangeNotifierProvider(create: (_) => ShelvesProvider()),
        ChangeNotifierProvider(create: (_) => LendingProvider()),
      ],
      child: MaterialApp.router(
        title: 'Better Reads',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
