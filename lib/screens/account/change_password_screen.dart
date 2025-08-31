// lib/screens/account/change_password_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/profile/profile_service.dart';

/// ---- Brand palette (same family used across redesigned screens) ----
class _Brand {
  static const primary = Color(0xFF6A89A7); // steel blue
  static const ink = Color(0xFF384959); // dark text
  static const subtle = Color(0xFF7C8B9B); // secondary text
  static const border = Color(0xFFE6ECF2); // strokes
  static const bg = Color(0xFFF6F8FC); // page background
}

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
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _svc.changePassword(
        currentPassword: _current.text.trim(),
        newPassword: _new.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.saved ?? 'Saved')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.error_generic ?? 'Something went wrong.'} $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _req(String? v) {
    final t = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) return t.required ?? 'Required';
    return null;
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
        appBar: AppBar(title: Text(t.settingsChangePassword)),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                title: t.settingsChangePassword,
                children: [
                  // Current password
                  TextFormField(
                    controller: _current,
                    obscureText: !_showCurrent,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: t.current_password /* reuse label slot? */ ??
                          'Current password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _showCurrent = !_showCurrent),
                        icon: Icon(
                          _showCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        tooltip:
                            _showCurrent ? 'Hide' : 'Show', // fine to keep EN
                      ),
                    ),
                    validator: _req,
                  ),
                  const SizedBox(height: 12),

                  // New password
                  TextFormField(
                    controller: _new,
                    obscureText: !_showNew,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: t.new_password,
                      hintText: t.new_password_hint,
                      prefixIcon: const Icon(Icons.password_outlined),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _showNew = !_showNew),
                        icon: Icon(
                          _showNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        tooltip: _showNew ? 'Hide' : 'Show',
                      ),
                    ),
                    validator: (v) {
                      final r = _req(v);
                      if (r != null) return r;
                      if ((v ?? '').length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Confirm password
                  TextFormField(
                    controller: _confirm,
                    obscureText: !_showConfirm,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: t.confirm_new_password,
                      hintText: t.confirm_new_password_hint,
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _showConfirm = !_showConfirm),
                        icon: Icon(
                          _showConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        tooltip: _showConfirm ? 'Hide' : 'Show',
                      ),
                    ),
                    validator: (v) {
                      final r = _req(v);
                      if (r != null) return r;
                      if (v != _new.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom Save bar
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
                  onPressed: _saving ? null : _submit,
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
