import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/onboarding_data.dart';
import 'package:frontend/screens/onboarding/onboarding_ui.dart';
import 'package:frontend/services/api_service.dart';

class CustomerSetPasswordScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const CustomerSetPasswordScreen({super.key, required this.onboardingData});

  @override
  State<CustomerSetPasswordScreen> createState() =>
      _CustomerSetPasswordScreenState();
}

class _CustomerSetPasswordScreenState extends State<CustomerSetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  bool _ob1 = true, _ob2 = true;
  bool _loading = false;

  String get lang => (widget.onboardingData.languageCode ?? 'en').toLowerCase();
  String _t(String en, String ru, String uz) =>
      lang == 'ru' ? ru : (lang == 'uz' ? uz : en);

  @override
  void dispose() {
    _pwd.dispose();
    _pwd2.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // Build CUSTOMER payload from onboardingData
      final d = widget.onboardingData;
      final body = <String, dynamic>{
        'name': (d.ownerName ?? '').trim(),
        'surname': (d.ownerSurname ?? '').trim(),
        'email': (d.ownerEmail ?? '').trim(),
        'phoneNumber': (d.ownerPhoneE164 ?? '').trim(),
        'password': _pwd.text.trim(),
        'language': (d.languageCode ?? 'en').toUpperCase(),
        'country': (d.countryIso2 ?? 'UZ').toUpperCase(),
        'role': 'CUSTOMER',
        if ((d.ownerDateOfBirth ?? '').isNotEmpty)
          'dateOfBirth': d.ownerDateOfBirth,
        if ((d.ownerGender ?? '').isNotEmpty) 'gender': d.ownerGender,
      };

      await ApiService.register(body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_t(
                'Registered! Please log in.',
                'Регистрация успешна! Войдите.',
                'Ro‘yxatdan o‘tildi! Kiring.'))),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final data = e.response?.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register failed: $code ${data ?? ''}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: _t('Step 2 of 2', 'Шаг 2 из 2', '2-bosqich / 2'),
        progress: 1.0,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            H1(_t('Create a password', 'Создайте пароль', 'Parol yarating')),
            const SizedBox(height: 8),
            Sub(_t('Use at least 8 characters.', 'Не менее 8 символов.',
                'Kamida 8 ta belgi.')),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pwd,
              obscureText: _ob1,
              decoration: InputDecoration(
                labelText: _t('Password', 'Пароль', 'Parol'),
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
                suffixIcon: IconButton(
                  icon: Icon(_ob1 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _ob1 = !_ob1),
                ),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.length < 8) {
                  return _t('At least 8 characters', 'Минимум 8 символов',
                      'Kamida 8 ta belgi');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pwd2,
              obscureText: _ob2,
              decoration: InputDecoration(
                labelText: _t('Confirm password', 'Подтвердите пароль',
                    'Parolni tasdiqlang'),
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
                suffixIcon: IconButton(
                  icon: Icon(_ob2 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _ob2 = !_ob2),
                ),
              ),
              validator: (v) {
                if ((v ?? '') != _pwd.text) {
                  return _t('Passwords do not match', 'Пароли не совпадают',
                      'Parollar mos kelmayapti');
                }
                return null;
              },
            ),
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
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_t(
                        'Create account', 'Создать аккаунт', 'Hisob yaratish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
