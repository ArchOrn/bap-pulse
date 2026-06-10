import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/auth/bloc/auth_bloc.dart';
import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/profile/data/account_api.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordCtrl = TextEditingController();
  final _api = AccountApi();
  bool _busy = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final password = _passwordCtrl.text;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      setState(() => _error = 'Session expirée. Reconnecte-toi.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Saisis ton mot de passe.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Re-authenticate with the current password so Firebase accepts the
      // subsequent delete (it refuses on a stale session).
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Server side first — once Firebase auth is gone, the ID token can't be
      // used to call DELETE /users/:id anymore.
      await _api.deleteMe();
      await user.delete();
      // AuthBloc's authStateChanges listener picks up the sign-out and the
      // router redirects to "/" — no manual navigation needed here. We still
      // emit signOut explicitly to be safe across edge cases.
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (e.code) {
          'wrong-password' || 'invalid-credential' => 'Mot de passe incorrect.',
          'too-many-requests' =>
            'Trop de tentatives. Réessaie dans un instant.',
          _ => 'Échec de la ré-authentification.',
        };
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Impossible de supprimer le compte.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Supprimer mon compte',
                      style: AppTextStyles.h1,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => context.pop(),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentRed.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'Cette action est définitive. Ton compte, ton historique de matchs et tes scores seront supprimés. Tu ne pourras pas récupérer ces données.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Confirme avec ton mot de passe',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _passwordCtrl,
                  autofocus: true,
                  obscureText: _obscure,
                  enabled: !_busy,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _deleteAccount(),
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 13,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _busy ? null : _deleteAccount,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Supprimer définitivement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
