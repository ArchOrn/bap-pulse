import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/auth/presentation/_auth_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        username: _usernameCtrl.text,
        inviteCode: _inviteCtrl.text,
      ),
    );
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
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Rejoins\nla ligue.', style: AppTextStyles.h1.copyWith(fontSize: 38)),
                    const SizedBox(height: 8),
                    Text(
                      'Quelques infos et c\'est parti.',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('Prénom'),
                              TextFormField(
                                controller: _firstNameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(hintText: 'Thomas'),
                                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('Nom'),
                              TextFormField(
                                controller: _lastNameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(hintText: 'Lefèvre'),
                                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _label('Pseudo'),
                    TextFormField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'thomas_l',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => v == null || v.length < 3 ? 'Au moins 3 caractères' : null,
                    ),
                    const SizedBox(height: 18),
                    _label('Email'),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'prenom.nom@bap.fr',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                      validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 18),
                    _label('Mot de passe'),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        hintText: '8 caractères minimum',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 8 ? '8 caractères minimum' : null,
                    ),
                    const SizedBox(height: 18),
                    _label('Code d\'invitation BAP'),
                    TextFormField(
                      controller: _inviteCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'ex. BAP-2026-XXXX',
                        prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Créer mon compte',
                      icon: Icons.arrow_forward,
                      loading: auth.busy,
                      onPressed: auth.busy ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'En créant un compte, tu acceptes le règlement intérieur de la ligue.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Déjà membre ? ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Se connecter',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
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
      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
    ),
  );
}
