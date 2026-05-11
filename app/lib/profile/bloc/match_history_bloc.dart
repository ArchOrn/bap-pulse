import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/profile/data/match_history_api.dart';
import 'package:bap_pulse/profile/data/match_history_models.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class MatchHistoryEvent extends Equatable {
  const MatchHistoryEvent();
  @override
  List<Object?> get props => [];
}

class MatchHistoryLoadRequested extends MatchHistoryEvent {
  final String userId;
  const MatchHistoryLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class MatchHistoryRefreshRequested extends MatchHistoryEvent {
  const MatchHistoryRefreshRequested();
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class MatchHistoryState extends Equatable {
  const MatchHistoryState();
  @override
  List<Object?> get props => [];
}

class MatchHistoryInitial extends MatchHistoryState {
  const MatchHistoryInitial();
}

class MatchHistoryLoading extends MatchHistoryState {
  final String userId;
  const MatchHistoryLoading(this.userId);
  @override
  List<Object?> get props => [userId];
}

class MatchHistoryLoaded extends MatchHistoryState {
  final String userId;
  final List<UserMatchEntry> matches;
  const MatchHistoryLoaded({required this.userId, required this.matches});
  @override
  List<Object?> get props => [userId, matches.length];
}

class MatchHistoryError extends MatchHistoryState {
  final String userId;
  final String message;
  const MatchHistoryError({required this.userId, required this.message});
  @override
  List<Object?> get props => [userId, message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class MatchHistoryBloc extends Bloc<MatchHistoryEvent, MatchHistoryState> {
  MatchHistoryBloc({MatchHistoryApi? api})
      : _api = api ?? MatchHistoryApi(),
        super(const MatchHistoryInitial()) {
    on<MatchHistoryLoadRequested>(_onLoad);
    on<MatchHistoryRefreshRequested>(_onRefresh);
  }

  final MatchHistoryApi _api;

  Future<void> _onLoad(
      MatchHistoryLoadRequested event, Emitter<MatchHistoryState> emit) async {
    emit(MatchHistoryLoading(event.userId));
    await _fetch(event.userId, emit);
  }

  Future<void> _onRefresh(MatchHistoryRefreshRequested event,
      Emitter<MatchHistoryState> emit) async {
    final userId = switch (state) {
      MatchHistoryLoaded(:final userId) => userId,
      MatchHistoryLoading(:final userId) => userId,
      MatchHistoryError(:final userId) => userId,
      _ => null,
    };
    if (userId == null) return;
    emit(MatchHistoryLoading(userId));
    await _fetch(userId, emit);
  }

  Future<void> _fetch(String userId, Emitter<MatchHistoryState> emit) async {
    try {
      final matches = await _api.fetch(userId);
      emit(MatchHistoryLoaded(userId: userId, matches: matches));
    } on ApiException catch (e) {
      emit(MatchHistoryError(userId: userId, message: e.message));
    } catch (_) {
      emit(MatchHistoryError(
        userId: userId,
        message: 'Impossible de charger l\'historique.',
      ));
    }
  }
}
