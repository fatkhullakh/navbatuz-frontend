import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  final storage = const FlutterSecureStorage();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response =
          await ApiService.login(_email.text.trim(), _password.text);
      final token = response.data?['token'];
      if (token == null || token is! String || token.isEmpty) {
        throw Exception('Malformed login response: ${response.data}');
      }
      final Map<String, dynamic> claims = Jwt.parseJwt(token);
      final rawRole = (claims['role'] ??
              claims['roles'] ??
              claims['authorities'] ??
              'CUSTOMER')
          .toString()
          .toUpperCase();
      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'user_role', value: rawRole);

      if (!mounted) return;
      if (rawRole.contains('CUSTOMER')) {
        Navigator.pushReplacementNamed(context, '/customers');
      } else if (rawRole.contains('OWNER') || rawRole.contains('PROVIDER')) {
        Navigator.pushReplacementNamed(context, '/providers');
      } else if (rawRole.contains('WORKER')) {
        Navigator.pushReplacementNamed(context, '/customers'); // adjust later
      } else {
        Navigator.pushReplacementNamed(context, '/customers');
      }
    } on DioException catch (dioErr) {
      if (!mounted) return;
      final code = dioErr.response?.statusCode;
      final body = dioErr.response?.data;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $code ${body ?? ''}')));
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("NavbatUz Login",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Enter email" : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Enter password" : null),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text("Don't have an account? Register"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text("Forgot password?"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
