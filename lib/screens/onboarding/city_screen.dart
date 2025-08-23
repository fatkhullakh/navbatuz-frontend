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

  bool get _canNext => _cityController.text.trim().isNotEmpty;

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
  void initState() {
    super.initState();
    _cityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: _StepAppBar(stepLabel: 'Step 3 of 5', progress: 0.6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _H1('Enter your city and district'),
            const SizedBox(height: 8),
            const _Sub('We’ll use this to show providers near you.'),
            const SizedBox(height: 24),
            TextField(
              controller: _cityController,
              textInputAction: TextInputAction.next,
              decoration: _dec('City *', prefix: Icons.location_city),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _districtController,
              textInputAction: TextInputAction.done,
              decoration:
                  _dec('District (optional)', prefix: Icons.map_outlined),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _canNext ? _Brand.primary : _Brand.accentSoft,
                  foregroundColor: _canNext ? Colors.white : _Brand.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _canNext ? goToNext : null,
                child: const Text('Next'),
              ),
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
  static const accent = Color(0xFF88BDF2);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

class _StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String stepLabel;
  final double progress;
  const _StepAppBar({required this.stepLabel, required this.progress});

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

InputDecoration _dec(String label, {IconData? prefix}) => InputDecoration(
      labelText: label,
      prefixIcon: prefix == null ? null : Icon(prefix),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _Brand.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _Brand.primary, width: 1.5),
      ),
    );

class _H1 extends StatelessWidget {
  final String text;
  const _H1(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w800, color: _Brand.ink));
}

class _Sub extends StatelessWidget {
  final String text;
  const _Sub(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14, color: _Brand.subtle));
}
