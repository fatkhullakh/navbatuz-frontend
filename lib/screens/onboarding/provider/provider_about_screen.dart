// lib/screens/onboarding/provider/provider_about_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';

class ProviderAboutScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const ProviderAboutScreen({super.key, required this.onboardingData});

  @override
  State<ProviderAboutScreen> createState() => _ProviderAboutScreenState();
}

class _ProviderAboutScreenState extends State<ProviderAboutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  static const int _DESC_MAX = 2000;

  /// ISO2, dial, localLen
  static const List<(String iso, String dial, int len)> _codes = [
    ('UZ', '+998', 9),
    ('KZ', '+7', 10),
    ('RU', '+7', 10),
    ('KG', '+996', 9),
    ('TJ', '+992', 9),
    ('TM', '+993', 8),
  ];

  String _iso = 'UZ';
  bool _checkingPhone = false;
  bool _phoneExists = false;
  String? _asyncPhoneError;
  Timer? _debounce;
  String _lastCheckedE164 = '';

  String get _lang {
    final picked = (widget.onboardingData.languageCode ?? '').toLowerCase();
    if (picked == 'ru' || picked == 'uz' || picked == 'en') return picked;
    final ctx = Localizations.localeOf(context).languageCode.toLowerCase();
    if (ctx == 'ru' || ctx == 'uz') return ctx;
    return 'en';
  }

  String _t(String en, String ru, String uz) =>
      _lang == 'ru' ? ru : (_lang == 'uz' ? uz : en);

  (String iso, String dial, int len) get _cur =>
      _codes.firstWhere((c) => c.$1 == _iso);
  String get _dial => _cur.$2;
  int get _requiredLen => _cur.$3;

  String _exampleForIso(String iso) {
    switch (iso) {
      case 'UZ':
        return '90 123 45 67';
      case 'KZ':
      case 'RU':
        return '900 123 45 67';
      case 'KG':
      case 'TJ':
        return '700 123 456';
      case 'TM':
        return '12 345678';
      default:
        return '123456789';
    }
  }

  String get _phoneHint =>
      '${_t("Example", "Пример", "Misol")}: ${_exampleForIso(_iso)}';

  @override
  void initState() {
    super.initState();
    _name.text = widget.onboardingData.businessName ?? '';
    _desc.text = widget.onboardingData.businessDescription ?? '';
    _email.text = widget.onboardingData.businessEmail ?? ''; // locked
    _phone.text = widget.onboardingData.businessPhoneNumber ?? '';
    _iso = widget.onboardingData.businessPhoneIso2 ?? 'UZ';
    _debouncedCheckPhone();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _desc.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _onIsoChanged(String? v) {
    if (v == null) return;
    setState(() {
      _iso = v;
      _asyncPhoneError = null;
      _phoneExists = false;
    });
    _debouncedCheckPhone();
  }

  String _composeE164() => '$_dial${_phone.text.trim()}';

  void _debouncedCheckPhone() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _checkPhone());
  }

  Future<void> _checkPhone() async {
    final local = _phone.text.trim();
    final e164 = _composeE164();

    if (local.isEmpty || local.length != _requiredLen) {
      setState(() {
        _checkingPhone = false;
        _phoneExists = false;
        _asyncPhoneError = null;
        _lastCheckedE164 = '';
      });
      return;
    }

    setState(() {
      _checkingPhone = true;
      _asyncPhoneError = null;
    });

    try {
      final res = await ApiService.client.get(
        '/providers/public/phone-exists',
        queryParameters: {'phone': e164},
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      if (!mounted) return;
      final data = res.data is Map ? (res.data as Map) : {};
      setState(() {
        _phoneExists = data['exists'] == true;
        _checkingPhone = false;
        _lastCheckedE164 = e164;
      });
    } on DioError {
      if (!mounted) return;
      setState(() {
        _asyncPhoneError = _t('Network error', 'Ошибка сети', 'Tarmoq xatosi');
        _checkingPhone = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _asyncPhoneError = _t('Network error', 'Ошибка сети', 'Tarmoq xatosi');
        _checkingPhone = false;
      });
    }
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return _t('Required', 'Обязательно', 'Majburiy');
    if (!RegExp(r'^\d+$').hasMatch(s)) {
      return _t('Digits only', 'Только цифры', 'Faqat raqamlar');
    }
    if (s.length != _requiredLen) {
      return _t(
        'Enter $_requiredLen digits',
        'Введите $_requiredLen цифр',
        '$_requiredLen ta raqam kiriting',
      );
    }
    if (_checkingPhone) return _t('Checking…', 'Проверка…', 'Tekshirilmoqda…');
    if (_phoneExists) {
      return _t(
        'Phone already in use. Use another.',
        'Телефон уже используется. Укажите другой.',
        'Bu raqam band. Boshqasini kiriting.',
      );
    }
    if (_asyncPhoneError != null) return _asyncPhoneError;
    return null;
  }

  Future<void> _next() async {
    final e164 = _composeE164();
    if (_checkingPhone || e164 != _lastCheckedE164) {
      await _checkPhone();
    }
    if (!_form.currentState!.validate()) return;
    if (_phoneExists) return;

    widget.onboardingData
      ..businessName = _name.text.trim()
      ..businessDescription = _desc.text.trim()
      ..businessEmail = _email.text.trim() // locked but persisted
      ..businessPhoneIso2 = _iso
      ..businessPhoneDialCode = _dial
      ..businessPhoneNumber = _phone.text.trim();

    Navigator.pushNamed(
      context,
      '/onboarding/provider/location',
      arguments: widget.onboardingData,
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
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
    final continueDisabled = _checkingPhone || _phoneExists;

    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      resizeToAvoidBottomInset: true,
      appBar: StepAppBar(
        stepLabel: _t('Step 2 of 6', 'Шаг 2 из 6', '2-bosqich / 6'),
        progress: 2 / 6,
      ),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            children: [
              H1(_t('About you', 'О вас и бизнесе', 'Biznes haqida')),
              const SizedBox(height: 8),
              Sub(_t(
                'Tell us more about your business.',
                'Расскажите немного о бизнесе.',
                'Biznesingiz haqida qisqacha ma’lumot bering.',
              )),
              const SizedBox(height: 16),

              // Business name (required)
              TextFormField(
                controller: _name,
                decoration: _dec(
                  _t('Business name *', 'Название бизнеса *', 'Biznes nomi *'),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? _t('Required', 'Обязательно', 'Majburiy')
                    : null,
              ),
              const SizedBox(height: 12),

              // Description (optional)
              TextFormField(
                controller: _desc,
                maxLines: 4,
                maxLength: _DESC_MAX,
                inputFormatters: [LengthLimitingTextInputFormatter(_DESC_MAX)],
                decoration: _dec(
                  _t('Description (optional)', 'Описание (необязательно)',
                      'Tavsif (ixtiyoriy)'),
                ).copyWith(
                    helperText: _t('Max $_DESC_MAX characters',
                        'Макс $_DESC_MAX символов', 'Maks $_DESC_MAX belgi')),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.length > _DESC_MAX) {
                    return _t(
                        'Too long (max $_DESC_MAX)',
                        'Слишком длинно (макс $_DESC_MAX)',
                        'Juda uzun (maks $_DESC_MAX)');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone (required)
              Text(
                _t('Phone *', 'Телефон *', 'Telefon *'),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Brand.ink),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: DropdownButtonFormField<String>(
                      value: _iso,
                      isExpanded: true,
                      decoration: _dec(_t('Code', 'Код', 'Kod')),
                      items: _codes
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.$1,
                              child: Text('${e.$2} (${e.$1})'),
                            ),
                          )
                          .toList(),
                      onChanged: _onIsoChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 12,
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _dec(
                        _t('Number *', 'Номер *', 'Raqam *'),
                        hint: _phoneHint, // local example ONLY (no +998)
                      ).copyWith(
                        // removed dial prefix from field per request
                        suffixIcon: (_phone.text.trim().isEmpty)
                            ? null
                            : (_checkingPhone
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : (_phoneExists
                                    ? const Icon(Icons.info_outline,
                                        color: Colors.orange)
                                    : const Icon(Icons.check_circle_outline,
                                        color: Colors.green))),
                      ),
                      onChanged: (v) {
                        setState(() {}); // refresh suffix icon
                        _debouncedCheckPhone();
                      },
                      validator: _phoneValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Email (locked)
              TextFormField(
                controller: _email,
                enabled: false,
                readOnly: true,
                decoration: _dec('Email').copyWith(
                  suffixIcon:
                      const Icon(Icons.lock_outline, color: Brand.subtle),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Brand.surfaceSoft,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: continueDisabled ? null : _next,
              child: Text(_t('Continue', 'Продолжить', 'Davom etish')),
            ),
          ),
        ),
      ),
    );
  }
}
