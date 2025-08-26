import 'package:flutter/material.dart';

class MyServicesScreen extends StatelessWidget {
  final String workerId;
  const MyServicesScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Services')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'List of services assigned to you (coming soon).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
