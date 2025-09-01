// lib/screens/onboarding/provider/provider_set_password_screen.dart
import 'package:flutter/material.dart';
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';

class ProviderSetPasswordScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const ProviderSetPasswordScreen({super.key, required this.onboardingData});

  @override
  State<ProviderSetPasswordScreen> createState() =>
      _ProviderSetPasswordScreenState();
}

class _ProviderSetPasswordScreenState extends State<ProviderSetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  bool _ob1 = true, _ob2 = true;

  String get lang => widget.onboardingData.languageCode ?? 'en';
  String _t(String en, String ru, String uz) =>
      lang == 'ru' ? ru : (lang == 'uz' ? uz : en);

  @override
  void dispose() {
    _pwd.dispose();
    _pwd2.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    // Do NOT store password in OnboardingData. Send to backend later in auth flow if needed.
    Navigator.pushNamed(
      context,
      '/onboarding/provider/category',
      arguments: widget.onboardingData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: _t('Step 2 of 6', 'Шаг 2 из 6', '2-bosqich / 6'),
        progress: 2 / 6,
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
                if (v != _pwd.text) {
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
                onPressed: _continue,
                child: Text(_t('Continue', 'Продолжить', 'Davom etish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
