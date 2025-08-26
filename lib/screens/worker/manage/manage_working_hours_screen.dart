import 'package:flutter/material.dart';

class ManageWorkingHoursScreen extends StatelessWidget {
  final String workerId;
  const ManageWorkingHoursScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Working Hours')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Configure weekly hours (coming soon). Use "Add / Manage Breaks" in the previous screen for daily breaks.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
