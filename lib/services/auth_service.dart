import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication (§4) — AUCUNE auth locale/codée en dur.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<void> signOut() => _auth.signOut();

  /// Traduit les erreurs Firebase en messages clairs (cas §21 :
  /// identifiants incorrects, compte existant, réseau...).
  static String messageOf(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email ou mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères min.)';
      case 'network-request-failed':
        return 'Erreur réseau — vérifiez votre connexion';
      case 'too-many-requests':
        return 'Trop de tentatives — réessayez plus tard';
      default:
        return 'Erreur d\'authentification (${e.code})';
    }
  }
}
