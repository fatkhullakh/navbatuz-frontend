import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';

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
  final storage = FlutterSecureStorage();

  void handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        final response = await ApiService.login(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        final token = response.data['token'];
        final role = response.data['role'];

        await storage.write(key: 'jwt_token', value: token);
        await storage.write(key: 'user_role', value: role);

        if (role == 'CUSTOMER') {
          Navigator.pushReplacementNamed(context, '/customers');
        } else if (role == 'OWNER') {
          Navigator.pushReplacementNamed(context, '/providers');
          } else if (role == 'WORKER') {
            Navigator.pushReplacementNamed(context, '/workers');
          } else {
            Navigator.pushReplacementNamed(context, '/customers');
        }
      } on DioException catch (dioErr) {
        print(
            "❌ DioException: ${dioErr.response?.statusCode} ${dioErr.response?.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Login failed: ${dioErr.response?.statusCode ?? 'Unknown'}')),
        );
      } catch (e) {
        print("❌ Dio error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed')),
        );
      }

      setState(() => isLoading = false);
    }

    print("Attempting login...");
    print("Email: ${emailController.text.trim()}");
    print("Password: ${passwordController.text.trim()}");
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
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 160, 107, 87))),
                const SizedBox(height: 40),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter email" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter password" : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
