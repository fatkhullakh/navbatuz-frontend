import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../services/providers/provider_staff_service.dart';

class ProviderWorkerEditScreen extends StatefulWidget {
  final StaffMember initial;
  const ProviderWorkerEditScreen({super.key, required this.initial});

  @override
  State<ProviderWorkerEditScreen> createState() =>
      _ProviderWorkerEditScreenState();
}

class _ProviderWorkerEditScreenState extends State<ProviderWorkerEditScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = ProviderStaffService();

  late final _name = TextEditingController();
  late final _surname = TextEditingController();
  late final _phone = TextEditingController();
  late final _email = TextEditingController();

  String? _gender; // MALE/FEMALE/OTHER
  String? _workerType; // e.g., DOCTOR, BARBER, etc.

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final parts = widget.initial.name.split(' ');
    _name.text = (parts.isNotEmpty ? parts.first : '').trim();
    _surname.text = (parts.length > 1 ? parts.sublist(1).join(' ') : '').trim();
    _phone.text = widget.initial.phoneNumber ?? '';
    _email.text = widget.initial.email ?? '';
    _gender = widget.initial.gender; // already string enum from backend
    _workerType = widget.initial.role; // workerType
  }

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
      final updated = await _svc.updateWorker(
        widget.initial.id,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        surname: _surname.text.trim().isEmpty ? null : _surname.text.trim(),
        phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        gender: _gender,
        workerType: _workerType,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit worker')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
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
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _workerType,
              decoration:
                  const InputDecoration(labelText: 'Role / Worker type'),
              items: const [
                // add only types you support
                DropdownMenuItem(value: 'DOCTOR', child: Text('Doctor')),
                DropdownMenuItem(value: 'BARBER', child: Text('Barber')),
                DropdownMenuItem(
                    value: 'RECEPTIONIST', child: Text('Receptionist')),
                DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
              ],
              onChanged: (v) => setState(() => _workerType = v),
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
