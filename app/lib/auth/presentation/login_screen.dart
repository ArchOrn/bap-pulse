import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bap_pulse/auth/auth_service.dart';

/// Compte de test en dev uniquement. Ne pas utiliser en prod.
const _devEmail = 'test@bap75.fr';
const _devPassword = 'testtest';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _auth = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = _authErrorMessage(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithDevAccount() async {
    if (!kDebugMode || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _devEmail,
        password: _devPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(e.code)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur dev: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Le mot de passe doit faire au moins 6 caractères.';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      default:
        return 'Erreur d\'authentification. Réessayez.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1411),
                  Color(0xFF102019),
                  Color(0xFF0B1B15),
                ],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF28F39B).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF28F39B).withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF28F39B),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF28F39B)
                                    .withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_tennis,
                            color: Color(0xFF052216),
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'BAP Pulse',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin
                            ? 'Connectez-vous à votre compte'
                            : 'Créez un compte',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12211B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF203229)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Bienvenue',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'vous@exemple.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Indiquez votre email';
                                }
                                if (!RegExp(
                                  r'^[\w.-]+@[\w.-]+\.\w+$',
                                ).hasMatch(v.trim())) {
                                  return 'Email invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                hintText: _isLogin ? null : 'Minimum 6 caractères',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    );
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Indiquez votre mot de passe';
                                }
                                if (!_isLogin && v.length < 6) {
                                  return 'Minimum 6 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF052216),
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Connexion' : 'Créer un compte',
                                    ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      _formKey.currentState?.reset();
                                      _passwordController.clear();
                                      setState(() => _isLogin = !_isLogin);
                                    },
                              child: Text(
                                _isLogin
                                    ? 'Pas de compte ? S\'inscrire'
                                    : 'Déjà un compte ? Se connecter',
                              ),
                            ),
                            if (kDebugMode) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed:
                                    _isLoading ? null : _signInWithDevAccount,
                                icon: const Icon(
                                  Icons.bug_report_outlined,
                                  size: 18,
                                ),
                                label: const Text('Connexion rapide (dev)'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
