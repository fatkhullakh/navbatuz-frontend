// lib/screens/provider/manage/staff/provider_worker_edit_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/providers/provider_staff_service.dart';

/// ---- Brand palette (same as other screens) ----
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);
}

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
  String? _workerType; // role enum string

  bool _saving = false;

  /// Supported worker roles
  static const List<String> _roleCodes = [
    'BARBER',
    'HAIRDRESSER',
    'DENTIST',
    'DOCTOR',
    'NURSER',
    'SPA_THERAPIST',
    'MASSEUSE',
    'NAIL_TECHNICIAN',
    'COSMETOLOGIST',
    'TATTOO_ARTIST',
    'PERSONAL_TRAINER',
    'MAKEUP_ARTIST',
    'PHYSIOTHERAPIST',
    'GENERAL',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    final parts = (widget.initial.name).split(' ');
    _name.text = (parts.isNotEmpty ? parts.first : '').trim();
    _surname.text = (parts.length > 1 ? parts.sublist(1).join(' ') : '').trim();
    _phone.text = widget.initial.phoneNumber ?? '';
    _email.text = widget.initial.email ?? '';
    _gender = widget.initial.gender;
    _workerType = widget.initial.role;

    // If BE sent a role not in our list, include it at runtime so the dropdown shows it.
    if (_workerType != null &&
        _workerType!.isNotEmpty &&
        !_roleCodes.contains(_workerType)) {
      _roleCodes.insert(0, _workerType!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _validateRequired(BuildContext context, String? v) {
    final t = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return t.required ?? 'Required';
    }
    return null;
  }

  String? _validateEmail(BuildContext context, String? v) {
    final t = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) return null;
    final s = v.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : (t.invalid_email ?? 'Invalid email');
  }

  String _genderLabel(AppLocalizations t, String code) {
    switch (code) {
      case 'MALE':
        return t.gender_male ?? 'Male';
      case 'FEMALE':
        return t.gender_female ?? 'Female';
      case 'OTHER':
      default:
        return t.gender_other ?? 'Other';
    }
  }

  String _roleLabel(AppLocalizations t, String code) {
    switch (code) {
      case 'BARBER':
        return t.role_barber ?? 'Barber';
      case 'HAIRDRESSER':
        return t.role_hairdresser ?? 'Hairdresser';
      case 'DENTIST':
        return t.role_dentist ?? 'Dentist';
      case 'DOCTOR':
        return t.role_doctor ?? 'Doctor';
      case 'NURSER':
        return t.role_nurser ?? 'Nurser';
      case 'SPA_THERAPIST':
        return t.role_spa_therapist ?? 'Spa therapist';
      case 'MASSEUSE':
        return t.role_masseuse ?? 'Masseuse';
      case 'NAIL_TECHNICIAN':
        return t.role_nail_technician ?? 'Nail technician';
      case 'COSMETOLOGIST':
        return t.role_cosmetologist ?? 'Cosmetologist';
      case 'TATTOO_ARTIST':
        return t.role_tattoo_artist ?? 'Tattoo artist';
      case 'PERSONAL_TRAINER':
        return t.role_personal_trainer ?? 'Personal trainer';
      case 'MAKEUP_ARTIST':
        return t.role_makeup_artist ?? 'Makeup artist';
      case 'PHYSIOTHERAPIST':
        return t.role_physiotherapist ?? 'Physiotherapist';
      case 'GENERAL':
        return t.role_general ?? 'General';
      case 'OTHER':
      default:
        return t.role_other ?? 'Other';
    }
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
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final theme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: _Brand.bg,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: _Brand.subtle),
        prefixIconColor: _Brand.subtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.primary, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _Brand.ink,
        elevation: 0.5,
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: Text(t.edit_worker ?? 'Edit worker')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Identity
              _SectionCard(
                title: t.identity ?? 'Identity',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: t.first_name ?? 'Name',
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            validator: (v) => _validateRequired(context, v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _surname,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: t.surname ?? 'Surname',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Label(t.gender ?? 'Gender'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _GenderChip(
                          label: _genderLabel(t, 'MALE'),
                          value: 'MALE',
                          groupValue: _gender,
                          onSelected: () => setState(() => _gender = 'MALE'),
                        ),
                        _GenderChip(
                          label: _genderLabel(t, 'FEMALE'),
                          value: 'FEMALE',
                          groupValue: _gender,
                          onSelected: () => setState(() => _gender = 'FEMALE'),
                        ),
                        _GenderChip(
                          label: _genderLabel(t, 'OTHER'),
                          value: 'OTHER',
                          groupValue: _gender,
                          onSelected: () => setState(() => _gender = 'OTHER'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Contact
              _SectionCard(
                title: t.contact ?? 'Contact',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.phone ?? 'Phone',
                        prefixIcon: const Icon(Icons.call_outlined),
                        hintText: t.phone_hint ?? '+998 90 123 45 67',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.email ?? 'Email',
                        prefixIcon: const Icon(Icons.alternate_email_outlined),
                        hintText: t.email_hint ?? 'name@example.com',
                      ),
                      validator: (v) => _validateEmail(context, v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Role
              _SectionCard(
                title: t.role ?? 'Role',
                child: DropdownButtonFormField<String>(
                  value: _workerType,
                  decoration: InputDecoration(
                    labelText: t.role_worker_type ?? 'Role / Worker type',
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                  items: _roleCodes
                      .map((code) => DropdownMenuItem(
                            value: code,
                            child: Text(_roleLabel(t, code)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _workerType = v),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _Brand.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving
                      ? (t.saving ?? 'Saving…')
                      : (t.action_save ?? 'Save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---- UI bits (unchanged design) ----

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _Brand.ink,
                )),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: _Brand.subtle, fontWeight: FontWeight.w700),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final String value;
  final String? groupValue;
  final VoidCallback onSelected;

  const _GenderChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      backgroundColor: Colors.white,
      selectedColor: _Brand.primary.withOpacity(.12),
      shape: StadiumBorder(side: BorderSide(color: _Brand.border)),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: selected ? _Brand.primary : _Brand.subtle,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? _Brand.primary : _Brand.ink,
            ),
          ),
        ],
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
