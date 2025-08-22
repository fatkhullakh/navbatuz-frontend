import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class ProviderStaffScreen extends StatefulWidget {
  final String providerId;
  const ProviderStaffScreen({super.key, required this.providerId});

  @override
  State<ProviderStaffScreen> createState() => _ProviderStaffScreenState();
}

class _ProviderStaffScreenState extends State<ProviderStaffScreen> {
  // TODO: hook to real staff list
  final List<_StaffRow> _staff = [];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_safe(t, null, 'Staff'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: invite/add worker flow
        },
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(_safe(t, null, 'Invite')),
      ),
      body: (_staff.isEmpty)
          ? Center(
              child: Text(_safe(t, null, 'No staff yet'),
                  style: const TextStyle(color: Colors.black54)),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemBuilder: (_, i) {
                final w = _staff[i];
                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading:
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(w.fullName),
                    subtitle: Text(w.email ?? '-'),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () {
                        // TODO: per-staff actions (assign services, working hours)
                      },
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _staff.length,
            ),
    );
  }

  String _safe(AppLocalizations t, String? maybe, String fallback) =>
      maybe ?? fallback;
}

class _StaffRow {
  final String id;
  final String fullName;
  final String? email;
  _StaffRow(this.id, this.fullName, this.email);
}
