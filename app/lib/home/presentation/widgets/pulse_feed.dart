import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/colors.dart';

class PulseFeedItem {
  final String emoji;
  final List<TextSpan> spans;
  final String time;
  const PulseFeedItem({
    required this.emoji,
    required this.spans,
    required this.time,
  });
}

class PulseFeed extends StatelessWidget {
  final List<PulseFeedItem> items;
  const PulseFeed({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
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
  final PulseFeedItem item;
  const _Row({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
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
                    children: item.spans,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.time,
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
    );
  }
}
