// lib/screens/account/personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/profile/profile_service.dart';

/// ---- Brand palette (same as other redesigned screens) ----
class _Brand {
  static const primary = Color(0xFF6A89A7); // steel blue
  static const ink = Color(0xFF384959); // dark text
  static const subtle = Color(0xFF7C8B9B); // secondary text
  static const border = Color(0xFFE6ECF2); // strokes
  static const bg = Color(0xFFF6F8FC); // page background
}

class PersonalInfoScreen extends StatefulWidget {
  final Me initial;
  const PersonalInfoScreen({super.key, required this.initial});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _surname;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  DateTime? _dob;
  String? _gender; // MALE / FEMALE / OTHER

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
    final latest = DateTime(now.year - 10, now.month, now.day);
    final earliest = DateTime(now.year - 100, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      firstDate: earliest,
      lastDate: latest,
      initialDate: _dob ?? latest,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'surname': _surname.text.trim(),
        'email': _email.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'dateOfBirth':
            _dob == null ? null : DateFormat('yyyy-MM-dd').format(_dob!),
        'gender': _gender,
        // keep language/country unchanged (server may ignore if null)
        'language': widget.initial.language,
        'country': widget.initial.country,
      }..removeWhere((k, v) => v == null);

      await _svc.updatePersonal(id: widget.initial.id, body: body);

      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.saved ?? 'Saved')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.error_generic ?? 'Something went wrong.'} $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _req(BuildContext context, String? v) {
    final t = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) return t.required ?? 'Required';
    return null;
  }

  String? _validEmail(BuildContext context, String? v) {
    final t = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) return t.required ?? 'Required';
    final emailRx = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRx.hasMatch(v.trim())) return t.invalid_email ?? 'Invalid email';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final df = DateFormat('yyyy-MM-dd');

    final theme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: _Brand.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _Brand.ink,
        elevation: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: _Brand.subtle),
        prefixIconColor: _Brand.subtle,
        suffixIconColor: _Brand.subtle,
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
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: Text(t.personal_info ?? 'Personal info')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // --- Identity card ---
              _SectionCard(
                title: t.identity ?? 'Identity',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: t.name ?? 'Name',
                          ),
                          validator: (v) => _req(context, v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _surname,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: t.surname ?? 'Surname',
                          ),
                          validator: (v) => _req(context, v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: t.gender ?? 'Gender',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'MALE',
                        child: Text(t.gender_male ?? 'Male'),
                      ),
                      DropdownMenuItem(
                        value: 'FEMALE',
                        child: Text(t.gender_female ?? 'Female'),
                      ),
                      DropdownMenuItem(
                        value: 'OTHER',
                        child: Text(t.gender_other ?? 'Other'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 12),
                  _FieldButton(
                    label: t.date_of_birth ?? 'Date of birth',
                    value: _dob == null ? '—' : df.format(_dob!),
                    icon: Icons.calendar_today,
                    onTap: _pickDob,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // --- Contact card ---
              _SectionCard(
                title: t.contact ?? 'Contact',
                children: [
                  TextFormField(
                    controller: _phone,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: t.phone ?? 'Phone',
                      hintText: t.phone_hint ?? 'Enter phone number',
                    ),
                    validator: (v) => _req(context, v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: t.email ?? 'Email',
                      hintText: t.email_hint ?? 'Enter email address',
                    ),
                    validator: (v) => _validEmail(context, v),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom save bar
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _Brand.border)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _Brand.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? (t.saving ?? 'Saving…')
                        : (t.action_save ?? 'Save'),
                  ),
                )),
          ),
        ),
      ),
    );
  }
}

/* ---------- UI helpers ---------- */

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _Brand.ink,
                )),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FieldButton extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _FieldButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: _Brand.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
