import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nature_ui.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/storage/guest_location_prefs.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';
import '../widgets/quote_banner.dart';
import '../widgets/report_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final feedAsync = ref.watch(feedProvider);
    final guestLocAsync = ref.watch(guestLocationProvider);
    final user = auth.valueOrNull;
    final isLoggedIn = user != null;

    return NatureBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: NatureHeader(
          title: 'Make Kerala Clean',
          subtitle: 'Community waste reports across Kerala',
          actions: [
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'Kerala statistics',
              onPressed: () => context.push('/analytics'),
            ),
            IconButton(
              icon: const Icon(Icons.place_outlined),
              tooltip: 'Your area',
              onPressed: () => context.push(isLoggedIn ? '/location-settings' : '/location-settings?guest=1'),
            ),
            if (isLoggedIn)
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => _showProfile(context, ref, user),
              )
            else ...[
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('Log in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text('Sign up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
        body: RefreshIndicator(
          color: NatureColors.moss,
          onRefresh: () async {
            ref.invalidate(randomQuoteProvider);
            ref.invalidate(guestLocationProvider);
            ref.invalidate(feedProvider);
            await ref.read(feedProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: QuoteBanner()),
              SliverToBoxAdapter(child: _FeedMixBanner(feedAsync: feedAsync, user: user, guestLocAsync: guestLocAsync)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, color: NatureColors.moss, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Reports',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: NatureColors.forestDark,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              feedAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: NatureColors.moss)),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: NatureGlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off, size: 48, color: NatureColors.sage),
                            const SizedBox(height: 12),
                            const Text(
                              'Could not load feed.\nStart the backend server and pull to refresh.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => ref.invalidate(feedProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                data: (feed) {
                  if (feed.items.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: NatureGlassCard(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌱', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                'No reports yet',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: NatureColors.forest,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Be the first to report waste in your area!'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ReportCard(report: feed.items[index]),
                      childCount: feed.items.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: NatureColors.forest.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: isLoggedIn ? () => context.push('/create-report') : () => context.push('/signup'),
            backgroundColor: NatureColors.moss,
            icon: Icon(isLoggedIn ? Icons.add_a_photo : Icons.login, color: Colors.white),
            label: Text(
              isLoggedIn ? 'Report waste' : 'Join us',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  void _showProfile(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: NatureColors.forest)),
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(color: NatureColors.soil)),
            Text(_roleLabel(user.role), style: const TextStyle(color: NatureColors.moss, fontWeight: FontWeight.w600)),
            if (user.hasHomeLocation) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: NatureColors.moss),
                  const SizedBox(width: 4),
                  Expanded(child: Text(user.homeLocationLabel, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_location_alt, color: NatureColors.forest),
              title: const Text('Feed location settings'),
              subtitle: const Text('60% near · 30% surrounding · 10% Kerala'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/location-settings');
              },
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(authStateProvider.notifier).logout();
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                child: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        'citizen' => 'Basic account',
        'ngo_admin' => 'NGO account',
        'system_admin' => 'Admin',
        _ => role,
      };
}

class _FeedMixBanner extends StatelessWidget {
  const _FeedMixBanner({
    required this.feedAsync,
    required this.user,
    required this.guestLocAsync,
  });

  final AsyncValue<FeedResponse> feedAsync;
  final UserModel? user;
  final AsyncValue<GuestLocation?> guestLocAsync;

  @override
  Widget build(BuildContext context) {
    final hasUserLoc = user?.hasHomeLocation == true;
    final hasGuestLoc = guestLocAsync.valueOrNull?.isSet == true;
    final mix = feedAsync.valueOrNull?.mix;

    String subtitle;
    if (mix?.locationBased == true) {
      subtitle = 'Feed: ${mix!.nearPct}% near you · ${mix.surroundingPct}% surrounding · ${mix.keralaPct}% Kerala · newest first';
    } else if (!hasUserLoc && !hasGuestLoc) {
      subtitle = 'Set your area for a local feed (60/30/10 mix) — or browse all Kerala, newest first';
    } else {
      subtitle = 'Loading personalised feed…';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: NatureColors.mint.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(user != null ? '/location-settings' : '/location-settings?guest=1'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 18, color: NatureColors.forest),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(subtitle, style: const TextStyle(fontSize: 12, color: NatureColors.forestDark, height: 1.35)),
                ),
                const Icon(Icons.chevron_right, color: NatureColors.moss),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
