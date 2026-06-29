import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_otp_screen.dart';
import '../../features/analytics/screens/analytics_map_screen.dart';
import '../../features/home/screens/create_report_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/location_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterRefresh(ref),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyOtpScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(path: '/create-report', builder: (_, __) => const CreateReportScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsMapScreen()),
      GoRoute(
        path: '/location-settings',
        builder: (_, state) => LocationSettingsScreen(isGuest: state.uri.queryParameters['guest'] == '1'),
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
