// lib/screens/onboarding/provider/business_address_screen.dart
import 'package:flutter/material.dart';
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';
import 'team_size_screen.dart';

class BusinessAddressScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const BusinessAddressScreen({super.key, required this.onboardingData});

  @override
  State<BusinessAddressScreen> createState() => _BusinessAddressScreenState();
}

class _BusinessAddressScreenState extends State<BusinessAddressScreen> {
  final _form = GlobalKey<FormState>();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _zip = TextEditingController();

  String get lang {
    final picked = (widget.onboardingData.languageCode ?? '').toLowerCase();
    if (picked == 'ru' || picked == 'uz' || picked == 'en') return picked;
    final ctx = Localizations.localeOf(context).languageCode.toLowerCase();
    if (ctx == 'ru' || ctx == 'uz') return ctx;
    return 'en';
  }

  String tr3(String en, String ru, String uz) =>
      lang == 'ru' ? ru : (lang == 'uz' ? uz : en);

  @override
  void initState() {
    super.initState();
    _city.text = widget.onboardingData.providerCityNameEn ??
        widget.onboardingData.cityNameEn ??
        '';
    _district.text = widget.onboardingData.providerDistrictNameEn ??
        widget.onboardingData.districtNameEn ??
        '';
    _addr1.text = widget.onboardingData.providerAddressLine1 ?? '';
    _addr2.text = widget.onboardingData.providerAddressLine2 ?? '';
    _zip.text = widget.onboardingData.providerZipCode ?? '';
  }

  @override
  void dispose() {
    _city.dispose();
    _district.dispose();
    _addr1.dispose();
    _addr2.dispose();
    _zip.dispose();
    super.dispose();
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

  void _next() {
    if (!_form.currentState!.validate()) return;
    widget.onboardingData
      ..providerCategoryNameEn = _city.text.trim()
      ..providerDistrictNameEn = _district.text.trim()
      ..providerAddressLine1 = _addr1.text.trim()
      ..providerAddressLine2 =
          _addr2.text.trim().isEmpty ? null : _addr2.text.trim()
      ..providerZipCode = _zip.text.trim().isEmpty ? null : _zip.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamSizeScreen(onboardingData: widget.onboardingData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: tr3('Step 5 of 7', 'Шаг 5 из 7', '5-bosqich / 7'),
        progress: 5 / 7, // adjust if your total differs
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            H1(tr3('Business address', 'Адрес бизнеса', 'Biznes manzili')),
            const SizedBox(height: 8),
            Sub(tr3(
              'Enter your full address so customers can reach you.',
              'Укажите полный адрес, чтобы клиенты могли вас найти.',
              'Mijozlar sizni topishi uchun to‘liq manzilni kiriting.',
            )),
            const SizedBox(height: 16),

            // City (required)
            TextFormField(
              controller: _city,
              decoration: _dec(tr3('City *', 'Город *', 'Shahar *')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr3('Required', 'Обязательно', 'Majburiy')
                  : null,
            ),
            const SizedBox(height: 12),

            // District (required)
            TextFormField(
              controller: _district,
              decoration: _dec(tr3('District *', 'Район *', 'Tuman *')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr3('Required', 'Обязательно', 'Majburiy')
                  : null,
            ),
            const SizedBox(height: 12),

            // Address line 1 (required)
            TextFormField(
              controller: _addr1,
              decoration: _dec(tr3(
                  'Address line 1 *', 'Адрес, строка 1 *', 'Manzil 1-qator *')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr3('Required', 'Обязательно', 'Majburiy')
                  : null,
            ),
            const SizedBox(height: 12),

            // Address line 2 (optional)
            TextFormField(
              controller: _addr2,
              decoration: _dec(tr3(
                  'Address line 2 (optional)',
                  'Адрес, строка 2 (необязательно)',
                  'Manzil 2-qator (ixtiyoriy)')),
            ),
            const SizedBox(height: 12),

            // ZIP (optional)
            TextFormField(
              controller: _zip,
              keyboardType: TextInputType.number,
              decoration: _dec(tr3('ZIP / Postal code (optional)',
                  'Индекс (необязательно)', 'Pochta indeksi (ixtiyoriy)')),
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _next,
                child: Text(tr3('Continue', 'Продолжить', 'Davom etish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
