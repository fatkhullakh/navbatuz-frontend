// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../services/profile_service.dart';

// class PersonalInfoScreen extends StatefulWidget {
//   final Me initial;
//   const PersonalInfoScreen({super.key, required this.initial});

//   @override
//   State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
// }

// class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
//   final _form = GlobalKey<FormState>();
//   final _dateFmt = DateFormat('yyyy-MM-dd');

//   late TextEditingController _name;
//   late TextEditingController _surname;
//   late TextEditingController _phone;
//   late TextEditingController _email;

//   DateTime? _dob;
//   String? _gender;
//   bool _saving = false;

//   final _svc = ProfileService();

//   @override
//   void initState() {
//     super.initState();
//     _name = TextEditingController(text: widget.initial.name);
//     _surname = TextEditingController(text: widget.initial.surname);
//     _phone = TextEditingController(text: widget.initial.phone);
//     _email = TextEditingController(text: widget.initial.email);
//     _dob = widget.initial.dateOfBirth;
//     _gender = widget.initial.gender;
//   }

//   @override
//   void dispose() {
//     _name.dispose();
//     _surname.dispose();
//     _phone.dispose();
//     _email.dispose();
//     super.dispose();
//   }

//   Future<void> _save() async {
//     if (!_form.currentState!.validate()) return;
//     setState(() => _saving = true);
//     try {
//       final updated = await _svc.updatePersonal(
//         name: _name.text.trim(),
//         surname: _surname.text.trim(),
//         phone: _phone.text.trim(),
//         email: _email.text.trim(),
//         dateOfBirth: _dob,
//         gender: _gender,
//       );
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Personal info updated')));
//       Navigator.of(context).pop(updated);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Update failed: $e')));
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Personal Info')),
//       body: Form(
//         key: _form,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             TextFormField(
//               controller: _name,
//               decoration: const InputDecoration(labelText: 'Name'),
//               textInputAction: TextInputAction.next,
//               validator: (v) =>
//                   (v == null || v.trim().isEmpty) ? 'Required' : null,
//             ),
//             const SizedBox(height: 8),
//             TextFormField(
//               controller: _surname,
//               decoration: const InputDecoration(labelText: 'Surname'),
//               textInputAction: TextInputAction.next,
//             ),
//             const SizedBox(height: 8),
//             TextFormField(
//               controller: _phone,
//               decoration: const InputDecoration(labelText: 'Phone'),
//               keyboardType: TextInputType.phone,
//               textInputAction: TextInputAction.next,
//               validator: (v) =>
//                   (v == null || v.trim().isEmpty) ? 'Required' : null,
//             ),
//             const SizedBox(height: 8),
//             TextFormField(
//               controller: _email,
//               decoration: const InputDecoration(labelText: 'Email'),
//               keyboardType: TextInputType.emailAddress,
//               validator: (v) {
//                 if (v == null || v.isEmpty) return null; // optional
//                 final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
//                 return ok ? null : 'Invalid email';
//               },
//             ),
//             const SizedBox(height: 8),
//             Row(children: [
//               Expanded(
//                 child: InkWell(
//                   onTap: () async {
//                     final now = DateTime.now();
//                     final initial =
//                         _dob ?? DateTime(now.year - 18, now.month, now.day);
//                     final picked = await showDatePicker(
//                       context: context,
//                       initialDate: initial,
//                       firstDate: DateTime(1900, 1, 1),
//                       lastDate: now,
//                     );
//                     if (picked != null) setState(() => _dob = picked);
//                   },
//                   child: InputDecorator(
//                     decoration: const InputDecoration(labelText: 'Birthday'),
//                     child: Text(_dob != null ? _dateFmt.format(_dob!) : '—'),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: DropdownButtonFormField<String>(
//                   value: _gender,
//                   decoration: const InputDecoration(labelText: 'Gender'),
//                   items: const [
//                     DropdownMenuItem(value: 'MALE', child: Text('Male')),
//                     DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
//                     DropdownMenuItem(value: 'OTHER', child: Text('Other')),
//                   ],
//                   onChanged: (v) => setState(() => _gender = v),
//                 ),
//               ),
//             ]),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton(
//                 onPressed: _saving ? null : _save,
//                 child: _saving
//                     ? const SizedBox(
//                         height: 18,
//                         width: 18,
//                         child: CircularProgressIndicator(strokeWidth: 2))
//                     : const Text('Save'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
