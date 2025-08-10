import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'location_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const CitySelectionScreen({super.key, required this.onboardingData});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();

  void goToNext() {
    widget.onboardingData.city = _cityController.text.trim();
    widget.onboardingData.district = _districtController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationScreen(onboardingData: widget.onboardingData),
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
          'Step 3 of 5',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Enter your city and district',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _districtController,
              decoration: InputDecoration(
                labelText: 'District (optional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: goToNext,
              child: const Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}
