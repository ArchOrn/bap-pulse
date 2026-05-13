import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:bap_pulse/notifications/data/fcm_service.dart';
import 'package:bap_pulse/notifications/data/notifications_repository.dart';
import 'package:bap_pulse/shared/models/notification.dart';

// ── Events ─────────────────────────────────────────────────────────────────

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested();
}

class NotificationsRefreshRequested extends NotificationsEvent {
  const NotificationsRefreshRequested();
}

class NotificationsMarkAllReadRequested extends NotificationsEvent {
  const NotificationsMarkAllReadRequested();
}

class NotificationsMarkReadRequested extends NotificationsEvent {
  final String id;
  const NotificationsMarkReadRequested(this.id);
  @override
  List<Object?> get props => [id];
}

/// Internal — triggered by an incoming FCM message while the app is open.
class _NotificationsPushReceived extends NotificationsEvent {
  const _NotificationsPushReceived();
}

/// Internal — clears state when the user signs out.
class NotificationsCleared extends NotificationsEvent {
  const NotificationsCleared();
}

// ── State ──────────────────────────────────────────────────────────────────

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<AppNotification> items;
  final int unreadCount;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
  }) =>
      NotificationsState(
        status: status ?? this.status,
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, items, unreadCount, errorMessage];
}

// ── BLoC ───────────────────────────────────────────────────────────────────

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _repo;
  StreamSubscription<RemoteMessage>? _pushSub;

  NotificationsBloc({NotificationsRepository? repo})
      : _repo = repo ?? NotificationsRepository.instance,
        super(const NotificationsState()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationsRefreshRequested>(_onRefresh);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationsMarkReadRequested>(_onMarkRead);
    on<_NotificationsPushReceived>(_onPushReceived);
    on<NotificationsCleared>((_, emit) => emit(const NotificationsState()));

    _pushSub = FcmService.instance.onForegroundMessage
        .listen((_) => add(const _NotificationsPushReceived()));
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.status == NotificationsStatus.loaded) return;
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    NotificationsRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _onPushReceived(
    _NotificationsPushReceived event,
    Emitter<NotificationsState> emit,
  ) async {
    // A new push arrived — the API has already persisted it. Re-fetch so the
    // notification center and the unread badge stay accurate.
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<NotificationsState> emit) async {
    try {
      final items = await _repo.list();
      final unread = items.where((n) => n.isUnread).length;
      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: items,
        unreadCount: unread,
        clearError: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onMarkRead(
    NotificationsMarkReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistic update first — UI feels snappier and the worst case is a
    // server hiccup leaving one notification visually-read until next refresh.
    final next = state.items.map((n) {
      if (n.id != event.id || n.readAt != null) return n;
      return n.copyWith(readAt: DateTime.now());
    }).toList();
    final unread = next.where((n) => n.isUnread).length;
    emit(state.copyWith(items: next, unreadCount: unread));

    try {
      await _repo.markRead(event.id);
    } on Exception {/* swallow — refresh on next open if needed */}
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final now = DateTime.now();
    final next = state.items
        .map((n) => n.readAt == null ? n.copyWith(readAt: now) : n)
        .toList();
    emit(state.copyWith(items: next, unreadCount: 0));

    try {
      await _repo.markAllRead();
    } on Exception {/* swallow — server will catch up on next refresh */}
  }

  @override
  Future<void> close() async {
    await _pushSub?.cancel();
    return super.close();
  }
}
