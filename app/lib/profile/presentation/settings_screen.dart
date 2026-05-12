import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/auth/data/auth_service.dart';
import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/profile/data/account.dart';
import 'package:bap_pulse/profile/data/account_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Account> _future;
  final _api = AccountApi();

  @override
  void initState() {
    super.initState();
    _future = _api.fetchMe();
  }

  void _reload() {
    setState(() => _future = _api.fetchMe());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: FutureBuilder<Account>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SettingsLoading();
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            final message = err is ApiException
                ? err.message
                : 'Impossible de charger ton compte.';
            return _SettingsError(message: message, onRetry: _reload);
          }
          return _SettingsBody(
            account: snapshot.data!,
            onNicknameChanged: _reload,
          );
        },
      ),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────

class _SettingsBody extends StatelessWidget {
  final Account account;
  final VoidCallback onNicknameChanged;

  const _SettingsBody({
    required this.account,
    required this.onNicknameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 14,
            20,
            8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RÉGLAGES',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Paramètres', style: AppTextStyles.h1),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
        // Section Profil
        const _SectionLabel('Profil'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: _Card(
            child: _ActionRow(
              label: 'Pseudo',
              trailing: account.nickname?.isNotEmpty == true
                  ? account.nickname!
                  : 'Ajouter un pseudo',
              trailingMuted: account.nickname == null ||
                  account.nickname!.isEmpty,
              onTap: () async {
                final ok = await context.push<bool>(
                  '/settings/nickname',
                  extra: account,
                );
                if (ok == true) onNicknameChanged();
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: _Card(
            child: Column(
              children: [
                _InfoRow(label: 'Prénom', value: account.firstName),
                _InfoRow(label: 'Nom', value: account.lastName),
                _InfoRow(
                  label: 'Genre',
                  value: _formatGender(account.gender),
                ),
                _InfoRow(
                  label: 'Classement FFBAD',
                  value: account.ffbadRank ?? '—',
                ),
                _InfoRow(label: 'Email', value: account.email, isLast: true),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Text(
            'Ces informations sont gérées par un admin du club. Contacte-les pour les modifier.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),

        // Section Compte
        const SizedBox(height: 24),
        const _SectionLabel('Compte'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: _Card(
            child: Column(
              children: [
                _ActionRow(
                  label: 'Changer le mot de passe',
                  onTap: () => _sendPasswordReset(context, account.email),
                ),
                _ActionRow(
                  label: 'Supprimer mon compte',
                  color: AppColors.accentRed,
                  isLast: true,
                  onTap: () => context.push('/settings/delete-account'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService().sendPasswordResetEmail(email);
      messenger.showSnackBar(
        SnackBar(content: Text('Mail de réinitialisation envoyé à $email.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossible d\'envoyer le mail.')),
      );
    }
  }

  static String _formatGender(String? g) => switch (g) {
        'MALE' => 'Homme',
        'FEMALE' => 'Femme',
        _ => '—',
      };
}

// ── Section pieces ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final String? trailing;
  final bool trailingMuted;
  final Color? color;
  final bool isLast;
  final VoidCallback onTap;

  const _ActionRow({
    required this.label,
    required this.onTap,
    this.trailing,
    this.trailingMuted = false,
    this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? AppColors.textPrimary,
                  fontWeight: color != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 14,
                    color: trailingMuted
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontStyle:
                        trailingMuted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: color ?? AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading & Error ─────────────────────────────────────────────────────────

class _SettingsLoading extends StatelessWidget {
  const _SettingsLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paramètres', style: AppTextStyles.h1),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _SettingsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SettingsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Paramètres', style: AppTextStyles.h1),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

