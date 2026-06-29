import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/guest_location_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/nature_ui.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';

/// Profile / guest location settings for the 60/30/10 feed mix.
class LocationSettingsScreen extends ConsumerStatefulWidget {
  const LocationSettingsScreen({super.key, this.isGuest = false});

  final bool isGuest;

  @override
  ConsumerState<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends ConsumerState<LocationSettingsScreen> {
  final _ward = TextEditingController();
  final _municipality = TextEditingController();
  final _district = TextEditingController();
  double? _lat;
  double? _lng;
  bool _loading = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.isGuest) {
      final loc = await GuestLocationPrefs.load();
      if (loc != null && mounted) _apply(loc.latitude, loc.longitude, loc.ward, loc.municipality, loc.district);
    } else {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null && mounted) {
        _apply(user.homeLatitude, user.homeLongitude, user.homeWard, user.homeMunicipality, user.homeDistrict);
      }
    }
  }

  void _apply(double? lat, double? lng, String? ward, String? muni, String? dist) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _ward.text = ward ?? '';
      _municipality.text = muni ?? '';
      _district.text = dist ?? '';
    });
  }

  @override
  void dispose() {
    _ward.dispose();
    _municipality.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) showSnack(context, 'Location permission required', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      if (mounted) showSnack(context, 'GPS location captured');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_ward.text.trim().isEmpty && _municipality.text.trim().isEmpty && _district.text.trim().isEmpty && _lat == null) {
      showSnack(context, 'Set GPS or enter ward / municipality / district', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      if (widget.isGuest) {
        await GuestLocationPrefs.save(GuestLocation(
          latitude: _lat,
          longitude: _lng,
          ward: _ward.text.trim(),
          municipality: _municipality.text.trim(),
          district: _district.text.trim(),
        ));
        ref.invalidate(guestLocationProvider);
      } else {
        await ref.read(authStateProvider.notifier).updateLocation(
              latitude: _lat,
              longitude: _lng,
              ward: _ward.text.trim(),
              municipality: _municipality.text.trim(),
              district: _district.text.trim(),
            );
      }
      ref.invalidate(feedProvider);
      if (mounted) {
        showSnack(context, 'Location saved — feed updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, dioErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: NatureColors.forestDark,
          title: const Text('Your area'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NatureGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalised feed',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: NatureColors.forest),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your feed blends posts from:\n'
                      '• 60% near your location\n'
                      '• 30% surrounding areas\n'
                      '• 10% all Kerala\n\n'
                      'Newest posts show first within each group.',
                      style: TextStyle(color: NatureColors.soil, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NatureGlassCard(
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _locating ? null : _captureGps,
                      icon: _locating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      label: Text(_lat != null ? 'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}' : 'Use GPS location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NatureColors.forest,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _ward, decoration: const InputDecoration(labelText: 'Ward')),
                    const SizedBox(height: 12),
                    TextField(controller: _municipality, decoration: const InputDecoration(labelText: 'Municipality / Panchayat')),
                    const SizedBox(height: 12),
                    TextField(controller: _district, decoration: const InputDecoration(labelText: 'District')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              NaturePrimaryButton(label: 'Save location', loading: _loading, onPressed: _save, icon: Icons.place),
            ],
          ),
        ),
      ),
    );
  }
}
