import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_safe(t, null, 'Dashboard'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_outlined, size: 56),
            const SizedBox(height: 8),
            Text(_safe(t, null, 'Coming soon')),
            const SizedBox(height: 4),
            Text(
              _safe(t, null, 'We are preparing analytics & quick actions.'),
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _safe(AppLocalizations t, String? maybe, String fallback) =>
      maybe ?? fallback;
}
