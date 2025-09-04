import 'package:flutter/material.dart';
import 'package:frontend/services/receptionist/receptionist_service.dart';

class ProviderReceptionistCreateScreen extends StatefulWidget {
  final String providerId;
  const ProviderReceptionistCreateScreen({super.key, required this.providerId});

  @override
  State<ProviderReceptionistCreateScreen> createState() =>
      _ProviderReceptionistCreateScreenState();
}

class _ProviderReceptionistCreateScreenState
    extends State<ProviderReceptionistCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _userIdCtrl = TextEditingController();
  DateTime? _hireDate;
  bool _submitting = false;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickHireDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: now,
    );
    if (picked != null) setState(() => _hireDate = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ReceptionistService().create(
        providerId: widget.providerId,
        userId: _userIdCtrl.text.trim(),
        hireDate: _hireDate, // optional; backend defaults to today
      );
      if (!mounted) return;
      Navigator.pop(context, true); // signal success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create receptionist: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hireText = _hireDate == null
        ? 'Hire date: today'
        : 'Hire date: ${_hireDate!.toIso8601String().split('T').first}';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Receptionist')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _userIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'User ID (UUID or email)',
                  hintText: 'Paste user UUID or type email',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text(hireText)),
                  TextButton(
                    onPressed: _pickHireDate,
                    child: const Text('Pick date'),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submitting ? null : _save,
                child: Text(_submitting ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
