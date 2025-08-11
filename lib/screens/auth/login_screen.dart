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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final storage = const FlutterSecureStorage();

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final response = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      // Expect backend to return only { token: "..." }
      final token = response.data?['token'];
      if (token == null || token is! String || token.isEmpty) {
        throw Exception('Malformed login response: ${response.data}');
      }

      // Decode role from JWT claims
      final Map<String, dynamic> claims = Jwt.parseJwt(token);
      // Try common claim names; default to CUSTOMER
      final rawRole = (claims['role'] ??
              claims['roles'] ??
              claims['authorities'] ??
              'CUSTOMER')
          .toString()
          .toUpperCase();

      // Persist
      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'user_role', value: rawRole);

      // Route by role
      if (rawRole.contains('CUSTOMER')) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/customers');
      } else if (rawRole.contains('OWNER') || rawRole.contains('PROVIDER')) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/providers');
      } else if (rawRole.contains('WORKER')) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/workers');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/customers');
      }
    } on DioException catch (dioErr) {
      if (!mounted) return;
      final code = dioErr.response?.statusCode;
      final body = dioErr.response?.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $code ${body ?? ''}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }

    // Debug prints (optional)
    // print("Attempting login...");
    // print("Email: ${emailController.text.trim()}");
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
                const Text(
                  "NavbatUz Login",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 160, 107, 87),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Enter email" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Enter password" : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text("Don't have an account? Register"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/change-password');
                  },
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
