import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/nature_ui.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      showSnack(context, 'Enter a valid email', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authApiProvider).forgotPassword(email: _email.text.trim());
      setState(() => _sent = true);
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
          title: const Text('Forgot password'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: NatureGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_reset, size: 48, color: NatureColors.moss),
                const SizedBox(height: 16),
                Text(
                  _sent ? 'OTP sent!' : 'Reset your password',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: NatureColors.forest),
                ),
                const SizedBox(height: 8),
                Text(
                  _sent
                      ? 'Check your email for the reset code.'
                      : 'We will send a one-time code to your email.',
                  style: const TextStyle(color: NatureColors.soil),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 24),
                NaturePrimaryButton(
                  label: _sent ? 'Sent' : 'Send reset OTP',
                  loading: _loading,
                  onPressed: _sent ? null : _submit,
                ),
                if (_sent) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push('/reset-password?email=${Uri.encodeComponent(_email.text.trim())}'),
                    style: OutlinedButton.styleFrom(foregroundColor: NatureColors.forest),
                    child: const Text('Enter OTP & new password'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
