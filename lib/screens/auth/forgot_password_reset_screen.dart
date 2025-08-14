// lib/screens/auth/forgot_password_reset_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordResetScreen({super.key, required this.email});

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _showNew = false, _showConfirm = false;

  @override
  void dispose() {
    _code.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    if (_new.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.resetPassword(
        email: widget.email.trim(),
        code: _code.text.trim(),
        newPassword: _new.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated. Please log in.')));
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?.toString() ?? 'Reset failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Email: ${widget.email}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '6-digit code'),
              validator: (v) => (v == null || v.trim().length != 6)
                  ? 'Enter the 6-digit code'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _new,
              decoration: InputDecoration(
                labelText: 'New password',
                suffixIcon: IconButton(
                  icon:
                      Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
              obscureText: !_showNew,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirm,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                suffixIcon: IconButton(
                  icon: Icon(
                      _showConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              obscureText: !_showConfirm,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _reset,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Reset password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
