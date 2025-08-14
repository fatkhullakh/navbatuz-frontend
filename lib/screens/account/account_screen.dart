// lib/screens/account/account_screen.dart
import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import 'personal_info_screen.dart';
import 'account_settings_screen.dart';
import 'change_password_screen.dart';
import 'support_screen.dart';
import 'other_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _svc = ProfileService();
  late Future<Me> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.getMe(force: true);
  }

  Future<void> _reload() async {
    setState(() => _future = _svc.getMe(force: true));
    await _future;
  }

  Future<void> _openPersonal(Me me) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PersonalInfoScreen(initial: me)),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _openSettings(Me me) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountSettingsScreen(initial: me)),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _openChangePassword(String userId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChangePasswordScreen(userId: userId)),
    );
    // no data to pull back; just refresh to be safe
    if (!mounted) return;
    await _reload();
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
      appBar: AppBar(title: const Text('Account')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Me>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator()),
                  ]);
            }
            if (snap.hasError) {
              return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text('Failed to load: ${snap.error}')),
                  ]);
            }
            final me = snap.data!;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // --- Header with user info (kept) ---
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (me.fullName.isNotEmpty ? me.fullName[0] : '?')
                            .toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(
                      me.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

                // --- Sections only ---
                _SectionTile(
                  title: 'Personal Info',
                  subtitle: 'Name, Surname, Email, Phone, Birthday, Gender',
                  onTap: () => _openPersonal(me),
                ),
                const SizedBox(height: 12),
                _SectionTile(
                  title: 'Account Settings',
                  subtitle: 'Language, Country',
                  onTap: () => _openSettings(me),
                ),
                const SizedBox(height: 12),
                _SectionTile(
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => _openChangePassword(me.id),
                ),
                const SizedBox(height: 12),
                _SectionTile(
                  title: 'Support',
                  subtitle: 'FAQ, Contact Us, Report a problem',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionTile(
                  title: 'Other',
                  subtitle: 'About, Terms, Privacy',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OtherScreen()),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Logout ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

class _SectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SectionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
