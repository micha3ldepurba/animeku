import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Set display name jika disediakan
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final credential = await _performGoogleSignIn();
    return await _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Failed to send reset email: ${e.toString()}');
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    await _updateUserProfile(() async {
      await _requireUser().updateDisplayName(displayName.trim());
    }, 'display name');
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _requireUser().updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to update password: ${e.toString()}');
    }
  }

  Future<void> reauthenticateWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await _requireUser().reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Re-authentication failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out dari kedua service
      // Note: Menggunakan signOut() bukan disconnect() agar user bisa login lagi
      // tanpa harus memilih akun Google lagi
      await Future.wait([
        _auth.signOut(),
        GoogleSignIn.instance.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  User _requireUser() {
    final user = currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in');
    }
    return user;
  }

  Future<void> _updateUserProfile(
      Future<void> Function() updateFn,
      String fieldName,
      ) async {
    try {
      await updateFn();
      await _requireUser().reload();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to update $fieldName: ${e.toString()}');
    }
  }

  Future<AuthCredential> _performGoogleSignIn() async {
    try {
      GoogleSignInAccount? googleUser;

      if (GoogleSignIn.instance.supportsAuthenticate()) {
        final completer = Completer<GoogleSignInAccount?>();
        StreamSubscription<GoogleSignInAuthenticationEvent>? subscription;

        subscription = GoogleSignIn.instance.authenticationEvents.listen(
              (event) {
            if (!completer.isCompleted) {
              switch (event) {
                case GoogleSignInAuthenticationEventSignIn():
                  completer.complete(event.user);
                  subscription?.cancel();
                case GoogleSignInAuthenticationEventSignOut():
                  completer.complete(null);
                  subscription?.cancel();
              }
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
              subscription?.cancel();
            }
          },
        );

        try {
          await GoogleSignIn.instance.authenticate();
          googleUser = await completer.future.timeout(
            const Duration(seconds: 30),
          );
        } catch (e) {
          subscription.cancel();
          rethrow;
        }
      } else {
        throw AuthException('Google Sign-In tidak didukung pada platform ini');
      }

      if (googleUser == null) {
        throw AuthException('Google Sign-In dibatalkan oleh user');
      }

      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw AuthException('Gagal mendapatkan ID token dari Google');
      }

      return GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    } on GoogleSignInException catch (e) {
      throw _handleGoogleSignInException(e);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on TimeoutException {
      throw AuthException('Google Sign-In timeout. Silakan coba lagi.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google Sign-In gagal: ${e.toString()}');
    }
  }

  AuthException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
    // Sign Up Errors
      case 'weak-password':
        return AuthException('Password terlalu lemah. Minimal 6 karakter.');
      case 'email-already-in-use':
        return AuthException(
          'Email sudah terdaftar. Silakan login atau gunakan email lain.',
        );

    // Sign In Errors
      case 'user-not-found':
        return AuthException(
          'Email tidak terdaftar. Silakan daftar terlebih dahulu.',
        );
      case 'wrong-password':
        return AuthException('Password salah. Silakan coba lagi.');
      case 'invalid-credential':
        return AuthException('Email atau password salah.');
      case 'user-disabled':
        return AuthException(
          'Akun ini telah dinonaktifkan. Hubungi administrator.',
        );

    // Email Errors
      case 'invalid-email':
        return AuthException('Format email tidak valid.');

    // Rate Limiting
      case 'too-many-requests':
        return AuthException(
          'Terlalu banyak percobaan. Silakan coba lagi nanti.',
        );

    // Requires Recent Login
      case 'requires-recent-login':
        return AuthException(
          'Operasi sensitif. Silakan logout dan login kembali.',
        );

    // Network Errors
      case 'network-request-failed':
        return AuthException(
          'Tidak ada koneksi internet. Periksa koneksi Anda.',
        );

    // Operation Not Allowed
      case 'operation-not-allowed':
        return AuthException('Operasi tidak diizinkan. Hubungi administrator.');

    // Default
      default:
        return AuthException('Error: ${e.message ?? e.code}');
    }
  }

  AuthException _handleGoogleSignInException(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return AuthException('Google Sign-In dibatalkan oleh user');
      default:
        return AuthException(
          'Google Sign-In error: ${e.description ?? e.code.name}',
        );
    }
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}