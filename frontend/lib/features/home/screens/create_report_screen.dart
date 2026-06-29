import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/waste_image_verifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/nature_ui.dart';
import '../data/home_api.dart';
import '../models/captured_photo.dart';
import '../providers/home_provider.dart';

const _categories = [
  ('plastic', 'Plastic waste'),
  ('food', 'Food waste'),
  ('construction', 'Construction debris'),
  ('electronic', 'Electronic waste'),
  ('roadside', 'Roadside garbage'),
  ('canal', 'Canal waste'),
  ('beach', 'Beach waste'),
  ('illegal_dumping', 'Illegal dumping'),
  ('overflowing_dustbin', 'Overflowing dustbin'),
  ('biomedical', 'Biomedical waste'),
];

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _ward = TextEditingController();
  final _municipality = TextEditingController();
  final _district = TextEditingController();
  final _picker = ImagePicker();

  String _category = 'plastic';
  final List<CapturedPhoto> _photos = [];
  double? _lat;
  double? _lng;
  bool _loading = false;
  bool _locating = false;
  bool _verifyingPhoto = false;

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    _ward.dispose();
    _municipality.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_photos.length >= 3) {
      showSnack(context, 'Maximum 3 photos per report', isError: true);
      return;
    }

    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (mounted) showSnack(context, 'Camera permission is required to report waste', isError: true);
      return;
    }

    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null || !mounted) return;

    setState(() => _verifyingPhoto = true);
    try {
      final check = await verifyWasteInImage(x.path);
      if (!check.passed) {
        if (mounted) {
          showSnack(
            context,
            'We could not detect waste in this photo. Frame the waste clearly and try again.',
            isError: true,
          );
        }
        return;
      }

      setState(() {
        _photos.add(
          CapturedPhoto(
            file: File(x.path),
            capturedAt: DateTime.now(),
            latitude: _lat,
            longitude: _lng,
            wasteConfidence: check.confidence,
            wasteLabels: check.labels,
          ),
        );
      });
    } catch (e) {
      if (mounted) showSnack(context, 'Could not verify photo. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _verifyingPhoto = false);
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        await openAppSettings();
        if (mounted) showSnack(context, 'Enable location in settings', isError: true);
        return;
      }
      if (perm == LocationPermission.denied) {
        if (mounted) showSnack(context, 'Location permission required', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      if (mounted) {
        showSnack(context, 'Location captured (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Could not get location', isError: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      showSnack(context, 'Add at least one photo', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(homeApiProvider).createReport(
            category: _category,
            description: _description.text.trim(),
            latitude: _lat,
            longitude: _lng,
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            wardName: _ward.text.trim().isEmpty ? null : _ward.text.trim(),
            municipalityName: _municipality.text.trim().isEmpty ? null : _municipality.text.trim(),
            districtName: _district.text.trim().isEmpty ? null : _district.text.trim(),
            images: _photos,
          );
      ref.invalidate(feedProvider);
      if (mounted) {
        showSnack(context, 'Report posted! NGOs nearby will be notified.');
        context.go('/');
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
          title: const Text('Report waste'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NatureGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help keep Kerala clean 🌱',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: NatureColors.forest,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Take up to 3 live photos with your camera. Gallery uploads are not allowed.',
                        style: TextStyle(color: NatureColors.soil, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NatureGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Photos (${_photos.length}/3)', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ..._photos.asMap().entries.map(
                                (e) => Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(e.value.file, width: 88, height: 88, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _photos.removeAt(e.key)),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          if (_photos.length < 3)
                            _PhotoAddButton(
                              icon: Icons.photo_camera,
                              label: _verifyingPhoto ? 'Checking…' : 'Camera',
                              onTap: _verifyingPhoto ? () {} : _capturePhoto,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NatureGlassCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Waste category'),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v ?? 'plastic'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Describe the problem',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v != null && v.trim().length >= 10 ? null : 'At least 10 characters',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _locating ? null : _captureLocation,
                        icon: _locating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                        label: Text(_lat != null ? 'Location saved' : 'Capture GPS location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NatureColors.forest,
                          side: const BorderSide(color: NatureColors.moss),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(labelText: 'Address (optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(controller: _ward, decoration: const InputDecoration(labelText: 'Ward')),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _municipality,
                        decoration: const InputDecoration(labelText: 'Municipality / Panchayat'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _district,
                        decoration: const InputDecoration(labelText: 'District'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NaturePrimaryButton(
                  label: 'Post report',
                  icon: Icons.eco,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoAddButton extends StatelessWidget {
  const _PhotoAddButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: NatureColors.mint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NatureColors.sage, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: NatureColors.forest),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: NatureColors.forest)),
          ],
        ),
      ),
    );
  }
}
