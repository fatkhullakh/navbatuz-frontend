import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/profile_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  final Me initial;
  const PersonalInfoScreen({super.key, required this.initial});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _surname;
  late TextEditingController _email;
  late TextEditingController _phone;
  DateTime? _dob;
  String? _gender;

  final _svc = ProfileService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.name ?? '');
    _surname = TextEditingController(text: widget.initial.surname ?? '');
    _email = TextEditingController(text: widget.initial.email ?? '');
    _phone = TextEditingController(text: widget.initial.phoneNumber ?? '');
    _dob = widget.initial.dateOfBirth;
    _gender = widget.initial.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final start = DateTime(now.year - 100, now.month, now.day);
    final end = DateTime(now.year - 10, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: end,
      initialDate: _dob ?? end,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'surname': _surname.text.trim(),
        'email': _email.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'dateOfBirth':
            _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
        'gender': _gender,
        'language': widget.initial.language,
        'country': widget.initial.country,
      }..removeWhere((k, v) => v == null);

      await _svc.updatePersonal(id: widget.initial.id, body: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Updated')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Info')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _req),
            const SizedBox(height: 12),
            TextFormField(
                controller: _surname,
                decoration: const InputDecoration(labelText: 'Surname'),
                validator: _req),
            const SizedBox(height: 12),
            TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _req),
            const SizedBox(height: 12),
            TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: _req),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Birthday'),
              subtitle: Text(_dob == null ? '—' : df.format(_dob!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDob,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _gender = v),
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            )
          ],
        ),
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
