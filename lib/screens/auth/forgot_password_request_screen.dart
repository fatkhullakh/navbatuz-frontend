import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import 'forgot_password_reset_screen.dart';

/* ---------------------------- Brand ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const surfaceSoft = Color(0xFFF6F9FC);
  static const subtle = Color(0xFF7C8B9B);
}

class ForgotPasswordRequestScreen extends StatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  State<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState
    extends State<ForgotPasswordRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;

  // ---- i18n helpers ----
  String get lang {
    final lc = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lc == 'ru' || lc == 'uz') return lc;
    return 'en';
  }

  String tr(String en, String ru, String uz) =>
      lang == 'ru' ? ru : (lang == 'uz' ? uz : en);

  @override
  void dispose() {
    _email.dispose();
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
          borderSide: const BorderSide(color: _Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.primary, width: 1.5),
        ),
      );

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);

    final genericMsg = tr(
      'If the email exists, a code was sent.',
      'Если такой email существует, код отправлен.',
      'Email mavjud bo‘lsa, kod yuborildi.',
    );

    try {
      await ApiService.forgotPassword(_email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(genericMsg)));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordResetScreen(email: _email.text.trim()),
        ),
      );
    } on DioException {
      if (!mounted) return;
      // Same message to avoid leaking account existence
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(genericMsg)));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordResetScreen(email: _email.text.trim()),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: AppBar(
        title: Text(
            tr('Forgot Password', 'Забыли пароль', 'Parolni unutdingizmi')),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // header card
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _Brand.border),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                child: Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: _Brand.surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mark_email_unread_outlined,
                          color: _Brand.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(
                          'Enter your account email. We will send a 6-digit code.',
                          'Укажите email аккаунта. Мы отправим 6-значный код.',
                          'Hisobingiz emailini kiriting. 6 xonali kod yuboramiz.',
                        ),
                        style: const TextStyle(color: _Brand.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('Email'),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) {
                  return tr('Required', 'Обязательно', 'Majburiy');
                }
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                return ok
                    ? null
                    : tr('Invalid email', 'Некорректный email',
                        'Noto‘g‘ri email');
              },
            ),
            const SizedBox(height: 18),

            SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(tr('Send code', 'Отправить код', 'Kod yuborish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
