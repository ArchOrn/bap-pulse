import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/auth/data/auth_account.dart';
import 'package:bap_pulse/auth/presentation/_auth_background.dart';

/// Shown to authenticated users whose account is not approved yet — either
/// pending FFBAD validation by an admin, or rejected. Blocks access to the
/// main tabs (this route lives outside the bottom-nav ShellRoute).
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.error != b.error && b.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!)));
      },
      builder: (context, auth) {
        final rejected = auth.accountStatus == AccountStatus.rejected;
        return Scaffold(
          body: AuthBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Icon(
                      rejected ? Icons.cancel_outlined : Icons.hourglass_top,
                      size: 64,
                      color: rejected ? AppColors.accentRed : AppColors.primary,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      rejected ? 'Accès refusé' : 'Compte en attente',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      rejected
                          ? 'Ton inscription n\'a pas été validée. Contacte un responsable du club si tu penses qu\'il s\'agit d\'une erreur.'
                          : 'Ta licence n\'a pas été reconnue automatiquement parmi les membres du club. Un admin va valider ton accès très vite. Tu peux rafraîchir pour vérifier.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(flex: 3),
                    if (!rejected)
                      PrimaryButton(
                        label: 'Rafraîchir',
                        icon: Icons.refresh,
                        loading: auth.syncing,
                        onPressed: auth.syncing
                            ? null
                            : () => context.read<AuthBloc>().add(
                                const AuthSyncRequested(),
                              ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.read<AuthBloc>().add(
                          const AuthSignOutRequested(),
                        ),
                        child: const Text('Se déconnecter'),
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
