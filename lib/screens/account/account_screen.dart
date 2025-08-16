import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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
      setState(() => _me = me);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
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
    final t = AppLocalizations.of(context)!;

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
            Center(child: Text(t.error_generic)),
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton(
                onPressed: () => _load(force: true),
                child: Text(t.action_retry),
              ),
            ),
          ],
        );
      }
      final me = _me!;
      final fullName =
          [me.name, me.surname].where((s) => (s ?? '').isNotEmpty).join(' ');
      final avatar = (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase();

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(avatar,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              title:
                  Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((me.phoneNumber ?? '').isNotEmpty) Text(me.phoneNumber!),
                  if ((me.email ?? '').isNotEmpty) Text(me.email!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTile(
            title: t.account_personal,
            subtitle: t.account_personal_sub,
            onTap: _openPersonal,
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: t.account_settings,
            subtitle: t.account_settings_sub,
            onTap: _openSettings,
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: t.account_change_password,
            subtitle: t.account_change_password_sub,
            onTap: _openChangePassword,
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: t.account_support,
            subtitle: t.account_support_sub,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: t.account_other,
            subtitle: t.account_other_sub,
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
              child: Text(t.logout),
            ),
          ),
        ],
      );
    }();

    return Scaffold(
      appBar: AppBar(title: Text(t.account_title)),
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
