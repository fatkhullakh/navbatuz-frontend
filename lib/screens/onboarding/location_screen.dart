import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'role_screen.dart';

class LocationScreen extends StatelessWidget {
  final OnboardingData onboardingData;
  const LocationScreen({super.key, required this.onboardingData});

  void goToNext(BuildContext context) {
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
      backgroundColor: _Brand.surfaceSoft,
      appBar: _StepAppBar(stepLabel: 'Step 4 of 5', progress: 0.8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _H1('Use your current location?'),
            const SizedBox(height: 8),
            const _Sub(
                'We use your location to show nearby providers. You can skip this.'),
            const SizedBox(height: 24),
            _Illustration(),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _Brand.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                // TODO: request permission + GPS, then:
                goToNext(context);
              },
              icon: const Icon(Icons.location_on),
              label: const Text('Allow GPS Access'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => goToNext(context),
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- UI Helpers ------------------------------ */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: _Brand.accentSoft,
        border: Border.all(color: _Brand.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.map, size: 56, color: _Brand.primary),
      ),
    );
  }
}

class _StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String stepLabel;
  final double progress;
  const _StepAppBar(
      {required this.stepLabel, required this.progress, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(stepLabel,
          style: const TextStyle(color: _Brand.subtle, fontSize: 16)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: _Brand.border,
          valueColor: const AlwaysStoppedAnimation<Color>(_Brand.primary),
          minHeight: 4,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class _H1 extends StatelessWidget {
  final String text;
  const _H1(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w800, color: _Brand.ink));
}

class _Sub extends StatelessWidget {
  final String text;
  const _Sub(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14, color: _Brand.subtle));
}
