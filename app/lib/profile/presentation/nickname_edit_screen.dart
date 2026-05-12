import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/core/widgets/primary_button.dart';
import 'package:bap_pulse/profile/data/account.dart';
import 'package:bap_pulse/profile/data/account_api.dart';

/// Max length enforced server-side via `VARCHAR(24)`.
const int _kNicknameMaxLength = 24;

class NicknameEditScreen extends StatefulWidget {
  final Account account;
  const NicknameEditScreen({super.key, required this.account});

  @override
  State<NicknameEditScreen> createState() => _NicknameEditScreenState();
}

class _NicknameEditScreenState extends State<NicknameEditScreen> {
  late final TextEditingController _ctrl;
  final _api = AccountApi();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.account.nickname ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _dirty {
    final cur = (widget.account.nickname ?? '').trim();
    final next = _ctrl.text.trim();
    return cur != next;
  }

  Future<void> _save() async {
    if (_busy || !_dirty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final raw = _ctrl.text.trim();
    final next = raw.isEmpty ? null : raw;
    try {
      await _api.updateNickname(widget.account, next);
      if (!mounted) return;
      context.pop(true);
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
        _error = 'Impossible d\'enregistrer.';
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
                  Expanded(child: Text('Pseudo', style: AppTextStyles.h1)),
                  TextButton(
                    onPressed: _busy ? null : () => context.pop(),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Visible uniquement par toi pour le moment.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  maxLength: _kNicknameMaxLength,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _save(),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_kNicknameMaxLength),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Ton pseudo',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _error ?? '',
                      style: const TextStyle(
                        color: AppColors.accentRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${_ctrl.text.length}/$_kNicknameMaxLength',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: _busy ? 'Enregistrement…' : 'Enregistrer',
                onPressed: (_busy || !_dirty) ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
