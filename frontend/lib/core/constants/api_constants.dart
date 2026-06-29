class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Rewrites localhost media URLs for Android emulator / device testing.
  static String resolveMediaUrl(String url) {
    if (url.contains('localhost:8000') && baseUrl.contains('10.0.2.2')) {
      return url.replaceFirst('localhost:8000', '10.0.2.2:8000');
    }
    if (url.contains('localhost:8000') && baseUrl.contains('192.168')) {
      final host = Uri.parse(baseUrl.replaceAll('/api/v1', '')).host;
      return url.replaceFirst('localhost:8000', '$host:8000');
    }
    return url;
  }
}
