import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bap_pulse/auth/data/auth_service.dart';
import 'package:bap_pulse/auth/data/auth_sync_api.dart';
import 'package:bap_pulse/auth/data/auth_account.dart';

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
  final String licenseNumber;
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.licenseNumber,
  });
  @override
  List<Object?> get props => [email, firstName, lastName, username, licenseNumber];
}

/// Re-runs `/auth/sync` to refresh the account status (e.g. the "Rafraîchir"
/// button on the pending-approval screen).
class AuthSyncRequested extends AuthEvent {
  const AuthSyncRequested();
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

  /// Account validation status, resolved by `/auth/sync` once authenticated.
  /// Null while the sync is in flight or after it failed (fail-closed: the
  /// router treats a null status on an authenticated user as blocked).
  final AccountStatus? accountStatus;

  /// True while `/auth/sync` is running (Firebase authed but status unknown).
  final bool syncing;

  const AuthState({
    required this.status,
    this.user,
    this.busy = false,
    this.error,
    this.resetEmailSent = false,
    this.accountStatus,
    this.syncing = false,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? busy,
    String? error,
    bool clearError = false,
    bool? resetEmailSent,
    AccountStatus? accountStatus,
    bool clearAccountStatus = false,
    bool? syncing,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
    resetEmailSent: resetEmailSent ?? this.resetEmailSent,
    accountStatus: clearAccountStatus ? null : (accountStatus ?? this.accountStatus),
    syncing: syncing ?? this.syncing,
  );

  @override
  List<Object?> get props => [
    status,
    user?.uid,
    busy,
    error,
    resetEmailSent,
    accountStatus,
    syncing,
  ];
}

// ── BLoC ───────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final AuthSyncApi _syncApi;
  StreamSubscription<User?>? _sub;

  // Profile fields captured at registration, consumed by the next sync.
  String? _pendingFirstName;
  String? _pendingLastName;
  String? _pendingNickname;
  String? _pendingLicense;

  AuthBloc({AuthService? authService, AuthSyncApi? syncApi})
    : _authService = authService ?? AuthService(),
      _syncApi = syncApi ?? AuthSyncApi(),
      super(const AuthState.unknown()) {
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthSyncRequested>(_onSyncRequested);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthErrorCleared>((_, emit) => emit(state.copyWith(clearError: true)));

    _sub = _authService.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  Future<void> _onUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user == null) {
      _clearPending();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
          clearAccountStatus: true,
          syncing: false,
          busy: false,
        ),
      );
      return;
    }

    // Firebase authed — status not yet known. Run the sync to resolve it.
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: event.user,
        clearError: true,
        clearAccountStatus: true,
        syncing: true,
      ),
    );
    await _runSync(emit);
  }

  Future<void> _runSync(Emitter<AuthState> emit) async {
    try {
      final result = await _syncApi.sync(
        firstName: _pendingFirstName,
        lastName: _pendingLastName,
        nickname: _pendingNickname,
        licenseNumber: _pendingLicense,
      );
      _clearPending();
      emit(
        state.copyWith(
          syncing: false,
          busy: false,
          accountStatus: result.status,
        ),
      );
    } catch (_) {
      _clearPending();
      // Fail-closed: no definitive status → stay blocked, surface a retry hint.
      emit(
        state.copyWith(
          syncing: false,
          busy: false,
          clearAccountStatus: true,
          error: 'Connexion au serveur impossible. Réessaie.',
        ),
      );
    }
  }

  Future<void> _onSyncRequested(
    AuthSyncRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated) return;
    emit(state.copyWith(syncing: true, clearError: true));
    await _runSync(emit);
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _authService.signIn(email: event.email, password: event.password);
      // _onUserChanged will fire, switch status and run the sync.
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
    // Stash profile + licence; the sync triggered by _onUserChanged sends them.
    _pendingFirstName = event.firstName.trim();
    _pendingLastName = event.lastName.trim();
    _pendingNickname = event.username.trim();
    _pendingLicense = event.licenseNumber.trim();
    try {
      await _authService.register(email: event.email, password: event.password);
      // _onUserChanged will fire and perform the sync with the stashed fields.
    } on FirebaseAuthException catch (e) {
      _clearPending();
      emit(state.copyWith(busy: false, error: _mapError(e)));
    } catch (_) {
      _clearPending();
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

  void _clearPending() {
    _pendingFirstName = null;
    _pendingLastName = null;
    _pendingNickname = null;
    _pendingLicense = null;
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
