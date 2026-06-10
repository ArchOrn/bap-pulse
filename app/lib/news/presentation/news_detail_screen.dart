import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bap_pulse/core/theme/colors.dart';
import 'package:bap_pulse/core/theme/text_styles.dart';
import 'package:bap_pulse/news/data/markdown.dart';
import 'package:bap_pulse/news/data/news.dart';
import 'package:bap_pulse/news/data/news_repository.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;
  const NewsDetailScreen({super.key, required this.newsId});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<News?> _future;

  @override
  void initState() {
    super.initState();
    _future = NewsRepository.instance.byId(widget.newsId);
  }

  void _retry() {
    setState(() {
      _future = NewsRepository.instance.byId(widget.newsId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      appBar: AppBar(
        backgroundColor: AppColors.bgScaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/news'),
        ),
        title: Text('News', style: AppTextStyles.h4),
      ),
      body: FutureBuilder<News?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _retry);
          }
          final news = snapshot.data;
          if (news == null) {
            return Center(
              child: Text(
                'Cette news n\'existe plus.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            );
          }
          return _Body(news: news);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final News news;
  const _Body({required this.news});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(news.emoji, style: const TextStyle(fontSize: 56, height: 1)),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            children: markdownToSpans(news.title, baseStyle: AppTextStyles.h2),
          ),
        ),
        const SizedBox(height: 12),
        _MetaRow(news: news),
        if (news.body != null && news.body!.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          _Paragraphs(body: news.body!),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final News news;
  const _MetaRow({required this.news});

  @override
  Widget build(BuildContext context) {
    final isAuto = news.source == NewsSource.autoMatch;
    final byline = isAuto ? 'Auto' : 'Club';

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Chip(
          label: byline,
          icon: isAuto ? Icons.auto_awesome : Icons.person_outline,
        ),
        Text(
          _formatDate(news.createdAt),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Paragraphs extends StatelessWidget {
  final String body;
  const _Paragraphs({required this.body});

  @override
  Widget build(BuildContext context) {
    final paragraphs = body.split(RegExp(r'\n\n+'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _Paragraph(text: paragraphs[i]),
        ],
      ],
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final isList = lines.every((l) => l.trimLeft().startsWith('- '));

    final base = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.textPrimary,
      height: 1.55,
    );

    if (isList) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 10),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: markdownToSpans(
                          line.trimLeft().substring(2),
                          baseStyle: base,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return RichText(
      text: TextSpan(children: markdownToSpans(text, baseStyle: base)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 12),
            Text(
              'Cette news n\'a pas pu être chargée.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year} · $h:$m';
}
