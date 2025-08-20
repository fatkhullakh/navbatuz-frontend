import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/profile/profile_service.dart';
import '../../core/locale_notifier.dart';

class AccountSettingsScreen extends StatefulWidget {
  final Me initial;
  const AccountSettingsScreen({super.key, required this.initial});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _svc = ProfileService();

  String? _language; // 'EN' | 'RU' | 'UZ'
  String? _country;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _language = widget.initial.language ?? 'EN';
    _country = widget.initial.country ?? 'UZ';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _svc.updateSettingsById(
        id: widget.initial.id,
        body: {'language': _language, 'country': _country},
      );
      if (!mounted) return;
      await context.read<LocaleNotifier>().setLocaleByBackend(_language);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.settingsLanguage,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _language,
            items: const [
              DropdownMenuItem(value: 'EN', child: Text('English')),
              DropdownMenuItem(value: 'RU', child: Text('Русский')),
              DropdownMenuItem(value: 'UZ', child: Text("O‘zbekcha")),
            ],
            onChanged: (v) => setState(() => _language = v),
          ),
          const SizedBox(height: 16),
          Text(t.settings_country,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: _country,
            onChanged: (v) => _country = v,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: t.settings_country_hint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator())
                : Text(t.action_save),
          ),
        ],
      ),
    );
  }
}
