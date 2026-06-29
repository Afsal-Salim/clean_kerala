import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/nature_ui.dart';
import '../data/analytics_api.dart';
import '../models/analytics_models.dart';

/// Kerala map analytics — drill-down: state → district → local body → ward.
/// Boundary GeoJSON layers ship in a later phase; stats API is live now.
class AnalyticsMapScreen extends ConsumerStatefulWidget {
  const AnalyticsMapScreen({super.key});

  @override
  ConsumerState<AnalyticsMapScreen> createState() => _AnalyticsMapScreenState();
}

class _AnalyticsMapScreenState extends ConsumerState<AnalyticsMapScreen> {
  AnalyticsViewState _view = const AnalyticsViewState();
  bool _loading = false;
  AnalyticsSummary? _summary;
  List<GeoStatsItem> _children = [];
  String? _error;

  static const _keralaCenter = LatLng(10.5, 76.2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(analyticsApiProvider);
      switch (_view.level) {
        case AnalyticsLevel.state:
          final summary = await api.summary();
          final districts = await api.districts();
          setState(() {
            _summary = summary;
            _children = districts;
          });
        case AnalyticsLevel.district:
          final d = await api.district(_view.districtSlug!);
          setState(() {
            _summary = AnalyticsSummary(
              totalReports: d.totalReports,
              pending: d.pending,
              closed: d.closed,
            );
            _children = d.localBodies;
          });
        case AnalyticsLevel.localBody:
          final b = await api.localBody(_view.localBodySlug!);
          setState(() {
            _summary = AnalyticsSummary(
              totalReports: b.totalReports,
              pending: b.pending,
              closed: b.closed,
            );
            _children = b.wards;
          });
        case AnalyticsLevel.ward:
          final w = await api.ward(_view.wardSlug!);
          setState(() {
            _summary = AnalyticsSummary(
              totalReports: w.totalReports,
              pending: w.pending,
              closed: w.closed,
            );
            _children = [];
          });
      }
    } catch (e) {
      setState(() => _error = dioErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChildTap(GeoStatsItem item) {
    switch (_view.level) {
      case AnalyticsLevel.state:
        setState(() => _view = _view.drillDistrict(item.slug, item.name));
      case AnalyticsLevel.district:
        setState(() => _view = _view.drillLocalBody(item.slug, item.name));
      case AnalyticsLevel.localBody:
        setState(() => _view = _view.drillWard(item.slug, item.name));
      case AnalyticsLevel.ward:
        return;
    }
    _load();
  }

  void _goBack() {
    if (_view.level == AnalyticsLevel.state) {
      context.pop();
      return;
    }
    setState(() => _view = _view.pop());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: NatureColors.forestDark,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
          title: Text(_view.title),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _keralaCenter,
                      initialZoom: 7.2,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'org.makekeralaclean.app',
                      ),
                    ],
                  ),
                  Positioned(
                    left: 12,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('© OpenStreetMap', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                  if (_view.level != AnalyticsLevel.state)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NatureColors.mint.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Tap areas below\n(boundary map soon)',
                          style: TextStyle(fontSize: 11, color: NatureColors.forest),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_summary != null) _StatsRow(summary: _summary!),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: NatureColors.moss))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : _children.isEmpty && _view.level == AnalyticsLevel.ward
                          ? const Center(child: Text('Ward-level detail'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _children.length,
                              itemBuilder: (_, i) {
                                final item = _children[i];
                                return _StatsTile(item: item, onTap: () => _onChildTap(item));
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _StatChip(label: 'Reports', value: summary.totalReports),
          const SizedBox(width: 8),
          _StatChip(label: 'Pending', value: summary.pending),
          const SizedBox(width: 8),
          _StatChip(label: 'Closed', value: summary.closed),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: NatureGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: NatureColors.forest)),
            Text(label, style: TextStyle(fontSize: 11, color: NatureColors.soil)),
          ],
        ),
      ),
    );
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({required this.item, required this.onTap});

  final GeoStatsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: NatureGlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, color: NatureColors.forestDark)),
                    Text(
                      '${item.totalReports} reports · ${item.closed} closed',
                      style: TextStyle(fontSize: 12, color: NatureColors.soil),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: NatureColors.moss),
            ],
          ),
        ),
      ),
    );
  }
}
