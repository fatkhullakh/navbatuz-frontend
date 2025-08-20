import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../services/api_service.dart';
import '../../services/provider_resolver_service.dart'; // ← NEW

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/* ---------------------------- Brand constants ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7); // #6A89A7
  static const accentSoft = Color(0xFFBDDDFC); // #BDDDFC
  static const ink = Color(0xFF384959); // #384959
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

  // ← RESTORED helper
  String _extractRole(dynamic raw) {
    if (raw == null) return 'CUSTOMER';
    if (raw is List) {
      return raw.map((e) => e.toString().toUpperCase()).join(',');
    }
    return raw.toString().toUpperCase();
  }

  bool _isProviderSide(String rolesCsvUpper) {
    return rolesCsvUpper.contains('OWNER') ||
        rolesCsvUpper.contains('PROVIDER') ||
        rolesCsvUpper.contains('RECEPTIONIST') ||
        rolesCsvUpper.contains('WORKER');
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response =
          await ApiService.login(_email.text.trim(), _password.text);
      final token = response.data?['token'];
      if (token == null || token is! String || token.isEmpty) {
        throw Exception('Malformed login response');
      }

      final claims = Jwt.parseJwt(token);
      final rawRole = _extractRole(
        claims['role'] ??
            claims['roles'] ??
            claims['authorities'] ??
            'CUSTOMER',
      );

      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'user_role', value: rawRole);

      if (!mounted) return;

      if (_isProviderSide(rawRole)) {
        // Try to resolve providerId (nullable is OK)
        String? providerId;
        try {
          providerId = await ProviderResolverService().resolveMyProviderId();
        } catch (_) {}
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/providers',
          (_) => false,
          arguments:
              providerId, // can be null, your /providers route should handle it
        );
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/customers', (_) => false);
      }
    } on DioException catch (dioErr) {
      if (!mounted) return;
      final code = dioErr.response?.statusCode;
      final message = (code == 401 || code == 403)
          ? 'Invalid email or password.'
          : 'Login failed. Try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  const Text(
                    "NavbatUz Login",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _Brand.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec("Email"),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return "Enter email";
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(v!.trim());
                      return ok ? null : 'Invalid email';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: _dec(
                      "Password",
                      suffix: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    obscureText: !_showPassword,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Enter password" : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _Brand.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loading ? null : _handleLogin,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Login"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.pushNamed(context, '/register'),
                    child: const Text("Don't have an account? Register"),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text("Forgot password?"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
