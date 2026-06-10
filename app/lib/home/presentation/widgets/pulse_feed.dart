import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/news/data/markdown.dart';
import 'package:bap_pulse/news/data/news.dart';

class PulseFeed extends StatelessWidget {
  final List<News> items;
  const PulseFeed({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState();
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _Row(item: items[i]),
          if (i != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final News item;
  const _Row({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/news/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 22, height: 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        children: markdownToSpans(
                          item.title,
                          baseStyle: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(item.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Pas encore d\'actu — tout va bien au club.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
  if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem.';
  return 'il y a ${(diff.inDays / 30).floor()} mois';
}
