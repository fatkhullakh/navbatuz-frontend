import 'package:flutter/material.dart';
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';

class TeamSizeScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const TeamSizeScreen({super.key, required this.onboardingData});

  @override
  State<TeamSizeScreen> createState() => _TeamSizeScreenState();
}

class _TeamSizeScreenState extends State<TeamSizeScreen> {
  String? _size;
  String get lang => (widget.onboardingData.languageCode ?? 'en').toLowerCase();

  InputDecoration _dec() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.primary, width: 1.5),
        ),
      );

  Widget _option(String code, String label) {
    final selected = _size == code;
    return InkWell(
      onTap: () => setState(() => _size = code),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: selected ? Brand.primary : Brand.border,
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Brand.primary : Brand.subtle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Brand.ink,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _mapSize(String code) {
    switch (code) {
      case 'JUST_ME':
        return 1;
      case 'TWO_THREE':
        return 3;
      case 'FOUR_SIX':
        return 6;
      case 'MORE_SIX':
        return 7; // 6+
      default:
        return 0;
    }
  }

  void _next() {
    if (_size == null) return;
    widget.onboardingData.teamSize = _mapSize(_size!);
    Navigator.pushNamed(
      context,
      '/onboarding/provider/hours',
      arguments: widget.onboardingData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: tr(lang, 'Step 6 of 7', 'Шаг 6 из 7', '6-bosqich / 7'),
        progress: 6 / 7,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            H1(tr(lang, "What's your team size?", 'Размер команды',
                'Jamoa hajmi?')),
            const SizedBox(height: 8),
            Sub(tr(
                lang,
                'This helps us tailor recommendations.',
                'Чтобы лучше адаптировать рекомендации.',
                'Tavsiyalarni moslash uchun.')),
            const SizedBox(height: 16),
            _option('JUST_ME', tr(lang, 'Just me', 'Только я', 'Faqat men')),
            const SizedBox(height: 10),
            _option('TWO_THREE',
                tr(lang, '2–3 staff members', '2–3 сотрудника', '2–3 xodim')),
            const SizedBox(height: 10),
            _option('FOUR_SIX',
                tr(lang, '4–6 staff members', '4–6 сотрудников', '4–6 xodim')),
            const SizedBox(height: 10),
            _option(
                'MORE_SIX', tr(lang, 'More than 6', 'Более 6', '6 dan ko‘p')),
            const Spacer(),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _size == null ? null : _next,
                child: Text(tr(lang, 'Continue', 'Продолжить', 'Davom etish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
