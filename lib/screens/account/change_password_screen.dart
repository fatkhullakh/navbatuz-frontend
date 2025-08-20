// lib/screens/account/change_password_screen.dart
import 'package:flutter/material.dart';
import '../../services/profile/profile_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String? userId; // optional; not needed for /users/change-password
  const ChangePasswordScreen({super.key, this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ProfileService();

  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _svc.changePassword(
        currentPassword: _current.text,
        newPassword: _new.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _req(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _current,
              decoration: const InputDecoration(labelText: 'Current password'),
              obscureText: true,
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _new,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
              validator: (v) {
                if (_req(v) != null) return 'Required';
                if (v!.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              decoration:
                  const InputDecoration(labelText: 'Confirm new password'),
              obscureText: true,
              validator: (v) {
                if (_req(v) != null) return 'Required';
                if (v != _new.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator())
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
