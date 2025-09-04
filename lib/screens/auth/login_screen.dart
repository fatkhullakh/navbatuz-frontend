import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../models/onboarding_data.dart';
import '../../services/api_service.dart';
import '../../services/providers/provider_resolver_service.dart';
import '../../services/workers/workers_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
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

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showPassword = false;
  final storage = const FlutterSecureStorage();

  // --- i18n helpers (read active app locale) ---
  String get lang {
    final lc = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lc == 'ru' || lc == 'uz') return lc;
    return 'en';
  }

  String tr(String en, String ru, String uz) =>
      lang == 'ru' ? ru : (lang == 'uz' ? uz : en);

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

  String _extractRole(dynamic raw) {
    if (raw == null) return 'CUSTOMER';
    if (raw is List) {
      return raw.map((e) => e.toString().toUpperCase()).join(',');
    }
    return raw.toString().toUpperCase();
  }

  bool _has(String rolesCsvUpper, String needle) =>
      rolesCsvUpper.contains(needle);

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final resp = await ApiService.login(_email.text.trim(), _password.text);
      final token = resp.data?['token'];
      if (token is! String || token.isEmpty) {
        throw Exception('Malformed login response');
      }

      await storage.write(key: 'jwt_token', value: token);
      ApiService.setToken(token);

      final claims = Jwt.parseJwt(token);
      final rolesCsv = _extractRole(
        claims['role'] ??
            claims['roles'] ??
            claims['authorities'] ??
            'CUSTOMER',
      );

      // 1) Pure worker (no owner/receptionist) → worker shell
      if (_has(rolesCsv, 'WORKER') &&
          !_has(rolesCsv, 'OWNER') &&
          !_has(rolesCsv, 'RECEPTIONIST')) {
        final me = await WorkersApi().me();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/workers',
          (_) => false,
          arguments: {'workerId': me.id},
        );
        return;
      }

      // 2) Owner / Receptionist (provider-side) → provider shell
      if (_has(rolesCsv, 'OWNER') || _has(rolesCsv, 'RECEPTIONIST')) {
        try {
          final providerId =
              await ProviderResolverService().resolveMyProviderId();
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/providers',
            (_) => false,
            arguments: providerId,
          );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(
                  'Your account is not linked to a branch',
                  'Ваш аккаунт не привязан к филиалу',
                  'Hisobingiz filialga ulangan emas')),
            ),
          );
        }
        return;
      }

      // 3) Everyone else → customer shell
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/customers', (_) => false);
    } on DioException catch (dioErr) {
      if (!mounted) return;
      final code = dioErr.response?.statusCode;
      final message = (code == 401 || code == 403)
          ? tr('Invalid email or password.', 'Неверный email или пароль.',
              'Email yoki parol noto‘g‘ri.')
          : tr(
              'Login failed. Try again.',
              'Не удалось войти. Повторите попытку.',
              'Kirish muvaffaqiyatsiz. Qaytadan urinib ko‘ring.');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Login failed: $e', 'Ошибка входа: $e', 'Kirish xatosi: $e'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goRegister() {
    // Register flow expects OnboardingData (for language threading)
    final data = OnboardingData(languageCode: lang);
    Navigator.pushNamed(context, '/register', arguments: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Branding header card
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: _Brand.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: _Brand.accentSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lock_outline,
                                color: _Brand.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('Welcome back', 'С возвращением',
                                      'Qaytganingiz bilan'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _Brand.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr(
                                      'Sign in to continue',
                                      'Войдите, чтобы продолжить',
                                      'Davom etish uchun kiring'),
                                  style: const TextStyle(color: _Brand.subtle),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec(tr('Email', 'Email', 'Email')),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) {
                        return tr(
                            'Enter email', 'Введите email', 'Email kiriting');
                      }
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(v!.trim());
                      return ok
                          ? null
                          : tr('Invalid email', 'Некорректный email',
                              'Noto‘g‘ri email');
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _password,
                    decoration: _dec(
                      tr('Password', 'Пароль', 'Parol'),
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    obscureText: !_showPassword,
                    validator: (v) => (v == null || v.isEmpty)
                        ? tr('Enter password', 'Введите пароль',
                            'Parol kiriting')
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Login button
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _Brand.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _loading ? null : _handleLogin,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(tr('Login', 'Войти', 'Kirish')),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Links
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _loading ? null : _goRegister,
                          child: Text(
                            tr(
                                "Don't have an account? Register",
                                'Нет аккаунта? Зарегистрируйтесь',
                                'Hisob yo‘qmi? Ro‘yxatdan o‘ting'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.pushNamed(
                                    context, '/forgot-password'),
                            child: Text(
                              tr('Forgot password?', 'Забыли пароль?',
                                  'Parol esdan chiqdimi?'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
