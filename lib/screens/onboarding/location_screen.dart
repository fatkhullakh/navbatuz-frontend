import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'role_screen.dart';

class LocationScreen extends StatelessWidget {
  final OnboardingData onboardingData;
  const LocationScreen({super.key, required this.onboardingData});

  void goToNext(BuildContext context) {
    // Optionally: Use GPS later
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(onboardingData: onboardingData),
      ),
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
          'Step 4 of 5',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.8,
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
              'Use your current location?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'We’ll use your location to show you local providers. You can skip this if you prefer to enter manually later.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
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
              icon: const Icon(Icons.location_on),
              label: const Text("Allow GPS Access"),
              onPressed: () {
                // For now, skip actual GPS logic
                goToNext(context);
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => goToNext(context),
              child: const Text("Skip"),
            ),
          ],
        ),
      ),
    );
  }
}
