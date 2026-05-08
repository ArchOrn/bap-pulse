import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/auth/presentation/forgot_password_screen.dart';
import 'package:bap_pulse/auth/presentation/login_screen.dart';
import 'package:bap_pulse/auth/presentation/register_screen.dart';
import 'package:bap_pulse/auth/presentation/splash_screen.dart';
import 'package:bap_pulse/club/presentation/club_screen.dart';
import 'package:bap_pulse/club/presentation/player_detail_screen.dart';
import 'package:bap_pulse/home/presentation/home_screen.dart';
import 'package:bap_pulse/jerseys/presentation/history_screen.dart';
import 'package:bap_pulse/jerseys/presentation/jerseys_screen.dart';
import 'package:bap_pulse/leaderboard/presentation/leaderboard_screen.dart';
import 'package:bap_pulse/news/presentation/news_detail_screen.dart';
import 'package:bap_pulse/news/presentation/news_list_screen.dart';
import 'package:bap_pulse/profile/presentation/profile_screen.dart';
import 'package:bap_pulse/score/presentation/score_entry_screen.dart';
import 'package:bap_pulse/score/presentation/score_validate_screen.dart';
import 'package:bap_pulse/shell/main_shell.dart';

/// Re-emits whenever the [AuthBloc] state changes so that GoRouter knows to
/// re-evaluate `redirect`.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AuthBloc bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(authBloc),
    redirect: (context, state) {
      final auth = authBloc.state;
      final loc = state.matchedLocation;
      final onAuthRoute = loc == '/' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password';

      if (auth.status == AuthStatus.unknown) return null;

      if (auth.status == AuthStatus.unauthenticated) {
        return onAuthRoute ? null : '/';
      }

      // authenticated — bounce away from auth surfaces
      if (loc == '/' || loc == '/login' || loc == '/register') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/leaderboard',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: LeaderboardScreen()),
          ),
          GoRoute(
            path: '/club',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: ClubScreen()),
          ),
          GoRoute(
            path: '/jerseys',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: JerseysScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/club/player/:id',
        builder: (_, state) =>
            PlayerDetailScreen(playerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/news',
        builder: (_, _) => const NewsListScreen(),
      ),
      GoRoute(
        path: '/news/:id',
        builder: (_, state) =>
            NewsDetailScreen(newsId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/score/new',
        pageBuilder: (_, state) => MaterialPage(
          fullscreenDialog: true,
          child: ScoreEntryScreen(
            preselectedOpponentId: state.uri.queryParameters['opponent'],
          ),
        ),
      ),
      GoRoute(
        path: '/score/validate/:matchId',
        pageBuilder: (_, state) => MaterialPage(
          fullscreenDialog: true,
          child: ScoreValidateScreen(matchId: state.pathParameters['matchId']!),
        ),
      ),
      GoRoute(
        path: '/history',
        builder: (_, _) => const HistoryScreen(),
      ),
    ],
  );
}

/// Helper: read the AuthBloc from context.
extension AuthBlocX on BuildContext {
  AuthBloc get authBloc => read<AuthBloc>();
}
