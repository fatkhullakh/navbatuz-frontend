import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'country_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  void goToNext(BuildContext context, String language) {
    final onboardingData = OnboardingData(language: language);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountrySelectionScreen(onboardingData: onboardingData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'label': 'O‘zbek', 'icon': Icons.translate},
      {'label': 'Русский', 'icon': Icons.language},
      {'label': 'English', 'icon': Icons.public},
    ];

    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: _StepAppBar(stepLabel: 'Step 1 of 5', progress: 0.2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _H1('Choose your language'),
            const SizedBox(height: 8),
            const _Sub('You can change language later in Settings.'),
            const SizedBox(height: 24),
            ...languages.map((lang) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionCard(
                    title: lang['label'] as String,
                    icon: lang['icon'] as IconData,
                    onTap: () => goToNext(context, lang['label'] as String),
                  ),
                )),
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
      elevation: 0,
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
                child: const Icon(Icons.language, color: _Brand.primary),
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
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: _Brand.ink),
      );
}

class _Sub extends StatelessWidget {
  final String text;
  const _Sub(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14, color: _Brand.subtle));
}
