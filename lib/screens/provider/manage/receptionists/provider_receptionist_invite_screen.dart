import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';

class ProviderReceptionistInviteScreen extends StatefulWidget {
  final String providerId;
  const ProviderReceptionistInviteScreen({super.key, required this.providerId});

  @override
  State<ProviderReceptionistInviteScreen> createState() =>
      _ProviderReceptionistInviteScreenState();
}

class _ProviderReceptionistInviteScreenState
    extends State<ProviderReceptionistInviteScreen> {
  final Dio _dio = ApiService.client;

  // stepper
  int _step = 0;

  // personal/contact
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _gender; // MALE/FEMALE/OTHER
  DateTime? _dob; // optional

  // employment
  DateTime? _hireDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ---------- helpers ----------
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 100, 1, 1);
    final last = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickHireDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 5, 1, 1);
    final last = DateTime(now.year + 1, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? now,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _hireDate = picked);
  }

  String _fmtDate(DateTime? d) => d == null
      ? '—'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _generatePassword() {
    const alphabet =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#\$%';
    final rnd = Random.secure();
    return List.generate(12, (_) => alphabet[rnd.nextInt(alphabet.length)])
        .join();
  }

  String? _extractId(dynamic data) {
    if (data is Map) {
      if (data['id'] != null) return data['id'].toString();
      if (data['userId'] != null) return data['userId'].toString();
      final d = data['data'];
      if (d is Map && d['id'] != null) return d['id'].toString();
    }
    return null;
  }

  // ---------- submit ----------
  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      setState(() => _step = 0);
      return;
    }

    setState(() => _saving = true);
    try {
      // 1) Register user with RECEPTIONIST role
      final tempPassword = _generatePassword();
      final registerBody = {
        'name': _nameCtrl.text.trim(),
        'surname': _surnameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'gender': _gender, // optional
        'language': 'RU',
        'country': 'UZ',
        'dateOfBirth': _dob == null ? null : _fmtDate(_dob),
        'role': 'RECEPTIONIST',
        'password': tempPassword, // backend may override; fine
      };

      final regRes = await _dio.post('/auth/register', data: registerBody);
      final userId = _extractId(regRes.data);
      if (userId == null) {
        throw Exception('User id not returned from /auth/register');
      }

      // 2) Create receptionist record (hire date optional)
      await _dio.post(
        '/providers/${widget.providerId}/receptionists',
        data: {
          'userId': userId,
          if (_hireDate != null) 'hireDate': _fmtDate(_hireDate),
        },
      );

      // 3) Best-effort invite email (fallback to forgot-password)
      try {
        await _dio.post('/auth/forgot-password',
            data: {'email': _emailCtrl.text.trim()});
      } catch (_) {/* ignore */}

      if (!mounted) return;

      // 4) Show credentials & finish
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(t.invite_sent_title ?? 'Invitation sent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${t.login_email ?? 'Login (email)'}: ${_emailCtrl.text.trim()}'),
              const SizedBox(height: 6),
              Text('${t.temp_password ?? 'Temporary password'}: $tempPassword'),
              const SizedBox(height: 8),
              Text(
                t.invite_note_change_password ??
                    'They will be asked to change the password on first login.',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.action_done ?? 'Done')),
          ],
        ),
      );

      Navigator.pop(context, true);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final steps = [
      Step(
        title: Text(t.step_personal ?? 'Personal & contact'),
        isActive: _step >= 0,
        content: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: t.provider_name ?? 'Name',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (t.required ?? 'Required')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _surnameCtrl,
                      decoration: InputDecoration(
                        labelText: t.surname ?? 'Surname',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (t.required ?? 'Required')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: t.email ?? 'Email',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return t.required ?? 'Required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(s)) {
                          return t.invalid ?? 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: t.phone ?? 'Phone',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EnumDropdown(
                      value: _gender,
                      label: t.gender ?? 'Gender',
                      items: const ['MALE', 'FEMALE', 'OTHER'],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDob,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText:
                              t.date_of_birth ?? 'Date of birth (optional)',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.event_outlined),
                        ),
                        child: Text(_fmtDate(_dob)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${t.language ?? 'Language'}: RU • ${t.country ?? 'Country'}: UZ',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
      Step(
        title: const Text('Employment'),
        isActive: _step >= 1,
        content: Column(
          children: [
            InkWell(
              onTap: _pickHireDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Hire date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(_fmtDate(_hireDate)),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Status: ACTIVE • Will be able to manage provider area (no self-booking).',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
      Step(
        title: Text(t.reviewTitle ?? 'Review and confirm'),
        isActive: _step >= 2,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(t.provider_name ?? 'Name',
                '${_nameCtrl.text} ${_surnameCtrl.text}'),
            _kv(t.email ?? 'Email', _emailCtrl.text),
            _kv(t.phone ?? 'Phone',
                _phoneCtrl.text.isEmpty ? '—' : _phoneCtrl.text),
            _kv(t.gender ?? 'Gender', _gender ?? '—'),
            _kv(t.date_of_birth ?? 'Date of birth', _fmtDate(_dob)),
            _kv('Hire date', _fmtDate(_hireDate)),
            _kv('${t.language ?? 'Language'} / ${t.country ?? 'Country'}',
                'RU / UZ'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: Text(_saving
                    ? (t.saving ?? 'Saving…')
                    : (t.action_invite ?? 'Create & send invite')),
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Add & Invite receptionist')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () =>
            setState(() => _step = (_step + 1).clamp(0, steps.length - 1)),
        onStepCancel: () =>
            setState(() => _step = (_step - 1).clamp(0, steps.length - 1)),
        controlsBuilder: (ctx, d) => Row(
          children: [
            if (_step < steps.length - 1)
              FilledButton(
                  onPressed: d.onStepContinue,
                  child: Text(t.continueLabel ?? 'Continue')),
            if (_step < steps.length - 1) const SizedBox(width: 12),
            if (_step > 0)
              OutlinedButton(
                  onPressed: d.onStepCancel,
                  child: Text(t.common_back ?? 'Back')),
          ],
        ),
        steps: steps,
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
                child: Text(k, style: const TextStyle(color: Colors.black54))),
            Expanded(child: Text(v, textAlign: TextAlign.right)),
          ],
        ),
      );
}

class _EnumDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _EnumDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration:
          InputDecoration(border: const OutlineInputBorder(), labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : null,
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
