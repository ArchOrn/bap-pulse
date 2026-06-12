import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/auth/data/auth_account.dart';
import 'package:bap_pulse/core/router/app_router.dart';
import 'package:bap_pulse/core/theme/theme.dart';
import 'package:bap_pulse/core/widgets/mobile_frame.dart';
import 'package:bap_pulse/leaderboard/bloc/leaderboard_bloc.dart';
import 'package:bap_pulse/notifications/bloc/notifications_bloc.dart';
import 'package:bap_pulse/notifications/data/fcm_service.dart';
import 'package:bap_pulse/profile/bloc/profile_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final ProfileBloc _profileBloc;
  late final LeaderboardBloc _leaderboardBloc;
  late final NotificationsBloc _notificationsBloc;
  late final GoRouter _router;
  StreamSubscription<RemoteMessage>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
    _profileBloc = ProfileBloc();
    _leaderboardBloc = LeaderboardBloc();
    _notificationsBloc = NotificationsBloc();
    _router = buildRouter(_authBloc);

    // Deep-link routing on notification tap (both warm + cold start).
    _deepLinkSub = FcmService.instance.onMessageOpenedApp.listen(
      _handleDeepLink,
    );
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _authBloc.close();
    _profileBloc.close();
    _leaderboardBloc.close();
    _notificationsBloc.close();
    super.dispose();
  }

  void _handleDeepLink(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString();
    final matchId = data['match_id']?.toString();
    switch (type) {
      case 'MATCH_AWAITING_CONFIRMATION':
      case 'MATCH_CONFIRMED':
      case 'MATCH_CONTESTED':
        if (matchId != null) _router.push('/score/validate/$matchId');
      case 'CHALLENGE_RECEIVED':
      case 'CHALLENGE_ACCEPTED':
      case 'CHALLENGE_DECLINED':
        _router.push('/notifications');
      default:
        _router.push('/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _profileBloc),
        BlocProvider.value(value: _leaderboardBloc),
        BlocProvider.value(value: _notificationsBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            prev.user?.uid != curr.user?.uid ||
            prev.status != curr.status ||
            prev.accountStatus != curr.accountStatus,
        listener: (context, state) {
          final uid = state.user?.uid;
          // Only load the profile / register for push once the account is
          // approved — pending or rejected users have no full profile.
          if (state.status == AuthStatus.authenticated &&
              state.accountStatus == AccountStatus.approved &&
              uid != null) {
            _profileBloc.add(ProfileLoadRequested(uid));
            _notificationsBloc.add(const NotificationsLoadRequested());
            // Push registration: best-effort; failures swallowed inside.
            FcmService.instance.registerCurrentToken();
          } else if (state.status == AuthStatus.unauthenticated) {
            _profileBloc.add(const ProfileCleared());
            _notificationsBloc.add(const NotificationsCleared());
            FcmService.instance.unregisterCurrentToken();
          }
        },
        child: MaterialApp.router(
          title: 'BAP Pulse',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          routerConfig: _router,
          builder: (context, child) =>
              MobileFrame(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
