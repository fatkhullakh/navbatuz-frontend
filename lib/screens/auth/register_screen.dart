import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String _role = 'CUSTOMER'; // CUSTOMER | OWNER | WORKER (adjust as you like)
  String? _gender; // MALE | FEMALE
  String _language = 'EN'; // EN | RU | UZ
  DateTime? _dob;

  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10),
      initialDate: _dob ?? DateTime(now.year - 20),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'surname': _surname.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'role': _role,
        'language': _language,
        if (_gender != null) 'gender': _gender,
        if (_dob != null)
          'dateOfBirth':
              '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
      };

      // NOTE: ApiService.register takes a Map body (not named params)
      await ApiService.register(body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered! Please log in.')),
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

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final inputPad = const SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _req,
            ),
            inputPad,
            TextFormField(
              controller: _surname,
              decoration: const InputDecoration(labelText: 'Surname'),
              validator: _req,
            ),
            inputPad,
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone (+998...)'),
              validator: _req,
              keyboardType: TextInputType.phone,
            ),
            inputPad,
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Required';
                if (!RegExp(r'.+@.+\..+').hasMatch(v!)) return 'Invalid email';
                return null;
              },
              keyboardType: TextInputType.emailAddress,
            ),
            inputPad,
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) => (v ?? '').length < 6 ? 'Min 6 chars' : null,
              obscureText: true,
            ),
            inputPad,
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'CUSTOMER', child: Text('Customer')),
                DropdownMenuItem(value: 'OWNER', child: Text('Owner')),
                DropdownMenuItem(value: 'WORKER', child: Text('Worker')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'CUSTOMER'),
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            inputPad,
            DropdownButtonFormField<String>(
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _gender = v),
              decoration: const InputDecoration(labelText: 'Gender (optional)'),
            ),
            inputPad,
            DropdownButtonFormField<String>(
              value: _language,
              items: const [
                DropdownMenuItem(value: 'EN', child: Text('English')),
                DropdownMenuItem(value: 'RU', child: Text('Русский')),
                DropdownMenuItem(value: 'UZ', child: Text("O‘zbek")),
              ],
              onChanged: (v) => setState(() => _language = v ?? 'EN'),
              decoration: const InputDecoration(labelText: 'Language'),
            ),
            inputPad,
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Birthday (optional)'),
              subtitle: Text(
                _dob == null
                    ? '—'
                    : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDob,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Create account'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
