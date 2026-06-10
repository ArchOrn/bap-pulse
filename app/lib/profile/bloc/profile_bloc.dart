import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/profile/data/profile_api.dart';
import 'package:bap_pulse/profile/data/profile_models.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String userId;
  const ProfileLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();
}

class ProfileCleared extends ProfileEvent {
  const ProfileCleared();
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  /// Userid being loaded — kept for the refresh path.
  final String userId;
  const ProfileLoading(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile.user.id, profile.performance.score];
}

class ProfileError extends ProfileState {
  final String userId;
  final String message;
  const ProfileError({required this.userId, required this.message});
  @override
  List<Object?> get props => [userId, message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({ProfileApi? api})
    : _api = api ?? ProfileApi(),
      super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileRefreshRequested>(_onRefresh);
    on<ProfileCleared>((_, emit) => emit(const ProfileInitial()));
  }

  final ProfileApi _api;

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading(event.userId));
    await _fetch(event.userId, emit);
  }

  Future<void> _onRefresh(
    ProfileRefreshRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final userId = switch (state) {
      ProfileLoaded(:final profile) => profile.user.id,
      ProfileLoading(:final userId) => userId,
      ProfileError(:final userId) => userId,
      _ => null,
    };
    if (userId == null) return;
    emit(ProfileLoading(userId));
    await _fetch(userId, emit);
  }

  Future<void> _fetch(String userId, Emitter<ProfileState> emit) async {
    try {
      final profile = await _api.fetch(userId);
      emit(ProfileLoaded(profile));
    } on ApiException catch (e) {
      emit(ProfileError(userId: userId, message: e.message));
    } catch (_) {
      emit(
        ProfileError(
          userId: userId,
          message: 'Impossible de charger le profil.',
        ),
      );
    }
  }
}
