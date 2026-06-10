import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bap_pulse/auth/data/auth_service.dart';

// ── Events ─────────────────────────────────────────────────────────────────

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Internal — emitted by the auth state stream subscription.
class _AuthUserChanged extends AuthEvent {
  final User? user;
  const _AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user?.uid];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String username;
  final String inviteCode;
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.inviteCode,
  });
  @override
  List<Object?> get props => [email, firstName, lastName, username];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

// ── State ──────────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final bool busy;
  final String? error;
  final bool resetEmailSent;

  const AuthState({
    required this.status,
    this.user,
    this.busy = false,
    this.error,
    this.resetEmailSent = false,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? busy,
    String? error,
    bool clearError = false,
    bool? resetEmailSent,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
    resetEmailSent: resetEmailSent ?? this.resetEmailSent,
  );

  @override
  List<Object?> get props => [status, user?.uid, busy, error, resetEmailSent];
}

// ── BLoC ───────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _sub;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(const AuthState.unknown()) {
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthErrorCleared>((_, emit) => emit(state.copyWith(clearError: true)));

    _sub = _authService.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        status: event.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: event.user,
        clearError: true,
        busy: false,
      ),
    );
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _authService.signIn(email: event.email, password: event.password);
      // _onUserChanged will fire and switch status.
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(busy: false, error: _mapError(e)));
    } catch (_) {
      emit(state.copyWith(busy: false, error: 'Une erreur est survenue.'));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      // NB: invite code, profile fields (firstName/lastName/username) will be
      // sent to the API in a follow-up. For now we only register on Firebase.
      await _authService.register(email: event.email, password: event.password);
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(busy: false, error: _mapError(e)));
    } catch (_) {
      emit(state.copyWith(busy: false, error: 'Une erreur est survenue.'));
    }
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearError: true, resetEmailSent: false));
    try {
      await _authService.sendPasswordResetEmail(event.email);
      emit(state.copyWith(busy: false, resetEmailSent: true));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(busy: false, error: _mapError(e)));
    } catch (_) {
      emit(state.copyWith(busy: false, error: 'Une erreur est survenue.'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.signOut();
  }

  String _mapError(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'Adresse email invalide.',
    'user-not-found' || 'invalid-credential' => 'Identifiants incorrects.',
    'wrong-password' => 'Mot de passe incorrect.',
    'email-already-in-use' => 'Cette adresse est déjà utilisée.',
    'weak-password' => 'Mot de passe trop faible (8 caractères minimum).',
    'network-request-failed' => 'Connexion réseau indisponible.',
    _ => e.message ?? 'Erreur d\'authentification.',
  };

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
