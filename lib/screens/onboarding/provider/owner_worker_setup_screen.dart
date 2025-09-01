// lib/screens/onboarding/provider/owner_worker_setup_screen.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';

class OwnerWorkerInfoScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const OwnerWorkerInfoScreen({super.key, required this.onboardingData});

  @override
  State<OwnerWorkerInfoScreen> createState() => _OwnerWorkerInfoScreenState();
}

class _OwnerWorkerInfoScreenState extends State<OwnerWorkerInfoScreen> {
  final _form = GlobalKey<FormState>();

  // controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController(); // read-only text for date
  DateTime? _birthDate;

  // gender
  static const _genders = ['MALE', 'FEMALE', 'OTHER'];
  String? _gender; // 'MALE' | 'FEMALE' | 'OTHER'

  // is this owner also a worker?
  bool get _asWorker {
    final args =
        (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};
    final v = args['asWorker'];
    if (v is bool) return v;
    return true; // default behavior matches old flow
  }

  // country code (drop-down on the left)
  static const List<(String iso, String dial, int len)> _codes = [
    ('UZ', '+998', 9),
    ('KZ', '+7', 10),
    ('RU', '+7', 10),
    ('KG', '+996', 9),
    ('TJ', '+992', 9),
    ('TM', '+993', 8),
  ];
  String _iso = 'UZ';
  (String iso, String dial, int len) get _cur =>
      _codes.firstWhere((c) => c.$1 == _iso);
  String get _dial => _cur.$2;
  int get _requiredLen => _cur.$3;

  // worker types
  static const List<String> _workerTypes = [
    'BARBER',
    'HAIRDRESSER',
    'DENTIST',
    'DOCTOR',
    'NURSER',
    'SPA_THERAPIST',
    'MASSEUSE',
    'NAIL_TECHNICIAN',
    'COSMETOLOGIST',
    'TATTOO_ARTIST',
    'PERSONAL_TRAINER',
    'MAKEUP_ARTIST',
    'PHYSIOTHERAPIST',
    'GENERAL',
    'OTHER',
  ];
  String? _workerType;

  // async checks
  bool _checkingEmail = false;
  bool _emailExists = false;
  String? _emailAsyncError;
  bool _checkingPhone = false;
  bool _phoneExists = false;
  String? _phoneAsyncError;
  Timer? _debounceEmail, _debouncePhone;
  String _lastCheckedEmail = '';
  String _lastCheckedPhoneE164 = '';

  String get _lang {
    final picked = (widget.onboardingData.languageCode ?? '').toLowerCase();
    if (picked == 'ru' || picked == 'uz' || picked == 'en') return picked;
    final ctx = Localizations.localeOf(context).languageCode.toLowerCase();
    if (ctx == 'ru' || ctx == 'uz') return ctx;
    return 'en';
  }

  String tr(String en, String ru, String uz) =>
      _lang == 'ru' ? ru : (_lang == 'uz' ? uz : en);

  String _typeLabel(String code) {
    switch (code) {
      case 'BARBER':
        return tr('Barber', 'Барбер', 'Sartarosh');
      case 'HAIRDRESSER':
        return tr('Hairdresser', 'Парикмахер', 'Soch ustasi');
      case 'DENTIST':
        return tr('Dentist', 'Стоматолог', 'Stomatolog');
      case 'DOCTOR':
        return tr('Doctor', 'Врач', 'Shifokor');
      case 'NURSER':
        return tr('Nurse', 'Медсестра', 'Hamshira');
      case 'SPA_THERAPIST':
        return tr('Spa therapist', 'SPA-терапевт', 'SPA terapevt');
      case 'MASSEUSE':
        return tr('Masseuse', 'Массажист', 'Massajchi');
      case 'NAIL_TECHNICIAN':
        return tr('Nail technician', 'Ногтевой мастер', 'Manikyur ustasi');
      case 'COSMETOLOGIST':
        return tr('Cosmetologist', 'Косметолог', 'Kosmetolog');
      case 'TATTOO_ARTIST':
        return tr('Tattoo artist', 'Тату-мастер', 'Tatu ustasi');
      case 'PERSONAL_TRAINER':
        return tr('Personal trainer', 'Персональный тренер', 'Shaxsiy trener');
      case 'MAKEUP_ARTIST':
        return tr('Makeup artist', 'Визажист', 'Vizajist');
      case 'PHYSIOTHERAPIST':
        return tr('Physiotherapist', 'Физиотерапевт', 'Fizioterapevt');
      case 'GENERAL':
        return tr('General', 'Универсал', 'Umumiy');
      default:
        return tr('Other', 'Другое', 'Boshqa');
    }
  }

  @override
  void initState() {
    super.initState();
    _email.text = widget.onboardingData.businessEmail ?? '';
    _iso = widget.onboardingData.businessPhoneIso2 ?? 'UZ';
    _phone.text = widget.onboardingData.businessPhoneNumber ?? '';
    if (_email.text.trim().isNotEmpty) _debouncedCheckEmail(_email.text.trim());
    if (_phone.text.trim().isNotEmpty) _debouncedCheckPhone();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _debounceEmail?.cancel();
    _debouncePhone?.cancel();
    super.dispose();
  }

  /* ------------------------- Async checks -------------------------- */

  void _debouncedCheckEmail(String v) {
    _debounceEmail?.cancel();
    _debounceEmail =
        Timer(const Duration(milliseconds: 350), () => _checkEmail(v));
  }

  Future<void> _checkEmail(String value) async {
    final email = value.trim();
    if (email.isEmpty || !RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      setState(() {
        _checkingEmail = false;
        _emailExists = false;
        _emailAsyncError = null;
        _lastCheckedEmail = '';
      });
      return;
    }
    setState(() {
      _checkingEmail = true;
      _emailAsyncError = null;
    });
    try {
      final res = await ApiService.client.get(
        '/auth/public/email-exists',
        queryParameters: {'email': email},
      );
      if (!mounted) return;
      final data = res.data is Map ? (res.data as Map) : {};
      setState(() {
        _emailExists = data['exists'] == true;
        _checkingEmail = false;
        _lastCheckedEmail = email;
      });
    } on DioError {
      if (!mounted) return;
      setState(() {
        _emailAsyncError = tr('Network error', 'Ошибка сети', 'Tarmoq xatosi');
        _checkingEmail = false;
      });
    }
  }

  String _composePhoneE164() => '$_dial${_phone.text.trim()}';

  void _debouncedCheckPhone() {
    _debouncePhone?.cancel();
    _debouncePhone =
        Timer(const Duration(milliseconds: 350), () => _checkPhone());
  }

  Future<void> _checkPhone() async {
    final local = _phone.text.trim();
    if (local.isEmpty || local.length != _requiredLen) {
      setState(() {
        _checkingPhone = false;
        _phoneExists = false;
        _phoneAsyncError = null;
        _lastCheckedPhoneE164 = '';
      });
      return;
    }
    final e164 = _composePhoneE164();
    setState(() {
      _checkingPhone = true;
      _phoneAsyncError = null;
    });
    try {
      final res = await ApiService.client.get(
        '/auth/public/phone-exists',
        queryParameters: {'phone': e164},
      );
      if (!mounted) return;
      final data = res.data is Map ? (res.data as Map) : {};
      setState(() {
        _phoneExists = data['exists'] == true;
        _checkingPhone = false;
        _lastCheckedPhoneE164 = e164;
      });
    } on DioError {
      if (!mounted) return;
      setState(() {
        _phoneAsyncError = tr('Network error', 'Ошибка сети', 'Tarmoq xatosi');
        _checkingPhone = false;
      });
    }
  }

  /* ------------------------- Validators --------------------------- */

  String? _req(String? v) => (v == null || v.trim().isEmpty)
      ? tr('Required', 'Обязательно', 'Majburiy')
      : null;

  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return tr('Required', 'Обязательно', 'Majburiy');
    final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(s);
    if (!ok)
      return tr('Invalid email', 'Некорректный email', 'Noto‘g‘ri email');
    if (_checkingEmail) return tr('Checking…', 'Проверка…', 'Tekshirilmoqda…');
    if (_emailExists) {
      return tr(
          'Email already in use. Use another.',
          'Email уже используется. Укажите другой.',
          'Bu email band. Boshqasini kiriting.');
    }
    if (_emailAsyncError != null) return _emailAsyncError;
    return null;
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return tr('Required', 'Обязательно', 'Majburiy');
    if (!RegExp(r'^\d+$').hasMatch(s)) {
      return tr('Digits only', 'Только цифры', 'Faqat raqamlar');
    }
    if (s.length != _requiredLen) {
      return tr('Enter $_requiredLen digits', 'Введите $_requiredLen цифр',
          '$_requiredLen ta raqam kiriting');
    }
    if (_checkingPhone) return tr('Checking…', 'Проверка…', 'Tekshirilmoqda…');
    if (_phoneExists) {
      return tr(
          'Phone already in use. Use another.',
          'Телефон уже используется. Укажите другой.',
          'Bu raqam band. Boshqasini kiriting.');
    }
    if (_phoneAsyncError != null) return _phoneAsyncError;
    return null;
  }

  String? _dobValidator(String? v) {
    if (_birthDate == null) {
      return tr('Required', 'Обязательно', 'Majburiy');
    }
    if (_birthDate!.isAfter(DateTime.now())) {
      return tr('Invalid date', 'Некорректная дата', 'Noto‘g‘ri sana');
    }
    return null;
  }

  /* ------------------------- UI helpers --------------------------- */

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

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 80, 1, 1);
    final last = DateTime(now.year - 14, 12, 31); // min age 14
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(last) ? initial : last,
      firstDate: first,
      lastDate: last,
      helpText: tr('Date of birth', 'Дата рождения', 'Tug‘ilgan sana'),
      cancelText: tr('Cancel', 'Отмена', 'Bekor qilish'),
      confirmText: tr('OK', 'ОК', 'OK'),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _dob.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _onIsoChanged(String? v) {
    if (v == null) return;
    setState(() {
      _iso = v;
      _phoneAsyncError = null;
      _phoneExists = false;
    });
    _debouncedCheckPhone();
  }

  /* ------------------------- Submit ------------------------------- */

  Future<void> _submit() async {
    // ensure last async checks ran on current values
    final email = _email.text.trim();
    if (_checkingEmail || email != _lastCheckedEmail) {
      await _checkEmail(email);
    }
    final e164 = _composePhoneE164();
    if (_checkingPhone || e164 != _lastCheckedPhoneE164) {
      await _checkPhone();
    }

    if (!_form.currentState!.validate()) return;
    if (_emailExists || _phoneExists) return;

    final workerPayload = {
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': email,
      'phoneIso2': _iso,
      'phoneDial': _dial,
      'phoneLocal': _phone.text.trim(),
      'phoneE164': e164,
      'dob': _dob.text, // YYYY-MM-DD
      'gender': _gender, // <-- add this
      'type': _workerType,
    };

    Navigator.pushNamed(
      context,
      '/onboarding/provider/congrats',
      arguments: {
        'onboarding': widget.onboardingData,
        'ownerWorker': workerPayload,
        'asWorker': _asWorker, // carry decision forward
      },
    );
  }

  /* ------------------------- Build ------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      resizeToAvoidBottomInset: true,
      appBar: StepAppBar(
        stepLabel: tr('Step 6 of 6', 'Шаг 6 из 6', '6-bosqich / 6'),
        progress: 1.0,
      ),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            children: [
              H1(tr('Your personal info', 'Личные данные', 'Shaxsiy ma’lumot')),
              const SizedBox(height: 8),
              Sub(tr(
                'We’ll use this to create your profile.',
                'Эти данные нужны для вашего профиля.',
                'Ushbu ma’lumotlar profilingiz uchun.',
              )),
              const SizedBox(height: 16),

              TextFormField(
                controller: _firstName,
                decoration: _dec(tr('First name *', 'Имя *', 'Ism *')),
                validator: _req,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastName,
                decoration: _dec(tr('Last name *', 'Фамилия *', 'Familiya *')),
                validator: _req,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Email *').copyWith(
                  suffixIcon: _checkingEmail
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_email.text.trim().isEmpty
                          ? null
                          : (_emailExists
                              ? const Icon(Icons.info_outline,
                                  color: Colors.orange)
                              : const Icon(Icons.check_circle_outline,
                                  color: Colors.green))),
                ),
                onChanged: _debouncedCheckEmail,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),

              Text(
                tr('Phone *', 'Телефон *', 'Telefon *'),
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
                      decoration: _dec(tr('Code', 'Код', 'Kod')),
                      items: _codes
                          .map((e) => DropdownMenuItem<String>(
                                value: e.$1,
                                child: Text('${e.$2} (${e.$1})'),
                              ))
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
                        tr('Number *', 'Номер *', 'Raqam *'),
                        hint:
                            tr('Digits only', 'Только цифры', 'Faqat raqamlar'),
                      ).copyWith(
                        suffixIcon: (_phone.text.trim().isEmpty)
                            ? null
                            : (_checkingPhone
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
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

              // DOB
              TextFormField(
                controller: _dob,
                readOnly: true,
                onTap: _pickDob,
                decoration: _dec(
                  tr('Date of birth *', 'Дата рождения *', 'Tug‘ilgan sana *'),
                  hint: 'YYYY-MM-DD',
                ).copyWith(
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                validator: _dobValidator,
              ),
              const SizedBox(height: 12),

              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                isExpanded: true,
                decoration: _dec(
                  tr('Gender *', 'Пол *', 'Jins *'),
                ),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Male')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null
                    ? tr('Required', 'Обязательно', 'Majburiy')
                    : null,
              ),
              const SizedBox(height: 12),

              // Worker type – only required/shown when they are also a worker
              if (_asWorker)
                DropdownButtonFormField<String>(
                  value: _workerType,
                  isExpanded: true,
                  decoration: _dec(
                    tr('Worker type *', 'Тип сотрудника *', 'Ishchi turi *'),
                  ),
                  items: _workerTypes
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(_typeLabel(t))))
                      .toList(),
                  onChanged: (v) => setState(() => _workerType = v),
                  validator: (v) => v == null
                      ? tr('Required', 'Обязательно', 'Majburiy')
                      : null,
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
              onPressed: _submit,
              child: Text(tr('Continue', 'Продолжить', 'Davom etish')),
            ),
          ),
        ),
      ),
    );
  }
}
