import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _email;
  String? _displayName;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get email => _email;
  String? get displayName => _displayName;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        await _fetchUserAttributes();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _fetchUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      for (final attr in attributes) {
        if (attr.userAttributeKey == AuthUserAttributeKey.email) {
          _email = attr.value;
        } else if (attr.userAttributeKey == AuthUserAttributeKey.name) {
          _displayName = attr.value;
        }
      }

      final user = await Amplify.Auth.getCurrentUser();
      _userId = user.userId;
    } catch (e) {
      debugPrint('Error fetching user attributes: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            AuthUserAttributeKey.name: displayName,
          },
        ),
      );

      if (result.isSignUpComplete) {
        // Auto sign in after sign up
        await signIn(email: email, password: password);
      }
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );

      if (!result.isSignUpComplete) {
        throw AuthProviderException('Sign up confirmation failed');
      }
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        await _fetchUserAttributes();
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      _status = AuthStatus.unauthenticated;
      _userId = null;
      _email = null;
      _displayName = null;
      notifyListeners();
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await Amplify.Auth.resetPassword(username: email);
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }

  Future<void> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } on AuthException catch (e) {
      throw AuthProviderException(e.message);
    }
  }
}

class AuthProviderException implements Exception {
  final String message;

  AuthProviderException(this.message);

  @override
  String toString() => message;
}
