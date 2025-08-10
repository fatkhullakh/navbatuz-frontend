import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedGender;
  String? selectedLanguage;
  DateTime? selectedDate;
  late String userRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is String) {
      userRole = args;
    } else {
      userRole = 'CUSTOMER';
    }
  }

  void pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.register(
        name: nameController.text.trim(),
        surname: surnameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        role: userRole,
        gender: selectedGender,
        language: selectedLanguage,
        dateOfBirth: selectedDate?.toIso8601String(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: surnameController,
                decoration: const InputDecoration(labelText: "Surname"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone (+998...)"),
                validator: (val) => val == null || val.isEmpty
                    ? "Required"
                    : !RegExp(r"^\+998\d{9}$").hasMatch(val)
                        ? "Invalid"
                        : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (val) => val == null || val.isEmpty
                    ? "Required"
                    : !val.contains("@")
                        ? "Invalid"
                        : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (val) =>
                    val != null && val.length < 6 ? "Too short" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: "Gender"),
                items: ['MALE', 'FEMALE', 'OTHER']
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedGender = val),
              ),
              DropdownButtonFormField<String>(
                value: selectedLanguage,
                decoration: const InputDecoration(labelText: "Language"),
                items: ['UZ', 'RU', 'EN']
                    .map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(l),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedLanguage = val),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? "No birthdate selected"
                          : "DOB: ${selectedDate!.toLocal().toIso8601String().split('T')[0]}",
                    ),
                  ),
                  TextButton(
                    onPressed: pickDateOfBirth,
                    child: const Text("Select DOB"),
                  )
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : handleRegister,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Register"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    children: [
                      TextSpan(
                        text: "Sign in",
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(0.64),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
