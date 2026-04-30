import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/core/widgets/pulse_logo.dart';
import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/auth/presentation/_auth_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthPasswordResetRequested(_emailCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, auth) => Scaffold(
        body: AuthBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const PulseLogo(size: 56, color: Colors.white),
                    const SizedBox(height: 32),
                    Text(
                      'Mot de\npasse oublié ?',
                      style: AppTextStyles.h1.copyWith(fontSize: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Indique l\'email de ton compte BAP. On t\'envoie un lien pour le réinitialiser.',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 32),
                    if (auth.resetEmailSent) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accentGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentGreen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Email envoyé. Vérifie ta boîte de réception.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    _label('Email'),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'prenom.nom@bap.fr',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Email invalide' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Envoyer le lien',
                      loading: auth.busy,
                      onPressed: auth.busy ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}
