import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/bap_logo.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/auth/presentation/_auth_background.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (a, b) => a.status != b.status,
      builder: (context, auth) {
        if (auth.status == AuthStatus.unknown) {
          return const Scaffold(
            body: AuthBackground(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }
        return Scaffold(
          body: AuthBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    const BapLogo(height: 110, color: Colors.white),
                    const SizedBox(height: 32),
                    Text(
                      'La Ligue\ndu BAP',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 38,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Le championnat interne du club de Bad\' A Paname',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(flex: 4),
                    PrimaryButton(
                      label: 'Se connecter',
                      onPressed: () => context.push('/login'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Créer un compte'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Réservé aux membres du BAP',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
