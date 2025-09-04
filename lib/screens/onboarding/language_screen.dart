import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_notifier.dart';
import '../../models/onboarding_data.dart';
import 'country_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _setLangAndGo(
    BuildContext context, {
    required String langCode, // 'en' | 'ru' | 'uz'
    required String
        displayLang, // localized label for the next screen if needed
  }) async {
    // 1) Persist & notify the app
    await context.read<LocaleNotifier>().setLocaleCode(langCode);

    // 2) Seed onboarding with chosen language
    final data = OnboardingData(languageCode: langCode);

    // 3) Navigate to Country selection (which will render in this language)
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CountrySelectionScreen(onboardingData: data),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // These labels are static on this screen (user hasn't picked a language yet)
    const languages = [
      _LangOpt(code: 'uz', label: 'O‘zbek', icon: Icons.translate),
      _LangOpt(code: 'ru', label: 'Русский', icon: Icons.language),
      _LangOpt(code: 'en', label: 'English', icon: Icons.public),
    ];

    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: const _StepAppBar(stepLabel: 'Step 1 of 5', progress: 0.20),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _H1('Choose your language'),
            const SizedBox(height: 8),
            const _Sub('You can change language later in Settings.'),
            const SizedBox(height: 24),
            for (final l in languages)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionCard(
                  title: l.label,
                  icon: l.icon,
                  onTap: () => _setLangAndGo(
                    context,
                    langCode: l.code,
                    displayLang: l.label,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- UI bits ---------------- */

class _LangOpt {
  final String code;
  final String label;
  final IconData icon;
  const _LangOpt({required this.code, required this.label, required this.icon});
}

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
  const _OptionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

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
                ),
                child: Icon(icon, color: _Brand.primary),
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
