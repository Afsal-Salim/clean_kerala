import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/nature_ui.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _adminCode = TextEditingController();
  String _accountType = 'basic';
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _adminCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            accountType: _accountType,
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            adminCode: _accountType == 'admin' ? _adminCode.text.trim() : null,
          );
      if (mounted) {
        context.go('/verify-email?email=${Uri.encodeComponent(_email.text.trim())}');
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
          title: const Text('Join the movement'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NatureGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account type', style: TextStyle(fontWeight: FontWeight.w800, color: NatureColors.forest)),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'basic', label: Text('Basic'), icon: Icon(Icons.person)),
                          ButtonSegment(value: 'ngo', label: Text('NGO'), icon: Icon(Icons.groups)),
                          ButtonSegment(value: 'admin', label: Text('Admin'), icon: Icon(Icons.admin_panel_settings)),
                        ],
                        selected: {_accountType},
                        onSelectionChanged: (s) => setState(() => _accountType = s.first),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _accountType == 'basic'
                            ? 'Report waste and track cleanups.'
                            : _accountType == 'ngo'
                                ? 'Accept and resolve community reports.'
                                : 'Admin access (requires code).',
                        style: const TextStyle(fontSize: 12, color: NatureColors.soil),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NatureGlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_outlined)),
                        validator: (v) => v != null && v.length >= 2 ? null : 'Enter your name',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 characters',
                      ),
                      if (_accountType == 'admin') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _adminCode,
                          decoration: const InputDecoration(labelText: 'Admin registration code'),
                          validator: (v) => v != null && v.isNotEmpty ? null : 'Admin code required',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NaturePrimaryButton(
                  label: 'Continue — verify email',
                  loading: _loading,
                  onPressed: _submit,
                  icon: Icons.eco,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(onPressed: () => context.push('/login'), child: const Text('Log in')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
