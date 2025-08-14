import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import 'personal_info_screen.dart';
import 'account_settings_screen.dart';
import 'change_password_screen.dart';
import 'support_screen.dart';
import 'other_screen.dart';

// TODO: user can change email and phone number in seperate section cause we need to send SMS to verify

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _svc = ProfileService();

  Me? _me;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(force: true);
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await _svc.getMe(force: force);
      if (!mounted) return;
      setState(() {
        _me = me;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Future<void> _openPersonal() async {
    if (_me == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PersonalInfoScreen(initial: _me!)),
    );
    if (changed == true) await _load(force: true);
  }

  Future<void> _openSettings() async {
    if (_me == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AccountSettingsScreen(initial: _me!)),
    );
    if (changed == true) await _load(force: true);
  }

  Future<void> _openChangePassword() async {
    if (_me == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ChangePasswordScreen(userId: _me!.id)),
    );
    // no user fields change here, but keep behavior consistent
    if (changed == true) await _load(force: true);
  }

  Future<void> _logout() async {
    await _svc.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final body = () {
      if (_loading && _me == null && _error == null) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        );
      }
      if (_error != null) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(child: Text('Failed to load: $_error')),
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton(
                onPressed: () => _load(force: true),
                child: const Text('Retry'),
              ),
            ),
          ],
        );
      }
      final me = _me!;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header with user's info (kept)
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  (me.fullName.isNotEmpty ? me.fullName[0] : '?').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(me.fullName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(me.phoneNumber),
                  if (me.email.isNotEmpty) Text(me.email),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sections only (tap to navigate)
          _SectionTile(
            title: 'Personal Info',
            subtitle: 'Name, Surname, Email, Phone, Birthday, Gender',
            onTap: _openPersonal,
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: 'Account Settings',
            subtitle: 'Language, Country',
            onTap: _openSettings,
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: _openChangePassword,
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: 'Support',
            subtitle: 'FAQ, Contact Us, Report a problem',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: 'Other',
            subtitle: 'About, Terms, Privacy',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OtherScreen())),
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
    }();

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: RefreshIndicator(onRefresh: () => _load(force: true), child: body),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SectionTile(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle:
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
