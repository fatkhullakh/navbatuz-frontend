import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ProviderAccountScreen extends StatelessWidget {
  const ProviderAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.navAccount)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_safe(t, null, 'Profile')),
              subtitle: Text(_safe(t, null, 'Edit your profile & sign out')),
              onTap: () {
                // TODO: navigate to provider profile settings
              },
            ),
          ),
        ],
      ),
    );
  }

  String _safe(AppLocalizations t, String? maybe, String fallback) =>
      maybe ?? fallback;
}
