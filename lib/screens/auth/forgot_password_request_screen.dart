// lib/screens/auth/forgot_password_request_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import 'forgot_password_reset_screen.dart';

class ForgotPasswordRequestScreen extends StatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  State<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState
    extends State<ForgotPasswordRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await ApiService.forgotPassword(_email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('If the email exists, a code was sent.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordResetScreen(email: _email.text.trim()),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      // still show generic OK (don’t leak existence)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('If the email exists, a code was sent.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordResetScreen(email: _email.text.trim()),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Enter your account email. We will send a 6-digit code to reset your password.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final ok =
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                return ok ? null : 'Invalid email';
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
