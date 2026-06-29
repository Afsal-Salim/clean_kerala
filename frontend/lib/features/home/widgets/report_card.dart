import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/home_models.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM · h:mm a').format(report.createdAt.toLocal());
    final images = report.imageUrls.map(ApiConstants.resolveMediaUrl).toList();
    final locationText = report.imageLocationText;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NatureColors.skyMist),
        boxShadow: [
          BoxShadow(
            color: NatureColors.forest.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  images.length == 1
                      ? _ReportImage(url: images.first)
                      : PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (_, i) => _ReportImage(url: images[i]),
                        ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ImageLocationBar(text: locationText, tier: report.locationTier),
                  ),
                  if (images.length > 1)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${images.length} photos',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: NatureColors.mint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatCategory(report.category),
                        style: const TextStyle(
                          color: NatureColors.forest,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (report.locationTier != null) ...[
                      const SizedBox(width: 8),
                      _TierChip(tier: report.locationTier!),
                    ],
                    const Spacer(),
                    _StatusChip(status: report.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report.description,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: NatureColors.bark),
                ),
                if (images.isEmpty && locationText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: NatureColors.moss),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(locationText, style: const TextStyle(color: NatureColors.soil, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MetaChip(icon: Icons.favorite_border, label: '${report.upvoteCount}'),
                    const SizedBox(width: 8),
                    _MetaChip(icon: Icons.chat_bubble_outline, label: '${report.commentCount}'),
                    const Spacer(),
                    Text(date, style: TextStyle(color: NatureColors.soil.withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
                if (report.authorName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Posted by ${report.authorName}',
                    style: const TextStyle(color: NatureColors.moss, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(String value) =>
      value.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _ImageLocationBar extends StatelessWidget {
  const _ImageLocationBar({required this.text, this.tier});

  final String text;
  final String? tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (tier != null) ...[
            const SizedBox(width: 8),
            _TierChip(tier: tier!, onDark: true),
          ],
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier, this.onDark = false});

  final String tier;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tier) {
      'near' => ('Near you', NatureColors.leaf),
      'surrounding' => ('Nearby', NatureColors.sunGlow),
      _ => ('Kerala', NatureColors.sage),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: onDark ? Border.all(color: Colors.white38) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: onDark ? Colors.white : NatureColors.forestDark,
        ),
      ),
    );
  }
}

class _ReportImage extends StatelessWidget {
  const _ReportImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: NatureColors.mint,
        child: const Center(child: Icon(Icons.image_not_supported, color: NatureColors.sage)),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: NatureColors.mint,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: NatureColors.moss)),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: NatureColors.cream, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: NatureColors.moss),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: NatureColors.soil)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'pending_ngo' => (const Color(0xFFE65100), NatureColors.sunGlow.withValues(alpha: 0.35)),
      'accepted' => (NatureColors.moss, NatureColors.mint),
      'resolved' => (const Color(0xFF00796B), const Color(0xFFB2DFDB)),
      'closed' => (NatureColors.forest, NatureColors.mint),
      _ => (NatureColors.soil, NatureColors.cream),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
