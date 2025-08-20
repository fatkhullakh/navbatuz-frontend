// lib/screens/worker/worker_nav_root.dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class WorkerNavRoot extends StatelessWidget {
  const WorkerNavRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.provider_nav_appointments)),
      body: const Center(child: Text('Worker area (stub)')),
    );
  }
}
