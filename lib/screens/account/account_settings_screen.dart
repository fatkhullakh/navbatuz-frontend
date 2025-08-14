// import 'package:flutter/material.dart';
// import '../../services/profile_service.dart';

// class AccountSettingsScreen extends StatefulWidget {
//   final Me initial;
//   const AccountSettingsScreen({super.key, required this.initial});

//   @override
//   State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
// }

// class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
//   String? _language;
//   String? _country;
//   bool _saving = false;

//   final _svc = ProfileService();

//   @override
//   void initState() {
//     super.initState();
//     _language = widget.initial.language;
//     _country = widget.initial.country;
//   }

//   Future<void> _save() async {
//     setState(() => _saving = true);
//     try {
//       final updated =
//           await _svc.updateSettings(language: _language, country: _country);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Settings updated')));
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
//       appBar: AppBar(title: const Text('Account Settings')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           DropdownButtonFormField<String>(
//             value: _language,
//             decoration: const InputDecoration(labelText: 'Language'),
//             items: const [
//               DropdownMenuItem(value: 'EN', child: Text('English')),
//               DropdownMenuItem(value: 'UZ', child: Text('Uzbek')),
//               DropdownMenuItem(value: 'RU', child: Text('Russian')),
//             ],
//             onChanged: (v) => setState(() => _language = v),
//           ),
//           const SizedBox(height: 8),
//           DropdownButtonFormField<String>(
//             value: _country,
//             decoration: const InputDecoration(labelText: 'Country'),
//             items: const [
//               DropdownMenuItem(value: 'UZ', child: Text('Uzbekistan')),
//               DropdownMenuItem(value: 'KZ', child: Text('Kazakhstan')),
//               DropdownMenuItem(value: 'KG', child: Text('Kyrgyzstan')),
//               DropdownMenuItem(value: 'TJ', child: Text('Tajikistan')),
//             ],
//             onChanged: (v) => setState(() => _country = v),
//           ),
//           const SizedBox(height: 24),
//           ListTile(
//             contentPadding: EdgeInsets.zero,
//             title: const Text('Change password',
//                 style: TextStyle(fontWeight: FontWeight.w600)),
//             trailing: const Icon(Icons.chevron_right),
//             onTap: () {
//               // TODO: route to your password screen
//               ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('TODO: Change password')));
//             },
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: FilledButton(
//               onPressed: _saving ? null : _save,
//               child: _saving
//                   ? const SizedBox(
//                       height: 18,
//                       width: 18,
//                       child: CircularProgressIndicator(strokeWidth: 2))
//                   : const Text('Save'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
