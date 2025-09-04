import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

/* ---------------------------- Brand ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const surfaceSoft = Color(0xFFF6F9FC);
  static const subtle = Color(0xFF7C8B9B);
}

class ForgotPasswordResetScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordResetScreen({super.key, required this.email});

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _showNew = false, _showConfirm = false;

  // i18n
  String get lang {
    final lc = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lc == 'ru' || lc == 'uz') return lc;
    return 'en';
  }

  String tr(String en, String ru, String uz) =>
      lang == 'ru' ? ru : (lang == 'uz' ? uz : en);

  @override
  void dispose() {
    _code.dispose();
    _new.dispose();
    _confirm.dispose();
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
          borderSide: const BorderSide(color: _Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.primary, width: 1.5),
        ),
      );

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    if (_new.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('Passwords do not match', 'Пароли не совпадают',
                'Parollar mos kelmaydi'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.resetPassword(
        email: widget.email.trim(),
        code: _code.text.trim(),
        newPassword: _new.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Password updated. Please log in.',
              'Пароль обновлён. Войдите.', 'Parol yangilandi. Kiring.')),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?.toString() ??
          tr('Reset failed', 'Не удалось сбросить', 'Qayta o‘rnatib bo‘lmadi');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: AppBar(
        title: Text(tr('Reset Password', 'Сброс пароля', 'Parolni tiklash')),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _Brand.border),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: _Brand.surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.email_outlined,
                          color: _Brand.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${widget.email}',
                              style: const TextStyle(color: _Brand.subtle)),
                          const SizedBox(height: 2),
                          Text(
                            tr(
                                'Check your inbox for the 6-digit code.',
                                'Проверьте почту: код из 6 цифр.',
                                '6 xonali kod uchun pochtangizni tekshiring.'),
                            style: const TextStyle(color: _Brand.ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration:
                  _dec(tr('6-digit code', '6-значный код', '6 xonali kod')),
              validator: (v) => (v == null || v.trim().length != 6)
                  ? tr('Enter the 6-digit code', 'Введите 6-значный код',
                      '6 xonali kodni kiriting')
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _new,
              decoration: _dec(
                tr('New password', 'Новый пароль', 'Yangi parol'),
                suffix: IconButton(
                  icon:
                      Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
              obscureText: !_showNew,
              validator: (v) => (v == null || v.length < 6)
                  ? tr('Min 6 characters', 'Минимум 6 символов',
                      'Kamida 6 belgi')
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirm,
              decoration: _dec(
                tr('Confirm new password', 'Подтвердите новый пароль',
                    'Yangi parolni tasdiqlang'),
                suffix: IconButton(
                  icon: Icon(
                      _showConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              obscureText: !_showConfirm,
              validator: (v) => (v == null || v.isEmpty)
                  ? tr('Required', 'Обязательно', 'Majburiy')
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _reset,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(tr('Reset password', 'Сбросить пароль',
                        'Parolni tiklash')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
