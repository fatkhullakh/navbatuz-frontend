import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'city_screen.dart';

class CountrySelectionScreen extends StatelessWidget {
  final OnboardingData onboardingData;
  const CountrySelectionScreen({super.key, required this.onboardingData});

  void goToNext(BuildContext context, String country) {
    onboardingData.country = country;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CitySelectionScreen(onboardingData: onboardingData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countries = [
      'Uzbekistan',
      'Kazakhstan',
      'Kyrgyzstan',
      'Russia',
      'Tajikistan',
      'Turkmenistan',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Step 2 of 5',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.4,
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
              'Select your country',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ...countries.map((country) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.indigo),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () => goToNext(context, country),
                    child: Text(country, style: const TextStyle(fontSize: 16)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
