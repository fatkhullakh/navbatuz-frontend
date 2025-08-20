import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../services/profile/profile_service.dart';
import '../../services/media/uploads_service.dart';
import '../../services/api_service.dart';
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
  final _uploads = UploadsService();
  final _picker = ImagePicker();

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

  // ---- Avatar actions ----

  void _onAvatarPressed(Me me, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: _Brand.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: Text(t.action_change_photo),
              onTap: () async {
                Navigator.pop(context);
                await _changeAvatar(me);
              },
            ),
            if ((me.avatarUrl ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: Text(t.action_remove_photo),
                onTap: () async {
                  Navigator.pop(context);
                  await _removeAvatar(me);
                },
              ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(t.action_view_photo),
              onTap: () {
                Navigator.pop(context);
                _viewAvatar(me);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeAvatar(Me me) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final url = await _uploads.uploadUserAvatar(
        userId: me.id,
        filePath: picked.path,
      );
      await _svc.setAvatarUrl(me.id, url);
      if (!mounted) return;
      await _load(force: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar: $e')),
      );
    }
  }

  Future<void> _removeAvatar(Me me) async {
    try {
      await _svc.removeAvatar(me.id);
      if (!mounted) return;
      await _load(force: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove avatar: $e')),
      );
    }
  }

  void _viewAvatar(Me me) {
    final url = ApiService.normalizeMediaUrl(me.avatarUrl);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: AspectRatio(
          aspectRatio: 1,
          child: url == null
              ? const Center(child: Icon(Icons.account_circle, size: 120))
              : InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.network(url, fit: BoxFit.cover),
                ),
        ),
      ),
    );
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
            Center(child: _BrandSpinner()),
          ],
        );
      }
      if (_error != null) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const _ErrorState(message: 'Something went wrong'),
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
      final avatarLetter =
          (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase();
      final avatarUrl = ApiService.normalizeMediaUrl(me.avatarUrl);

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              leading: GestureDetector(
                onTap: () => _onAvatarPressed(me, t),
                child: _Avatar(
                  url: avatarUrl,
                  fallbackLetter: avatarLetter,
                ),
              ),
              title: Text(
                fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((me.phoneNumber ?? '').isNotEmpty)
                    Text(me.phoneNumber!,
                        style: const TextStyle(color: _Brand.subtle)),
                  if ((me.email ?? '').isNotEmpty)
                    Text(me.email!,
                        style: const TextStyle(color: _Brand.subtle)),
                ],
              ),
              trailing: IconButton(
                onPressed: () => _onAvatarPressed(me, t),
                icon: const Icon(Icons.edit),
                tooltip: t.action_change_photo,
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionTile(
            title: t.account_other,
            subtitle: t.account_other_sub,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OtherScreen()),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _DangerButton(
              text: t.logout,
              onPressed: _logout,
            ),
          ),
        ],
      );
    }();

    return Theme(
      data: _brandTheme(context),
      child: Scaffold(
        backgroundColor: _Brand.bg,
        appBar: AppBar(
          title: Text(t.account_title),
          backgroundColor: _Brand.surface1,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: _Brand.primary,
          onRefresh: () => _load(force: true),
          child: body,
        ),
      ),
    );
  }
}

/* ---------------------------- Brand + Theme ---------------------------- */

class _Brand {
  static const primary = Color(0xFF6A89A7); // #6A89A7
  static const accent = Color(0xFF88BDF2); // #88BDF2
  static const accentSoft = Color(0xFFBDDDFC); // #BDDDFC
  static const ink = Color(0xFF384959); // #384959

  static const bg = Color(0xFFF6F8FC);
  static const surface1 = Colors.white;
  static const surface2 = Color(0xFFF2F6FC);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
}

ThemeData _brandTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    scaffoldBackgroundColor: _Brand.bg,
    colorScheme: ColorScheme.light(
      primary: _Brand.primary,
      secondary: _Brand.accent,
      surface: _Brand.surface1,
      onSurface: _Brand.ink,
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      foregroundColor: _Brand.ink,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: const IconThemeData(color: _Brand.ink),
    dividerColor: _Brand.border,
    textTheme: base.textTheme.apply(
      bodyColor: _Brand.ink,
      displayColor: _Brand.ink,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _Brand.primary,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _Brand.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _Brand.accentSoft.withOpacity(0.25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

/* ------------------------------ Widgets ------------------------------- */

class _Avatar extends StatelessWidget {
  final String? url;
  final String fallbackLetter;
  const _Avatar({required this.url, required this.fallbackLetter});

  @override
  Widget build(BuildContext context) {
    final image = (url != null) ? NetworkImage(url!) : null;
    return Container(
      padding: const EdgeInsets.all(2), // ring
      decoration: BoxDecoration(
        color: _Brand.accentSoft.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: _Brand.border, width: 1),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundImage: image,
        child: image == null
            ? Text(
                fallbackLetter,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: _Brand.ink),
              )
            : null,
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
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle:
              Text(subtitle, style: const TextStyle(color: _Brand.subtle)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class _DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _DangerButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _BrandSpinner extends StatelessWidget {
  const _BrandSpinner();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(strokeWidth: 3),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 32, color: _Brand.primary),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
