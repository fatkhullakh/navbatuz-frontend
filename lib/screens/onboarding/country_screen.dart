import 'package:flutter/material.dart';
import 'package:frontend/screens/onboarding/city_selection_screen.dart';
import '../../models/onboarding_data.dart';
import 'onboarding_ui.dart';
import 'city_screen.dart';

class CountrySelectionScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const CountrySelectionScreen({super.key, required this.onboardingData});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  final _search = TextEditingController();

  String get lang => widget.onboardingData.languageCode ?? 'en';

  // ISO-2 code + localized labels + emoji flag
  final _countries = const [
    {
      'code': 'UZ',
      'flag': '🇺🇿',
      'en': 'Uzbekistan',
      'ru': 'Узбекистан',
      'uz': 'O‘zbekiston',
    },
    {
      'code': 'KZ',
      'flag': '🇰🇿',
      'en': 'Kazakhstan',
      'ru': 'Казахстан',
      'uz': 'Qozog‘iston',
    },
    {
      'code': 'KG',
      'flag': '🇰🇬',
      'en': 'Kyrgyzstan',
      'ru': 'Киргизия',
      'uz': 'Qirg‘iziston',
    },
    {
      'code': 'RU',
      'flag': '🇷🇺',
      'en': 'Russia',
      'ru': 'Россия',
      'uz': 'Rossiya',
    },
    {
      'code': 'TJ',
      'flag': '🇹🇯',
      'en': 'Tajikistan',
      'ru': 'Таджикистан',
      'uz': 'Tojikiston',
    },
    {
      'code': 'TM',
      'flag': '🇹🇲',
      'en': 'Turkmenistan',
      'ru': 'Туркменистан',
      'uz': 'Turkmaniston',
    },
  ];

  List<Map<String, String>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    final labelKey = lang == 'ru' ? 'ru' : (lang == 'uz' ? 'uz' : 'en');
    final list = _countries
        .map((e) => e.map((k, v) => MapEntry(k, v.toString())))
        .toList();
    if (q.isEmpty) return list;
    return list
        .where((c) => (c[labelKey] ?? '').toLowerCase().contains(q))
        .toList();
  }

  void _pick(Map<String, String> item) {
    widget.onboardingData
      ..countryIso2 = item['code'] // save ISO-2
      ..countryNameEn = item['en']; // save English label for DB
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

  InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: tr(lang, 'Step 2 of 5', 'Шаг 2 из 5', '2-bosqich / 5'),
        progress: 0.4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            H1(tr(lang, 'Select your country', 'Выберите страну',
                'Mamlakatni tanlang')),
            const SizedBox(height: 8),
            Sub(tr(
                lang,
                'Helps us show the right currency and providers.',
                'Поможет показать правильную валюту и поставщиков.',
                'To‘g‘ri valyuta va provayderlarni ko‘rsatadi.')),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: _dec(
                tr(lang, 'Search country', 'Поиск страны', 'Mamlakat qidirish'),
                suffix: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = _filtered[i];
                  final label =
                      item[lang == 'ru' ? 'ru' : (lang == 'uz' ? 'uz' : 'en')]!;
                  return OptionCard(
                    title: '${item['flag']}  $label',
                    icon: Icons.flag_outlined,
                    onTap: () => _pick(item),
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
