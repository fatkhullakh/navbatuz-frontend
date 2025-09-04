// lib/screens/onboarding/provider/provider_email_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';
import 'package:frontend/services/api_service.dart';

/// Prefer passing this via --dart-define=API_BASE=https://your.api
const String _kApiBase =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8080');

class ProviderEmailScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const ProviderEmailScreen({super.key, required this.onboardingData});

  @override
  State<ProviderEmailScreen> createState() => _ProviderEmailScreenState();
}

class _ProviderEmailScreenState extends State<ProviderEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _checking = false;
  bool _exists = false;
  String? _error;

  Timer? _debounce;
  String _lastCheckedEmail = '';

  String get lang => widget.onboardingData.languageCode ?? 'en';
  String _t(String en, String ru, String uz) =>
      lang == 'ru' ? ru : (lang == 'uz' ? uz : en);

  @override
  void initState() {
    super.initState();
    _email.text = widget.onboardingData.businessEmail ?? '';
    final pre = _email.text.trim();
    if (pre.isNotEmpty) _debouncedCheck(pre);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _debouncedCheck(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _check(value));
  }

  Future<void> _check(String value) async {
    final v = value.trim();
    _lastCheckedEmail = v;

    if (v.isEmpty) {
      setState(() {
        _exists = false;
        _error = null;
        _checking = false;
      });
      return;
    }

    final valid = RegExp(r'^\S+@\S+\.\S+$').hasMatch(v);
    if (!valid) {
      setState(() {
        _exists = false;
        _error = _t('Invalid email', 'Некорректный email', 'Noto‘g‘ri email');
        _checking = false;
      });
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final res = await ApiService.client.get(
        '/providers/public/email-exists',
        queryParameters: {'email': v},
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      if (!mounted) return;

      final data = res.data is Map ? (res.data as Map) : {};
      setState(() {
        _exists = data['exists'] == true;
        _checking = false;
      });
    } on DioError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _t('Network error', 'Ошибка сети', 'Tarmoq xatosi');
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _t('Network error', 'Ошибка сети', 'Tarmoq xatosi');
        _checking = false;
      });
    }
  }

  Future<void> _continue() async {
    final current = _email.text.trim();
    if (current != _lastCheckedEmail || _checking) {
      await _check(current);
    }
    if (!_form.currentState!.validate()) return;
    if (_exists) return; // hard block: show validator + login CTA
    widget.onboardingData.businessEmail = current;
    Navigator.pushNamed(context, '/onboarding/provider/set-password',
        arguments: widget.onboardingData);
  }

  @override
  Widget build(BuildContext context) {
    final title = _t('Your work email', 'Рабочая почта', 'Ishchi email');
    final sub = _t(
        'Use an email you check often.',
        'Укажите почту, которой вы пользуетесь.',
        'Doimiy ishlatadigan emailingizni kiriting.');
    final label = 'Email';

    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: _t('Step 1 of 6', 'Шаг 1 из 6', '1-bosqich / 6'),
        progress: 1 / 6,
      ),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            H1(title),
            const SizedBox(height: 8),
            Sub(sub),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
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
                  borderSide:
                      const BorderSide(color: Brand.primary, width: 1.5),
                ),
                suffixIcon: _email.text.trim().isEmpty
                    ? null
                    : (_checking
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : (_exists
                            ? const Icon(Icons.info_outline,
                                color: Colors.orange)
                            : const Icon(Icons.check_circle_outline,
                                color: Colors.green))),
              ),
              onChanged: _debouncedCheck,
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) {
                  return _t('Required', 'Обязательно', 'Majburiy');
                }
                final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(s);
                if (!ok) {
                  return _t(
                      'Invalid email', 'Некорректный email', 'Noto‘g‘ri email');
                }
                if (_checking) {
                  return _t('Checking…', 'Проверка…', 'Tekshirilmoqda…');
                }
                if (_exists) {
                  return _t(
                    'Email already registered. Please log in.',
                    'Email уже зарегистрирован. Войдите.',
                    'Email allaqachon ro‘yxatdan o‘tgan. Tizimga kiring.',
                  );
                }
                if (_error != null) return _error; // network/server error
                return null;
              },
            ),
            if (_exists) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Brand.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Brand.subtle),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t(
                          'This email belongs to an existing provider. Log in instead.',
                          'Этот email уже используется провайдером. Выполните вход.',
                          'Bu email allaqachon mavjud. Iltimos, tizimga kiring.',
                        ),
                        style: const TextStyle(color: Brand.ink),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: Text(_t('Log in', 'Войти', 'Kirish')),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null && !_exists) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: (_exists || _checking) ? null : _continue,
                child: Text(_t('Continue', 'Продолжить', 'Davom etish')),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(_t(
                    'Already have an account? Log in',
                    'Уже есть аккаунт? Войти',
                    'Allaqachon akkaunt bormi? Kirish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
