import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/home_provider.dart';

class QuoteBanner extends ConsumerWidget {
  const QuoteBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(randomQuoteProvider);

    return quoteAsync.when(
      loading: () => const _QuoteCard(text: 'Growing a cleaner Kerala, one report at a time…', author: null),
      error: (_, __) => const _QuoteCard(
        text: 'Cleanliness is next to godliness — keep Kerala beautiful.',
        author: 'Make Kerala Clean',
      ),
      data: (quote) => _QuoteCard(text: quote.text, author: quote.author),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.text, this.author});

  final String text;
  final String? author;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: NatureColors.gradientHero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: NatureColors.forest.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🌿', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Awareness',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$text"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (author != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '— $author',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
