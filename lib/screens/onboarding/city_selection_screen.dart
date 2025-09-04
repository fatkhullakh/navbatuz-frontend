// lib/screens/onboarding/city_selection_screen.dart
import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'onboarding_ui.dart';
import 'location_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const CitySelectionScreen({super.key, required this.onboardingData});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  String? _cityId;
  String? _districtId;

  String get lang => (widget.onboardingData.languageCode ?? 'en').toLowerCase();
  String get countryRaw =>
      (widget.onboardingData.countryIso2 ?? 'UZ').toUpperCase();

  // ensure supported country; fallback to UZ
  String get country =>
      const ['UZ', 'KZ', 'KG', 'RU', 'TJ', 'TM'].contains(countryRaw)
          ? countryRaw
          : 'UZ';

  // ---- Full dataset (stable IDs, localized labels) ----
  static const _geo = {
    'UZ': {
      'cities': [
        {
          'id': 'tashkent',
          'en': 'Tashkent',
          'ru': 'Ташкент',
          'uz': 'Toshkent',
          'districts': [
            {
              'id': 'mirabad',
              'en': 'Mirabad',
              'ru': 'Мирабад',
              'uz': 'Mirabad'
            },
            {
              'id': 'chilanzar',
              'en': 'Chilanzar',
              'ru': 'Чиланзар',
              'uz': 'Chilonzor'
            },
            {
              'id': 'yashnabad',
              'en': 'Yashnabad',
              'ru': 'Яшнабад',
              'uz': 'Yashnobod'
            },
            {
              'id': 'mirzo-ulugbek',
              'en': 'Mirzo-Ulugbek',
              'ru': 'Мирзо-Улугбек',
              'uz': 'Mirzo Ulug‘bek'
            },
            {
              'id': 'sergeli',
              'en': 'Sergeli',
              'ru': 'Сергелий',
              'uz': 'Sergeli'
            },
          ]
        },
        {
          'id': 'samarkand',
          'en': 'Samarkand',
          'ru': 'Самарканд',
          'uz': 'Samarqand',
          'districts': [
            {
              'id': 'samarqand-district',
              'en': 'Samarkand District',
              'ru': 'Самаркандский р-н',
              'uz': 'Samarqand tumani'
            },
            {'id': 'urgut', 'en': 'Urgut', 'ru': 'Ургут', 'uz': 'Urgut'},
          ]
        },
        {
          'id': 'bukhara',
          'en': 'Bukhara',
          'ru': 'Бухара',
          'uz': 'Buxoro',
          'districts': [
            {
              'id': 'bukhara-city',
              'en': 'Bukhara City',
              'ru': 'Город Бухара',
              'uz': 'Buxoro sh.'
            },
          ]
        },
        {
          'id': 'fergana',
          'en': 'Fergana',
          'ru': 'Фергана',
          'uz': 'Farg‘ona',
          'districts': [
            {
              'id': 'fergana-city',
              'en': 'Fergana City',
              'ru': 'Город Фергана',
              'uz': 'Farg‘ona sh.'
            },
          ]
        },
        {
          'id': 'namangan',
          'en': 'Namangan',
          'ru': 'Наманган',
          'uz': 'Namangan',
          'districts': [
            {
              'id': 'namangan-city',
              'en': 'Namangan City',
              'ru': 'Город Наманган',
              'uz': 'Namangan sh.'
            },
          ]
        },
        {
          'id': 'andijan',
          'en': 'Andijan',
          'ru': 'Андижан',
          'uz': 'Andijon',
          'districts': [
            {
              'id': 'andijan-city',
              'en': 'Andijan City',
              'ru': 'Город Андижан',
              'uz': 'Andijon sh.'
            },
          ]
        },
        {
          'id': 'nukus',
          'en': 'Nukus',
          'ru': 'Нукус',
          'uz': 'Nukus',
          'districts': [
            {
              'id': 'nukus-city',
              'en': 'Nukus City',
              'ru': 'Город Нукус',
              'uz': 'Nukus sh.'
            },
          ]
        },
      ],
    },
    'KZ': {
      'cities': [
        {
          'id': 'almaty',
          'en': 'Almaty',
          'ru': 'Алма-Ата',
          'uz': 'Almati',
          'districts': [
            {
              'id': 'almalinsky',
              'en': 'Almalinsky',
              'ru': 'Алмалинский',
              'uz': 'Almalinskiy'
            },
            {
              'id': 'bostandyk',
              'en': 'Bostandyk',
              'ru': 'Бостандыкский',
              'uz': 'Bostandik'
            },
          ]
        },
        {
          'id': 'astana',
          'en': 'Astana',
          'ru': 'Астана',
          'uz': 'Astana',
          'districts': [
            {'id': 'esil', 'en': 'Yesil', 'ru': 'Есильский', 'uz': 'Yesil'},
            {
              'id': 'saryarka',
              'en': 'Saryarka',
              'ru': 'Сарыарка',
              'uz': 'Sariarqa'
            },
          ]
        },
      ],
    },
    'KG': {
      'cities': [
        {
          'id': 'bishkek',
          'en': 'Bishkek',
          'ru': 'Бишкек',
          'uz': 'Bishkek',
          'districts': [
            {
              'id': 'leninsky',
              'en': 'Leninsky',
              'ru': 'Ленинский',
              'uz': 'Leninskiy'
            },
            {
              'id': 'oktyabrsky',
              'en': 'Oktyabrsky',
              'ru': 'Октябрьский',
              'uz': 'Oktyabr'
            },
          ]
        },
        {'id': 'osh', 'en': 'Osh', 'ru': 'Ош', 'uz': 'O‘sh', 'districts': []},
      ],
    },
    'RU': {
      'cities': [
        {
          'id': 'moscow',
          'en': 'Moscow',
          'ru': 'Москва',
          'uz': 'Moskva',
          'districts': [
            {
              'id': 'tsao',
              'en': 'Tverskoy (Tsentralny AO)',
              'ru': 'Тверской (ЦАО)',
              'uz': 'Tverskoy (Markaziy AO)'
            },
            {
              'id': 'szao',
              'en': 'Strogino (SZAO)',
              'ru': 'Строгино (СЗАО)',
              'uz': 'Strogino (G‘arbiy Shimoliy AO)'
            },
          ]
        },
        {
          'id': 'saint-petersburg',
          'en': 'Saint Petersburg',
          'ru': 'Санкт-Петербург',
          'uz': 'Sankt-Peterburg',
          'districts': [
            {
              'id': 'tsentralny',
              'en': 'Tsentralny',
              'ru': 'Центральный',
              'uz': 'Markaziy'
            },
            {
              'id': 'moskovsky',
              'en': 'Moskovsky',
              'ru': 'Московский',
              'uz': 'Moskovskiy'
            },
          ]
        },
      ],
    },
    'TJ': {
      'cities': [
        {
          'id': 'dushanbe',
          'en': 'Dushanbe',
          'ru': 'Душанбе',
          'uz': 'Dushanbe',
          'districts': [
            {
              'id': 'firdavsi',
              'en': 'Firdavsi',
              'ru': 'Фирдавси',
              'uz': 'Firdavsiy'
            },
            {'id': 'somoni', 'en': 'Somoni', 'ru': 'Сомони', 'uz': 'Somoniy'},
          ]
        },
        {
          'id': 'khujand',
          'en': 'Khujand',
          'ru': 'Худжанд',
          'uz': 'Xo‘jand',
          'districts': []
        },
      ],
    },
    'TM': {
      'cities': [
        {
          'id': 'ashgabat',
          'en': 'Ashgabat',
          'ru': 'Ашхабад',
          'uz': 'Ashxobod',
          'districts': []
        },
        {
          'id': 'turkmenabat',
          'en': 'Turkmenabat',
          'ru': 'Туркменабат',
          'uz': 'Turkmanobod',
          'districts': []
        },
      ],
    },
  };

  List<Map<String, dynamic>> get _cities {
    final arr = (_geo[country]?['cities'] as List?) ?? const [];
    return arr.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> get _districts {
    final city = _cities.firstWhere(
      (c) => c['id'] == _cityId,
      orElse: () => <String, dynamic>{'districts': []},
    );
    return (city['districts'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
  }

  String _label(Map m) {
    final key = (lang == 'ru') ? 'ru' : (lang == 'uz' ? 'uz' : 'en');
    return (m[key] ?? m['en']) as String;
  }

  @override
  void initState() {
    super.initState();
    // Preselect first city for smoother UX (optional)
    final cs = _cities;
    if (cs.isNotEmpty) {
      _cityId = cs.first['id'] as String;
    }
  }

  void _next() {
    final city = _cities.firstWhere((c) => c['id'] == _cityId);
    final enCity = (city['en'] as String?) ?? '';
    final district = _districts
        .where((d) => d['id'] == _districtId)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;

    widget.onboardingData
      ..cityCode = _cityId
      ..cityNameEn = enCity
      ..districtCode = district?['id'] as String?
      ..districtNameEn = (district?['en'] as String?);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationScreen(onboardingData: widget.onboardingData),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
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
    final hasCities = _cities.isNotEmpty;

    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: tr(lang, 'Step 3 of 5', 'Шаг 3 из 5', '3-bosqich / 5'),
        progress: 0.6,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            H1(tr(lang, 'Choose your city', 'Выберите город',
                'Shaharni tanlang')),
            const SizedBox(height: 8),
            Sub(tr(
              lang,
              'We’ll show nearby providers.',
              'Покажем ближайшие сервисы.',
              'Yaqin xizmatlarni ko‘rsatamiz.',
            )),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _cityId,
              isExpanded: true,
              decoration: _dec(tr(lang, 'City *', 'Город *', 'Shahar *')),
              items: _cities
                  .map((c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(_label(c)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _cityId = v;
                _districtId = null;
              }),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _districtId,
              isExpanded: true,
              decoration: _dec(tr(lang, 'District (optional)',
                  'Район (необязательно)', 'Tuman (ixtiyoriy)')),
              items: _districts
                  .map((d) => DropdownMenuItem<String>(
                        value: d['id'] as String,
                        child: Text(_label(d)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _districtId = v),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: hasCities && _cityId != null ? _next : null,
                child: Text(tr(lang, 'Continue', 'Продолжить', 'Davom etish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
