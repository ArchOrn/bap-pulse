import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/challenges/data/challenges_repository.dart';
import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/notifications/bloc/notifications_bloc.dart';
import 'package:bap_pulse/notifications/presentation/notification_card.dart';
import 'package:bap_pulse/shared/models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<NotificationsBloc>();
    if (bloc.state.status == NotificationsStatus.initial) {
      bloc.add(const NotificationsLoadRequested());
    } else {
      bloc.add(const NotificationsRefreshRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      appBar: AppBar(
        backgroundColor: AppColors.bgScaffold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<NotificationsBloc>().add(
                  const NotificationsMarkAllReadRequested(),
                ),
                child: const Text(
                  'Tout lu',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.status == NotificationsStatus.loading &&
              state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NotificationsStatus.error &&
              state.items.isEmpty) {
            return _ErrorState(
              message: state.errorMessage ?? 'Une erreur est survenue.',
              onRetry: () => context.read<NotificationsBloc>().add(
                const NotificationsRefreshRequested(),
              ),
            );
          }
          if (state.items.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => context.read<NotificationsBloc>().add(
              const NotificationsRefreshRequested(),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final notif = state.items[i];
                return NotificationCard(
                  notification: notif,
                  onTap: () => _onTap(notif),
                  primary: _primaryAction(notif),
                  secondary: _secondaryAction(notif),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _markRead(AppNotification n) {
    if (n.isUnread) {
      context.read<NotificationsBloc>().add(
        NotificationsMarkReadRequested(n.id),
      );
    }
  }

  void _onTap(AppNotification n) {
    _markRead(n);
    final matchId = n.matchId;
    if ((n.type == AppNotificationType.matchAwaitingConfirmation ||
            n.type == AppNotificationType.matchConfirmed ||
            n.type == AppNotificationType.matchContested) &&
        matchId != null) {
      context.push('/score/validate/$matchId');
    }
  }

  ({String label, VoidCallback onPressed})? _primaryAction(AppNotification n) {
    if (n.type == AppNotificationType.challengeReceived &&
        n.challengeId != null) {
      return (
        label: 'Accepter',
        onPressed: () => _respondChallenge(n, accept: true),
      );
    }
    if (n.type == AppNotificationType.matchAwaitingConfirmation &&
        n.matchId != null) {
      return (
        label: 'Confirmer',
        onPressed: () => context.push('/score/validate/${n.matchId}'),
      );
    }
    return null;
  }

  ({String label, VoidCallback onPressed})? _secondaryAction(
    AppNotification n,
  ) {
    if (n.type == AppNotificationType.challengeReceived &&
        n.challengeId != null) {
      return (
        label: 'Refuser',
        onPressed: () => _respondChallenge(n, accept: false),
      );
    }
    return null;
  }

  Future<void> _respondChallenge(
    AppNotification n, {
    required bool accept,
  }) async {
    final id = n.challengeId;
    if (id == null) return;
    _markRead(n);
    try {
      if (accept) {
        await ChallengesRepository.instance.accept(id);
      } else {
        await ChallengesRepository.instance.decline(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: accept ? AppColors.accentGreen : AppColors.accentRed,
          content: Text(accept ? 'Défi accepté' : 'Défi refusé'),
        ),
      );
      if (mounted) {
        context.read<NotificationsBloc>().add(
          const NotificationsRefreshRequested(),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Action impossible';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.accentRed, content: Text(message)),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: AppColors.textFaint,
            ),
            const SizedBox(height: 14),
            Text(
              'Aucune notification',
              style: AppTextStyles.h2.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tu verras ici tes défis reçus et les scores à valider.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textFaint),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
