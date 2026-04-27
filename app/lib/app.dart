import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bap_pulse/core/router/app_router.dart';
import 'package:bap_pulse/core/theme/theme.dart';
import 'package:bap_pulse/core/widgets/mobile_frame.dart';
import 'package:bap_pulse/auth/bloc/auth_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(_authBloc);
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'BAP Pulse',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
        builder: (context, child) =>
            MobileFrame(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
