import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/* ---------------------------- Brand constants ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String _role = 'CUSTOMER'; // CUSTOMER | OWNER | WORKER
  String? _gender; // MALE | FEMALE
  String _language = 'EN'; // EN | RU | UZ
  DateTime? _dob;

  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
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
      backgroundColor: _Brand.surfaceSoft,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: _dec('Name'),
              validator: _req,
            ),
            inputPad,
            TextFormField(
              controller: _surname,
              decoration: _dec('Surname'),
              validator: _req,
            ),
            inputPad,
            TextFormField(
              controller: _phone,
              decoration: _dec('Phone (+998...)'),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Required';
                // Basic sanity (don’t over-restrict)
                final ok = RegExp(r'^\+?\d{9,15}$').hasMatch(v!.trim());
                return ok ? null : 'Invalid phone';
              },
            ),
            inputPad,
            TextFormField(
              controller: _email,
              decoration: _dec('Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!)) {
                  return 'Invalid email';
                }
                return null;
              },
            ),
            inputPad,
            TextFormField(
              controller: _password,
              decoration: _dec(
                'Password',
                suffix: IconButton(
                  icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              obscureText: !_showPassword,
              validator: (v) => (v ?? '').length < 6 ? 'Min 6 chars' : null,
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
              decoration: _dec('Role'),
            ),
            inputPad,
            DropdownButtonFormField<String>(
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _gender = v),
              decoration: _dec('Gender (optional)'),
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
              decoration: _dec('Language'),
            ),
            inputPad,
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Birthday (optional)'),
              subtitle: Text(
                _dob == null
                    ? '—'
                    : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: _Brand.subtle),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDob,
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
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create account'),
              ),
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
