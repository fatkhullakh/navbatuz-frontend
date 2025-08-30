// lib/screens/provider/manage/receptionists/provider_receptionist_edit_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../services/providers/provider_staff_service.dart';

class ProviderReceptionistEditScreen extends StatefulWidget {
  final String providerId;
  final ReceptionistMember initial;
  const ProviderReceptionistEditScreen({
    super.key,
    required this.providerId,
    required this.initial,
  });

  @override
  State<ProviderReceptionistEditScreen> createState() =>
      _ProviderReceptionistEditScreenState();
}

class _ProviderReceptionistEditScreenState
    extends State<ProviderReceptionistEditScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = ProviderStaffService();

  late final _name = TextEditingController(text: widget.initial.name);
  late final _surname = TextEditingController(text: widget.initial.surname);
  late final _phone =
      TextEditingController(text: widget.initial.phoneNumber ?? '');
  late final _email = TextEditingController(text: widget.initial.email ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await _svc.updateReceptionist(
        widget.providerId,
        widget.initial.id,
        name: _name.text.trim(),
        surname: _surname.text.trim(),
        phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit receptionist')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _surname,
                  decoration: const InputDecoration(labelText: 'Surname'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
