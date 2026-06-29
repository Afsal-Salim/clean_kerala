import 'dart:io';

class CapturedPhoto {
  CapturedPhoto({
    required this.file,
    required this.capturedAt,
    required this.wasteConfidence,
    required this.wasteLabels,
    this.latitude,
    this.longitude,
  });

  final File file;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final double wasteConfidence;
  final List<String> wasteLabels;

  Map<String, dynamic> toMetadataJson() => {
        'captured_at': capturedAt.toUtc().toIso8601String(),
        'source': 'camera',
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'waste_confidence': wasteConfidence,
        'waste_labels': wasteLabels,
      };
}
