import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/leaderboard/data/leaderboard_api.dart';
import 'package:bap_pulse/leaderboard/data/leaderboard_models.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();
  @override
  List<Object?> get props => [];
}

class LeaderboardLoadRequested extends LeaderboardEvent {
  final LeaderboardCriterion criterion;
  const LeaderboardLoadRequested(this.criterion);
  @override
  List<Object?> get props => [criterion];
}

/// User tapped a different criterion chip. Returns the cached entries when
/// available, otherwise triggers a fetch.
class LeaderboardCriterionChanged extends LeaderboardEvent {
  final LeaderboardCriterion criterion;
  const LeaderboardCriterionChanged(this.criterion);
  @override
  List<Object?> get props => [criterion];
}

/// Force-refetch the current criterion (invalidates its cache entry).
class LeaderboardRefreshRequested extends LeaderboardEvent {
  const LeaderboardRefreshRequested();
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class LeaderboardState extends Equatable {
  const LeaderboardState();

  /// Per-criterion cache. Surviving across criterion changes lets us flip
  /// between chips without re-hitting the network.
  Map<LeaderboardCriterion, List<LeaderboardEntry>> get cache => const {};

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  final LeaderboardCriterion criterion;
  @override
  final Map<LeaderboardCriterion, List<LeaderboardEntry>> cache;

  const LeaderboardLoading({required this.criterion, this.cache = const {}});

  @override
  List<Object?> get props => [criterion, cache];
}

class LeaderboardLoaded extends LeaderboardState {
  final LeaderboardCriterion criterion;
  final List<LeaderboardEntry> entries;
  @override
  final Map<LeaderboardCriterion, List<LeaderboardEntry>> cache;

  const LeaderboardLoaded({
    required this.criterion,
    required this.entries,
    required this.cache,
  });

  @override
  List<Object?> get props => [criterion, entries.length, cache.length];
}

class LeaderboardError extends LeaderboardState {
  final LeaderboardCriterion criterion;
  final String message;
  @override
  final Map<LeaderboardCriterion, List<LeaderboardEntry>> cache;

  const LeaderboardError({
    required this.criterion,
    required this.message,
    this.cache = const {},
  });

  @override
  List<Object?> get props => [criterion, message, cache];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  LeaderboardBloc({LeaderboardApi? api})
    : _api = api ?? LeaderboardApi(),
      super(const LeaderboardInitial()) {
    on<LeaderboardLoadRequested>(_onLoad);
    on<LeaderboardCriterionChanged>(_onCriterionChanged);
    on<LeaderboardRefreshRequested>(_onRefresh);
  }

  final LeaderboardApi _api;

  Future<void> _onLoad(
    LeaderboardLoadRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    final cache = state.cache;
    final cached = cache[event.criterion];
    if (cached != null) {
      emit(
        LeaderboardLoaded(
          criterion: event.criterion,
          entries: cached,
          cache: cache,
        ),
      );
      return;
    }
    emit(LeaderboardLoading(criterion: event.criterion, cache: cache));
    await _fetch(event.criterion, emit, cache);
  }

  Future<void> _onCriterionChanged(
    LeaderboardCriterionChanged event,
    Emitter<LeaderboardState> emit,
  ) async {
    final cache = state.cache;
    final cached = cache[event.criterion];
    if (cached != null) {
      emit(
        LeaderboardLoaded(
          criterion: event.criterion,
          entries: cached,
          cache: cache,
        ),
      );
      return;
    }
    emit(LeaderboardLoading(criterion: event.criterion, cache: cache));
    await _fetch(event.criterion, emit, cache);
  }

  Future<void> _onRefresh(
    LeaderboardRefreshRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    final criterion = switch (state) {
      LeaderboardLoaded(:final criterion) => criterion,
      LeaderboardLoading(:final criterion) => criterion,
      LeaderboardError(:final criterion) => criterion,
      _ => null,
    };
    if (criterion == null) return;
    final cache = Map.of(state.cache)..remove(criterion);
    emit(LeaderboardLoading(criterion: criterion, cache: cache));
    await _fetch(criterion, emit, cache);
  }

  Future<void> _fetch(
    LeaderboardCriterion criterion,
    Emitter<LeaderboardState> emit,
    Map<LeaderboardCriterion, List<LeaderboardEntry>> _,
  ) async {
    try {
      final entries = await _api.fetch(criterion);
      // Read state.cache (live) rather than the captured snapshot so that
      // concurrent fetches (e.g. jerseys screen kicking off all 4 criteria
      // at once) merge additively instead of last-writer-wins.
      final next = Map.of(state.cache)..[criterion] = entries;
      emit(
        LeaderboardLoaded(criterion: criterion, entries: entries, cache: next),
      );
    } on ApiException catch (e) {
      emit(
        LeaderboardError(
          criterion: criterion,
          message: e.message,
          cache: state.cache,
        ),
      );
    } catch (_) {
      emit(
        LeaderboardError(
          criterion: criterion,
          message: 'Impossible de charger le classement.',
          cache: state.cache,
        ),
      );
    }
  }
}
