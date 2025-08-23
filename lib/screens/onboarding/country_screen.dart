import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'city_screen.dart';

class CountrySelectionScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const CountrySelectionScreen({super.key, required this.onboardingData});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  final _search = TextEditingController();
  final _countries = const [
    'Uzbekistan',
    'Kazakhstan',
    'Kyrgyzstan',
    'Russia',
    'Tajikistan',
    'Turkmenistan',
  ];

  List<String> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _countries;
    return _countries.where((c) => c.toLowerCase().contains(q)).toList();
  }

  void goToNext(String country) {
    widget.onboardingData.country = country;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CitySelectionScreen(onboardingData: widget.onboardingData),
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: _StepAppBar(stepLabel: 'Step 2 of 5', progress: 0.4),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _H1('Select your country'),
            const SizedBox(height: 8),
            const _Sub('This helps us show the right providers and currency.'),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration:
                  _dec('Search country', suffix: const Icon(Icons.search)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final country = _filtered[i];
                  return _OptionCard(
                    title: country,
                    icon: Icons.flag_outlined,
                    onTap: () => goToNext(country),
                  );
                },
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

InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
      labelText: label,
      suffixIcon: suffix,
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

class _OptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _OptionCard(
      {required this.title,
      required this.icon,
      required this.onTap,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _Brand.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _Brand.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                  //border: const BorderSide(color: _Brand.border),
                ),
                child: const Icon(Icons.flag_outlined, color: _Brand.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: _Brand.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    if ((subtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: const TextStyle(color: _Brand.subtle)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _Brand.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

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
