import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';

class RoleSelectionScreen extends StatelessWidget {
  final OnboardingData onboardingData;
  const RoleSelectionScreen({super.key, required this.onboardingData});

  void finishOnboarding(BuildContext context, String role) {
    onboardingData.role = role;

    Navigator.pushNamed(
      context,
      '/register',
      arguments:
          onboardingData, // this can be a String like "CUSTOMER" or a Map
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Step 5 of 5',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Who are you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.person),
              label: const Text("I'm a Customer"),
              onPressed: () => finishOnboarding(context, 'CUSTOMER'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.storefront),
              label: const Text("I'm a Service Provider"),
              onPressed: () => finishOnboarding(context, 'PROVIDER_OWNER'),
            ),
          ],
        ),
      ),
    );
  }
}
