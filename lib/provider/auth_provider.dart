import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();

      if (user != null) {
        debugPrint('✅ User logged in: ${user.email}');
      } else {
        debugPrint('❌ User logged out');
      }
    });
  }

  Future<bool> _executeAuth(
      Future<void> Function() operation, {
        String? errorPrefix,
      }) async {
    try {
      _setLoading(true);
      _clearError();
      await operation();
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('${errorPrefix ?? "Operation failed"}: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _refreshUser() async {
    _user = _authService.currentUser;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    debugPrint('❌ Auth Error: $message');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _executeAuth(
            () => _authService.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        ),
        errorPrefix: 'Sign up gagal',
      );

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _executeAuth(
            () => _authService.signInWithEmail(email: email, password: password),
        errorPrefix: 'Sign in gagal',
      );

  Future<bool> signInWithGoogle() => _executeAuth(
    _authService.signInWithGoogle,
    errorPrefix: 'Google Sign-In gagal',
  );

  Future<bool> sendPasswordResetEmail(String email) => _executeAuth(
        () => _authService.sendPasswordResetEmail(email),
    errorPrefix: 'Gagal mengirim email reset',
  );

  Future<bool> updateDisplayName(String displayName) async {
    final result = await _executeAuth(
          () => _authService.updateDisplayName(displayName),
      errorPrefix: 'Gagal update nama',
    );
    if (result) await _refreshUser();
    return result;
  }

  Future<bool> updatePassword(String newPassword) => _executeAuth(
        () => _authService.updatePassword(newPassword),
    errorPrefix: 'Gagal update password',
  );

  Future<bool> reauthenticateWithEmail({
    required String email,
    required String password,
  }) =>
      _executeAuth(
            () => _authService.reauthenticateWithEmail(
          email: email,
          password: password,
        ),
        errorPrefix: 'Re-authentication gagal',
      );

  Future<bool> signOut() => _executeAuth(
    _authService.signOut,
    errorPrefix: 'Sign out gagal',
  );

}