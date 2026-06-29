import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Labels that suggest waste, litter, or pollution in the scene.
const wasteLabelKeywords = [
  'trash',
  'garbage',
  'waste',
  'litter',
  'rubbish',
  'pollution',
  'landfill',
  'debris',
  'junk',
  'filth',
  'refuse',
  'dump',
  'plastic',
  'bottle',
  'can',
  'bag',
  'bin',
  'container',
  'cardboard',
  'scrap',
];

class WasteCheckResult {
  const WasteCheckResult({
    required this.passed,
    required this.confidence,
    required this.labels,
    this.matchedLabel,
  });

  final bool passed;
  final double confidence;
  final List<String> labels;
  final String? matchedLabel;
}

/// Minimum confidence for a waste-related ML Kit label (0–1).
const minWasteConfidence = 0.35;

Future<WasteCheckResult> verifyWasteInImage(String path) async {
  final inputImage = InputImage.fromFilePath(path);
  final labeler = ImageLabeler(options: ImageLabelerOptions());
  try {
    final detected = await labeler.processImage(inputImage);
    var bestScore = 0.0;
    String? matchedLabel;

    for (final label in detected) {
      final text = label.label.toLowerCase();
      if (wasteLabelKeywords.any(text.contains) && label.confidence > bestScore) {
        bestScore = label.confidence;
        matchedLabel = label.label;
      }
    }

    return WasteCheckResult(
      passed: bestScore >= minWasteConfidence,
      confidence: bestScore,
      matchedLabel: matchedLabel,
      labels: detected.map((l) => '${l.label}:${l.confidence.toStringAsFixed(2)}').toList(),
    );
  } finally {
    await labeler.close();
  }
}
