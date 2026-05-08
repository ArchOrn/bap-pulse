import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bap_pulse/core/router/app_router.dart';
import 'package:bap_pulse/core/theme/theme.dart';
import 'package:bap_pulse/core/widgets/mobile_frame.dart';
import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/profile/bloc/profile_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
    _profileBloc = ProfileBloc();
  }

  @override
  void dispose() {
    _authBloc.close();
    _profileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(_authBloc);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _profileBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            prev.user?.uid != curr.user?.uid ||
            prev.status != curr.status,
        listener: (context, state) {
          final uid = state.user?.uid;
          if (state.status == AuthStatus.authenticated && uid != null) {
            _profileBloc.add(ProfileLoadRequested(uid));
          } else if (state.status == AuthStatus.unauthenticated) {
            _profileBloc.add(const ProfileCleared());
          }
        },
        child: MaterialApp.router(
          title: 'BAP Pulse',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          routerConfig: router,
          builder: (context, child) =>
              MobileFrame(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
