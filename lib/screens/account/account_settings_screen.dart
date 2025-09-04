// lib/screens/account/account_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/profile/profile_service.dart';
import '../../core/locale_notifier.dart';

/// ---- Brand palette (same as other redesigned screens) ----
class _Brand {
  static const primary = Color(0xFF6A89A7); // steel blue
  static const ink = Color(0xFF384959); // dark text
  static const subtle = Color(0xFF7C8B9B); // secondary text
  static const border = Color(0xFFE6ECF2); // strokes
  static const bg = Color(0xFFF6F8FC); // page background
}

class AccountSettingsScreen extends StatefulWidget {
  final Me initial;
  const AccountSettingsScreen({super.key, required this.initial});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _svc = ProfileService();

  /// Language comes from backend: 'EN' | 'RU' | 'UZ'
  String? _language;

  /// Country ISO-2 (Central Asia + Russia)
  String? _country;

  bool _saving = false;

  /// Central Asia + Russia dropdown options
  static const List<_Country> _countries = [
    _Country('UZ', 'Uzbekistan'),
    _Country('KZ', 'Kazakhstan'),
    _Country('KG', 'Kyrgyzstan'),
    _Country('TJ', 'Tajikistan'),
    _Country('TM', 'Turkmenistan'),
    _Country('RU', 'Russia'),
  ];

  @override
  void initState() {
    super.initState();
    _language = (widget.initial.language ?? 'EN').toUpperCase();
    _country = (widget.initial.country ?? 'UZ').toUpperCase();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _svc.updateSettingsById(
        id: widget.initial.id,
        body: {'language': _language, 'country': _country},
      );

      if (!mounted) return;
      // Immediately apply the new language after saving
      await context.read<LocaleNotifier>().setLocaleByBackend(_language);

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
            content: Text('${t.error_generic ?? 'Something went wrong.'} $e')),
      );
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
        appBar: AppBar(title: Text(t.settingsTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SectionCard(
              title: t.settingsTitle,
              children: [
                // Language
                Text(
                  t.settingsLanguage,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _Brand.ink,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _language,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'EN', child: Text('English')),
                    DropdownMenuItem(value: 'RU', child: Text('Русский')),
                    DropdownMenuItem(value: 'UZ', child: Text('O‘zbekcha')),
                  ],
                  onChanged: (v) => setState(() => _language = v),
                ),
                const SizedBox(height: 16),

                // Country
                Text(
                  t.settings_country,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _Brand.ink,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _country,
                  isExpanded: true,
                  items: _countries
                      .map((c) => DropdownMenuItem<String>(
                            value: c.code,
                            child: Text('${c.name} (${c.code})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _country = v),
                ),
              ],
            ),
          ],
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

class _Country {
  final String code;
  final String name;
  const _Country(this.code, this.name);
}
