import 'package:flutter/material.dart';

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About / Terms / Privacy')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
