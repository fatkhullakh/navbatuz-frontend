import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ProviderAppointmentsScreen extends StatelessWidget {
  const ProviderAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.navAppointments)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TODO: hook up to provider/worker appointments
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(_safeText(t, 'Appointments')),
              subtitle: Text(_safeText(t, 'Your schedule appears here.')),
            ),
          ),
        ],
      ),
    );
  }

  String _safeText(AppLocalizations t, String fallback) => fallback;
}
