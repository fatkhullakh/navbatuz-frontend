import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class ProviderBusinessInfoScreen extends StatefulWidget {
  final String providerId;
  const ProviderBusinessInfoScreen({super.key, required this.providerId});

  @override
  State<ProviderBusinessInfoScreen> createState() =>
      _ProviderBusinessInfoScreenState();
}

class _ProviderBusinessInfoScreenState
    extends State<ProviderBusinessInfoScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _about = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_safe(t, null, 'Business info'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: _safe(t, null, 'Name')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? _safe(t, null, 'Required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _about,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'About'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _saving = true);
                        try {
                          // TODO: call API to save business info
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_safe(t, null, 'Saved'))),
                          );
                          Navigator.pop(context);
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(_saving
                    ? _safe(t, null, 'Saving…')
                    : _safe(t, null, 'Save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _safe(AppLocalizations t, String? maybe, String fallback) =>
      maybe ?? fallback;
}
