import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/onboarding_data.dart';
import 'package:frontend/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  /// This screen must receive OnboardingData from RoleSelectionScreen
  /// (or earlier) so we know the picked language.
  final OnboardingData onboardingData;
  const RegisterScreen({super.key, required this.onboardingData});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/* ---------------------------- Brand ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  final _phoneLocal = TextEditingController();
  final _dob = TextEditingController();

  // phone code selector
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

  String? _gender; // MALE | FEMALE | OTHER
  DateTime? _birthDate;

  bool _loading = false;

  // async exists checks
  bool _checkingEmail = false, _emailExists = false;
  bool _checkingPhone = false, _phoneExists = false;
  Timer? _debounceEmail, _debouncePhone;
  String _lastCheckedEmail = '';
  String _lastCheckedPhoneE164 = '';
  String? _emailAsyncError, _phoneAsyncError;

  String get _lang =>
      (widget.onboardingData.languageCode ?? 'en').toLowerCase();
  String _t(String en, String ru, String uz) =>
      _lang == 'ru' ? ru : (_lang == 'uz' ? uz : en);

  @override
  void initState() {
    super.initState();
    // Prefill from onboarding (if any)
    _email.text = widget.onboardingData.ownerEmail ?? '';
    _name.text = widget.onboardingData.ownerName ?? '';
    _surname.text = widget.onboardingData.ownerSurname ?? '';
    _iso = widget.onboardingData.businessPhoneIso2 ?? 'UZ';
    if (_email.text.trim().isNotEmpty) _debouncedCheckEmail(_email.text.trim());
    if ((widget.onboardingData.ownerPhoneE164 ?? '').isNotEmpty) {
      // try to split E.164 into local if matches current dial code
      final e = widget.onboardingData.ownerPhoneE164!;
      if (e.startsWith(_dial)) _phoneLocal.text = e.substring(_dial.length);
    }
    if (_phoneLocal.text.isNotEmpty) _debouncedCheckPhone();
  }

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _email.dispose();
    _phoneLocal.dispose();
    _dob.dispose();
    _debounceEmail?.cancel();
    _debouncePhone?.cancel();
    super.dispose();
  }

  /* ------------------------- Decorations ------------------------ */
  InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.primary, width: 1.5),
        ),
      );

  /* ------------------------- Async checks ----------------------- */
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
    } on DioException {
      if (!mounted) return;
      setState(() {
        _emailAsyncError = _t('Network error', 'Ошибка сети', 'Tarmoq xatosi');
        _checkingEmail = false;
      });
    }
  }

  String _composeE164() => '$_dial${_phoneLocal.text.trim()}';

  void _debouncedCheckPhone() {
    _debouncePhone?.cancel();
    _debouncePhone =
        Timer(const Duration(milliseconds: 350), () => _checkPhone());
  }

  Future<void> _checkPhone() async {
    final local = _phoneLocal.text.trim();
    if (local.isEmpty || local.length != _requiredLen) {
      setState(() {
        _checkingPhone = false;
        _phoneExists = false;
        _phoneAsyncError = null;
        _lastCheckedPhoneE164 = '';
      });
      return;
    }
    final e164 = _composeE164();
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
    } on DioException {
      if (!mounted) return;
      setState(() {
        _phoneAsyncError = _t('Network error', 'Ошибка сети', 'Tarmoq xatosi');
        _checkingPhone = false;
      });
    }
  }

  /* --------------------------- DOB picker ----------------------- */
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 100, 1, 1);
    final last = DateTime(now.year - 10, 12, 31);
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(last) ? initial : last,
      firstDate: first,
      lastDate: last,
      helpText: _t('Date of birth', 'Дата рождения', 'Tug‘ilgan sana'),
      cancelText: _t('Cancel', 'Отмена', 'Bekor qilish'),
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _dob.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  /* --------------------------- Submit -------------------------- */
  Future<void> _continue() async {
    // ensure async checks reflect current values
    final email = _email.text.trim();
    if (_checkingEmail || email != _lastCheckedEmail) {
      await _checkEmail(email);
    }
    final e164 = _composeE164();
    if (_checkingPhone || e164 != _lastCheckedPhoneE164) {
      await _checkPhone();
    }

    if (!_form.currentState!.validate()) return;
    if (_emailExists || _phoneExists) return;

    // Push to password screen with all data packed into OnboardingData
    final updated = widget.onboardingData.copyWith(
      role: 'CUSTOMER',
      ownerName: _name.text.trim(),
      ownerSurname: _surname.text.trim(),
      ownerEmail: email,
      ownerPhoneE164: e164,
      ownerGender: _gender,
      ownerDateOfBirth: _dob.text.isEmpty ? null : _dob.text,
      // keep previously chosen languageCode as-is
    );

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/auth/set-password',
      arguments: updated,
    );
  }

  /* --------------------------- Validators ---------------------- */
  String? _req(String? v) => (v == null || v.trim().isEmpty)
      ? _t('Required', 'Обязательно', 'Majburiy')
      : null;

  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return _t('Required', 'Обязательно', 'Majburiy');
    final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(s);
    if (!ok)
      return _t('Invalid email', 'Некорректный email', 'Noto‘g‘ri email');
    if (_checkingEmail) return _t('Checking…', 'Проверка…', 'Tekshirilmoqda…');
    if (_emailExists) {
      return _t(
          'Email already in use. Use another.',
          'Email уже используется. Укажите другой.',
          'Bu email band. Boshqasini kiriting.');
    }
    if (_emailAsyncError != null) return _emailAsyncError;
    return null;
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return _t('Required', 'Обязательно', 'Majburiy');
    if (!RegExp(r'^\d+$').hasMatch(s)) {
      return _t('Digits only', 'Только цифры', 'Faqat raqamlar');
    }
    if (s.length != _requiredLen) {
      return _t('Enter $_requiredLen digits', 'Введите $_requiredLen цифр',
          '$_requiredLen ta raqam kiriting');
    }
    if (_checkingPhone) return _t('Checking…', 'Проверка…', 'Tekshirilmoqda…');
    if (_phoneExists) {
      return _t(
          'Phone already in use. Use another.',
          'Телефон уже используется. Укажите другой.',
          'Bu raqam band. Boshqasini kiriting.');
    }
    if (_phoneAsyncError != null) return _phoneAsyncError;
    return null;
  }

  /* ---------------------------- Build -------------------------- */
  @override
  Widget build(BuildContext context) {
    final inputPad = const SizedBox(height: 12);

    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
            _t('Create your account', 'Создайте аккаунт', 'Hisob yarating'),
            style: const TextStyle(color: _Brand.subtle, fontSize: 16)),
      ),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Name
            TextFormField(
              controller: _name,
              decoration: _dec(_t('First name *', 'Имя *', 'Ism *')),
              validator: _req,
            ),
            inputPad,
            TextFormField(
              controller: _surname,
              decoration: _dec(_t('Last name *', 'Фамилия *', 'Familiya *')),
              validator: _req,
            ),
            inputPad,

            // Email
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec(_t('Email *', 'Email *', 'Email *')).copyWith(
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
            inputPad,

            // Phone (code + local)
            Text(
              _t('Phone *', 'Телефон *', 'Telefon *'),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: _Brand.ink),
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
                        .map((e) => DropdownMenuItem<String>(
                              value: e.$1,
                              child: Text('${e.$2} (${e.$1})'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _iso = v;
                        _phoneAsyncError = null;
                        _phoneExists = false;
                      });
                      _debouncedCheckPhone();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 12,
                  child: TextFormField(
                    controller: _phoneLocal,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _dec(
                      _t('Number *', 'Номер *', 'Raqam *'),
                      // hint: _t('Digits only', 'Только цифры', 'Faqat raqamlar'),
                    ).copyWith(
                      suffixIcon: (_phoneLocal.text.trim().isEmpty)
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
            inputPad,

            // DOB
            TextFormField(
              controller: _dob,
              readOnly: true,
              onTap: _pickDob,
              decoration: _dec(
                _t('Date of birth (optional)', 'Дата рождения (необязательно)',
                    'Tug‘ilgan sana (ixtiyoriy)'),
                // hint: 'YYYY-MM-DD',
              ).copyWith(
                suffixIcon: const Icon(Icons.calendar_month_outlined),
              ),
            ),
            inputPad,

            // Gender (optional)
            DropdownButtonFormField<String>(
              value: _gender,
              isExpanded: true,
              decoration: _dec(_t('Gender (optional)', 'Пол (необязательно)',
                  'Jins (ixtiyoriy)')),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 20),

            // Continue → password screen
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _loading ? null : _continue,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_t('Continue', 'Продолжить', 'Davom etish')),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text(_t('Already have an account? Log in',
                  'Уже есть аккаунт? Войти', 'Hisobingiz bormi? Kirish')),
            ),
          ],
        ),
      ),
    );
  }
}
