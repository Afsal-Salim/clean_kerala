import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_api.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/nature_ui.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _otp = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.text.length != 6) {
      showSnack(context, 'Enter the 6-digit OTP', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).verifyEmail(email: widget.email, otp: _otp.text.trim());
      if (mounted) {
        showSnack(context, 'Email verified!');
        context.go('/');
      }
    } catch (e) {
      if (mounted) showSnack(context, dioErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authApiProvider).resendOtp(email: widget.email);
      if (mounted) showSnack(context, 'New OTP sent to your email');
    } catch (e) {
      if (mounted) showSnack(context, dioErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _resending = false);
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
          title: const Text('Verify email'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: NatureGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📧', textAlign: TextAlign.center, style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Check your inbox', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: NatureColors.forest)),
                const SizedBox(height: 8),
                Text(
                  'Code sent to ${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NatureColors.soil),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.bold, color: NatureColors.forest),
                  decoration: InputDecoration(
                    labelText: 'OTP code',
                    counterText: '',
                    filled: true,
                    fillColor: NatureColors.mint.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                NaturePrimaryButton(label: 'Verify & continue', loading: _loading, onPressed: _verify),
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Sending…' : 'Resend OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
