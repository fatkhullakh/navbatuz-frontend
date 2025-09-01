import 'package:flutter/material.dart';
import 'package:frontend/screens/onboarding/onboarding_ui.dart';
import '../../../models/onboarding_data.dart';

class ProviderCategoryScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const ProviderCategoryScreen({super.key, required this.onboardingData});

  @override
  State<ProviderCategoryScreen> createState() => _ProviderCategoryScreenState();
}

class _ProviderCategoryScreenState extends State<ProviderCategoryScreen> {
  String? _selected;

  String get _lang {
    final picked = (widget.onboardingData.languageCode ?? '').toLowerCase();
    if (picked == 'ru' || picked == 'uz' || picked == 'en') return picked;
    final ctx = Localizations.localeOf(context).languageCode.toLowerCase();
    if (ctx == 'ru' || ctx == 'uz') return ctx;
    return 'en';
  }

  // Stable codes saved to DB (English labels kept in parallel)
  final _cats = const [
    ('BARBERSHOP', Icons.content_cut, 'Barbershop', 'Барбершоп', 'Barbershop'),
    ('CLINIC', Icons.local_hospital_outlined, 'Clinic', 'Клиника', 'Klinika'),
    ('DENTAL', Icons.masks_outlined, 'Dental', 'Стоматология', 'Stomatologiya'),
    ('SPA', Icons.spa_outlined, 'Spa', 'Спа', 'Spa'),
    ('GYM', Icons.fitness_center, 'Gym / Fitness', 'Фитнес', 'Sport zali'),
    (
      'NAIL_SALON',
      Icons.health_and_safety_outlined,
      'Nail salon',
      'Ногтевой салон',
      'Manikur saloni'
    ),
    (
      'BEAUTY_CLINIC',
      Icons.face_retouching_natural,
      'Beauty clinic',
      'Косметология',
      'Goʻzallik klinikasi'
    ),
    (
      'TATTOO',
      Icons.brush_outlined,
      'Tattoo studio',
      'Тату-студия',
      'Tatu studiyasi'
    ),
    ('MASSAGE', Icons.self_improvement, 'Massage', 'Массаж', 'Massaj'),
    (
      'PHYSIO',
      Icons.sports_gymnastics,
      'Physiotherapy',
      'Физиотерапия',
      'Fizioterapiya'
    ),
    (
      'MAKEUP',
      Icons.palette_outlined,
      'Makeup studio',
      'Макияж',
      'Vizaj studiyasi'
    ),
    ('OTHER', Icons.more_horiz, 'Other', 'Другое', 'Boshqa'),
  ];

  String _l(String en, String ru, String uz) => _lang == 'ru'
      ? ru
      : _lang == 'uz'
          ? uz
          : en;

  void _next() {
    if (_selected == null) return;
    final item = _cats.firstWhere((e) => e.$1 == _selected);
    widget.onboardingData
      ..providerCategoryCode = item.$1
      ..providerCategoryNameEn = item.$3; // keep English name for DB
    Navigator.pushNamed(
      context,
      '/onboarding/provider/about',
      arguments: widget.onboardingData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: _StepAppBar(
        stepLabel: _l('Step 1 of 5', 'Шаг 1 из 5', '1-qadam / 5'),
        progress: .2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _H1(_l("What's your business?", 'Выберите категорию бизнеса',
                'Biznes turini tanlang')),
            const SizedBox(height: 8),
            _Sub(_l('Select the category', 'Выберите категорию',
                'Kategoriya tanlang')),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _cats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.9,
                ),
                itemBuilder: (_, i) {
                  final c = _cats[i];
                  final isSel = _selected == c.$1;
                  return InkWell(
                    onTap: () => setState(() => _selected = c.$1),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: isSel ? _Brand.primary : _Brand.border,
                            width: isSel ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _Brand.accentSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(c.$2, color: _Brand.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _l(c.$3, c.$4, c.$5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _Brand.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                decoration: isSel
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _selected == null ? null : _next,
                child: Text(_l('Continue', 'Продолжить', 'Davom etish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------- UI bits (brand) ------- */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const surfaceSoft = Color(0xFFF6F9FC);
  static const subtle = Color(0xFF7C8B9B);
}

class _StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String stepLabel;
  final double progress;
  const _StepAppBar(
      {required this.stepLabel, required this.progress, super.key});
  @override
  Widget build(BuildContext context) => AppBar(
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
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
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
