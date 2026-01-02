import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Uncomment when Amplify is configured:
// import 'package:amplify_flutter/amplify_flutter.dart';
// import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// import 'amplifyconfiguration.dart';

import 'providers/auth_provider.dart';
import 'providers/books_provider.dart';
import 'router.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uncomment when Amplify is configured:
  // await _configureAmplify();

  runApp(const BetterReadsApp());
}

// Uncomment when Amplify is configured:
// Future<void> _configureAmplify() async {
//   try {
//     final auth = AmplifyAuthCognito();
//     await Amplify.addPlugins([auth]);
//     await Amplify.configure(amplifyconfig);
//     debugPrint('Amplify configured successfully');
//   } catch (e) {
//     debugPrint('Error configuring Amplify: $e');
//   }
// }

class BetterReadsApp extends StatelessWidget {
  const BetterReadsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BooksProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = createRouter(authProvider);

          return MaterialApp.router(
            title: 'Better Reads',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
