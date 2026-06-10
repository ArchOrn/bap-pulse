import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/shared/models/notification.dart';

/// A single row in the notification center.
///
/// Displays a coloured leading bubble whose icon and tint depend on the
/// notification type, followed by title + body + relative timestamp. The whole
/// card is tappable; when the notification points to a still-actionable
/// resource (an open challenge or a pending match), [onPrimary] / [onSecondary]
/// render inline CTAs (e.g. Accepter / Refuser).
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  /// Primary inline action (e.g. Accepter le défi, Confirmer le score).
  final ({String label, VoidCallback onPressed})? primary;

  /// Secondary inline action (e.g. Refuser, Contester).
  final ({String label, VoidCallback onPressed})? secondary;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isUnread;
    final tone = _toneFor(notification.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? tone.color.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tone.icon, color: tone.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 6, top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: tone.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (primary != null || secondary != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (secondary != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentRed,
                          side: const BorderSide(
                            color: AppColors.accentRed,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: secondary!.onPressed,
                        child: Text(secondary!.label),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (primary != null)
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: tone.color,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: primary!.onPressed,
                        child: Text(primary!.label),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static _Tone _toneFor(AppNotificationType type) => switch (type) {
    AppNotificationType.challengeReceived => const _Tone(
      Icons.sports_kabaddi_rounded,
      AppColors.primary,
    ),
    AppNotificationType.challengeAccepted => const _Tone(
      Icons.check_circle_rounded,
      AppColors.accentGreen,
    ),
    AppNotificationType.challengeDeclined => const _Tone(
      Icons.cancel_rounded,
      AppColors.accentRed,
    ),
    AppNotificationType.matchAwaitingConfirmation => const _Tone(
      Icons.flag_rounded,
      AppColors.accentAmber,
    ),
    AppNotificationType.matchConfirmed => const _Tone(
      Icons.verified_rounded,
      AppColors.accentGreen,
    ),
    AppNotificationType.matchContested => const _Tone(
      Icons.warning_rounded,
      AppColors.accentRed,
    ),
    AppNotificationType.unknown => const _Tone(
      Icons.notifications_rounded,
      AppColors.textMuted,
    ),
  };

  static String _formatTimestamp(DateTime dt) {
    final delta = DateTime.now().difference(dt);
    if (delta.inMinutes < 1) return 'à l\'instant';
    if (delta.inMinutes < 60) return 'il y a ${delta.inMinutes} min';
    if (delta.inHours < 24) return 'il y a ${delta.inHours} h';
    if (delta.inDays < 7) return 'il y a ${delta.inDays} j';
    return DateFormat('d MMM', 'fr_FR').format(dt);
  }
}

class _Tone {
  final IconData icon;
  final Color color;
  const _Tone(this.icon, this.color);
}
