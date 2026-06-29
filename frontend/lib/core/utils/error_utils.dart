import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const _apiErrorMessages = {
  'GALLERY_NOT_ALLOWED': 'Only live camera photos are allowed.',
  'WASTE_NOT_DETECTED': 'We could not verify waste in the photo. Please retake.',
  'STALE_CAPTURE': 'Photo is too old. Take a fresh picture with the camera.',
  'IMAGE_METADATA_REQUIRED': 'Photo verification data is missing.',
  'MAX_PHOTOS_EXCEEDED': 'Maximum 3 photos per report.',
  'REPORT_RATE_LIMIT_EXCEEDED': 'You can post up to 5 reports per day.',
};

String dioErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      final code = data['detail'] as String;
      return _apiErrorMessages[code] ?? code;
    }
    if (data is Map && data['detail'] is List) {
      return (data['detail'] as List).map((e) => e['msg'] ?? e.toString()).join('\n');
    }
    return error.message ?? 'Something went wrong';
  }
  return error.toString();
}

void showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1B7A43),
    ),
  );
}
