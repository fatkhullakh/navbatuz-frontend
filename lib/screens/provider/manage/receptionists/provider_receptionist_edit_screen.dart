// lib/screens/provider/manage/receptionists/provider_receptionist_edit_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/providers/provider_staff_service.dart';

class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);
}

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
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : (t.invalid_email ?? 'Invalid email');
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
    final t = AppLocalizations.of(context)!;

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
        appBar: AppBar(title: Text(t.edit_receptionist ?? 'Edit receptionist')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                title: t.identity ?? 'Identity',
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _name,
                          decoration: InputDecoration(
                            labelText: t.name ?? 'Name',
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => _validateRequired(context, v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _surname,
                          decoration: InputDecoration(
                            labelText: t.surname ?? 'Surname',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: t.contact ?? 'Contact',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
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
