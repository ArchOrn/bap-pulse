import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';

class ChallengeSentScreen extends StatelessWidget {
  final String opponentFirstName;

  const ChallengeSentScreen({super.key, required this.opponentFirstName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_kabaddi_rounded,
                  color: AppColors.onPrimary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Défi envoyé',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(letterSpacing: -0.6),
              ),
              const SizedBox(height: 8),
              Text(
                '$opponentFirstName va recevoir une notification. Tu seras prévenu de sa réponse.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Retour à l\'accueil',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
