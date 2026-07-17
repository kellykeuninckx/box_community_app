import 'package:firebase_auth/firebase_auth.dart';

/// Wikkelt Firebase Auth in met vriendelijke, Nederlandse foutmeldingen.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Dit e-mailadres is al in gebruik.';
      case 'invalid-email':
        return 'Dit is geen geldig e-mailadres.';
      case 'weak-password':
        return 'Dit wachtwoord is te zwak — gebruik minstens 6 tekens.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mailadres of wachtwoord klopt niet.';
      default:
        return 'Er ging iets mis. Probeer het opnieuw.';
    }
  }
}