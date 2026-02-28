import 'package:firebase_auth/firebase_auth.dart';

/// Service d'authentification basé sur Firebase Auth.
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream des changements d'état d'authentification.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté, ou null.
  User? get currentUser => _auth.currentUser;

  /// Connexion avec email et mot de passe.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Création d'un compte avec email et mot de passe.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Déconnexion.
  Future<void> signOut() => _auth.signOut();
}
