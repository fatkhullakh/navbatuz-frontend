// lib/screens/account/account_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/profile_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _svc = ProfileService();
  late Future<Me> _future;
  final _dateFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _future = _svc.getMe();
  }

  Future<void> _refresh() async {
    setState(() => _future = _svc.getMe());
    await _future;
  }

  Future<void> _editPersonal(Me me) async {
    final res = await showModalBottomSheet<_PersonalResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PersonalSheet(me: me),
    );
    if (res == null) return;
    try {
      final updated = await _svc.updatePersonal(
        name: res.name,
        surname: res.surname,
        phone: res.phone,
        email: res.email,
        dateOfBirth: res.dateOfBirth,
        gender: res.gender,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Personal info updated')));
      setState(() => _future = Future.value(updated));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _editSettings(Me me) async {
    final res = await showModalBottomSheet<_SettingsResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _SettingsSheet(language: me.language, country: me.country),
    );
    if (res == null) return;
    try {
      final updated = await _svc.updateSettings(
          language: res.language, country: res.country);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings updated')));
      setState(() => _future = Future.value(updated));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _logout() async {
    await _svc.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer account')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Me>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                const SizedBox(height: 120),
                Center(child: Text('Failed to load: ${snap.error}')),
              ]);
            }
            final me = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header summary
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (me.fullName.isNotEmpty ? me.fullName[0] : '?')
                            .toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(me.fullName,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.phone,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (me.email.isNotEmpty)
                          Text(me.email,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PERSONAL INFO (collapsed by default)
                _ExpandableSection(
                  title: 'Personal Info',
                  subtitle: 'Name, Surname, Email, Phone, Birthday, Gender',
                  onEdit: () => _editPersonal(me),
                  child: Column(
                    children: [
                      _InfoRow('Name', me.name),
                      _InfoRow('Surname', me.surname),
                      _InfoRow('Email', me.email.isEmpty ? '—' : me.email),
                      _InfoRow('Phone', me.phone),
                      _InfoRow(
                          'Birthday',
                          me.dateOfBirth != null
                              ? _dateFmt.format(me.dateOfBirth!)
                              : '—'),
                      _InfoRow('Gender', me.gender ?? '—'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ACCOUNT SETTINGS (collapsed by default)
                _ExpandableSection(
                  title: 'Account Settings',
                  subtitle: 'Language, Country, Password',
                  onEdit: () => _editSettings(me),
                  child: Column(
                    children: [
                      _InfoRow('Language', me.language ?? '—'),
                      _InfoRow('Country', me.country ?? '—'),
                      Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: const Text('Change password',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: navigate to password screen
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('TODO: Change password')));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _logout,
                    child: const Text('Log out'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------- Reusable expandable section ----------
class _ExpandableSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback onEdit;

  const _ExpandableSection({
    required this.title,
    required this.child,
    required this.onEdit,
    this.subtitle,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          if (widget.subtitle != null)
                            Text(widget.subtitle!,
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 12)),
                        ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit',
                    onPressed: widget.onEdit, // opens sheet to change
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0, // arrow flip
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------- Small UI helpers ----------
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
      ),
    );
  }
}

// ---------- Bottom sheets (edit windows) ----------
class _PersonalResult {
  final String name;
  final String surname;
  final String phone;
  final String email;
  final DateTime? dateOfBirth;
  final String? gender;
  _PersonalResult({
    required this.name,
    required this.surname,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
  });
}

class _PersonalSheet extends StatefulWidget {
  final Me me;
  const _PersonalSheet({required this.me});
  @override
  State<_PersonalSheet> createState() => _PersonalSheetState();
}

class _PersonalSheetState extends State<_PersonalSheet> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _surname;
  late TextEditingController _phone;
  late TextEditingController _email;
  DateTime? _dob;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.me.name);
    _surname = TextEditingController(text: widget.me.surname);
    _phone = TextEditingController(text: widget.me.phone);
    _email = TextEditingController(text: widget.me.email);
    _dob = widget.me.dateOfBirth;
    _gender = widget.me.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2))),
                  const Text('Edit personal info',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _surname,
                    decoration: const InputDecoration(labelText: 'Surname'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final ok =
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                      return ok ? null : 'Invalid email';
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final initial = _dob ??
                              DateTime(now.year - 18, now.month, now.day);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(1900, 1, 1),
                            lastDate: now,
                          );
                          if (picked != null) setState(() => _dob = picked);
                        },
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Birthday'),
                          child: Text(_dob != null
                              ? DateFormat('yyyy-MM-dd').format(_dob!)
                              : '—'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'MALE', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'FEMALE', child: Text('Female')),
                          DropdownMenuItem(
                              value: 'OTHER', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (!_form.currentState!.validate()) return;
                        Navigator.of(context).pop(_PersonalResult(
                          name: _name.text.trim(),
                          surname: _surname.text.trim(),
                          phone: _phone.text.trim(),
                          email: _email.text.trim(),
                          dateOfBirth: _dob,
                          gender: _gender,
                        ));
                      },
                      child: const Text('Save'),
                    ),
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

class _SettingsResult {
  final String? language;
  final String? country;
  _SettingsResult({this.language, this.country});
}

class _SettingsSheet extends StatefulWidget {
  final String? language;
  final String? country;
  const _SettingsSheet({this.language, this.country});
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  String? _language;
  String? _country;

  @override
  void initState() {
    super.initState();
    _language = widget.language;
    _country = widget.country;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2))),
                const Text('Account settings',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'EN', child: Text('English')),
                    DropdownMenuItem(value: 'UZ', child: Text('Uzbek')),
                    DropdownMenuItem(value: 'RU', child: Text('Russian')),
                  ],
                  onChanged: (v) => setState(() => _language = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: const [
                    DropdownMenuItem(value: 'UZ', child: Text('Uzbekistan')),
                    DropdownMenuItem(value: 'KZ', child: Text('Kazakhstan')),
                    DropdownMenuItem(value: 'KG', child: Text('Kyrgyzstan')),
                    DropdownMenuItem(value: 'TJ', child: Text('Tajikistan')),
                  ],
                  onChanged: (v) => setState(() => _country = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_SettingsResult(
                        language: _language, country: _country)),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
