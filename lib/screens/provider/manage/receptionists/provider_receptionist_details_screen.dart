// lib/screens/provider/manage/receptionists/provider_receptionist_details_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';
import 'provider_receptionist_edit_screen.dart';

/// ---- Brand palette to match other screens ----
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);

  static const ok = Color(0xFF12B76A);
  static const danger = Color(0xFFB42318);
}

class ProviderReceptionistDetailsScreen extends StatefulWidget {
  final String providerId;
  final ReceptionistMember initial;

  const ProviderReceptionistDetailsScreen({
    super.key,
    required this.providerId,
    required this.initial,
  });

  @override
  State<ProviderReceptionistDetailsScreen> createState() =>
      _ProviderReceptionistDetailsScreenState();
}

class _ProviderReceptionistDetailsScreenState
    extends State<ProviderReceptionistDetailsScreen> {
  final _svc = ProviderStaffService();
  late ReceptionistMember _m;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _m = widget.initial;
    _hydrate();
  }

  Future<void> _hydrate() async {
    setState(() => _loading = true);
    try {
      final fetched = await _svc.getReceptionist(widget.providerId, _m.id);
      setState(() => _m = fetched);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reactivate() async {
    setState(() => _loading = true);
    try {
      final updated = await _svc.activateReceptionistReturn(
        widget.providerId,
        _m.id,
      );
      setState(() => _m = updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.receptionist_reactivated ??
                'Receptionist reactivated',
          ),
        ),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFromTeam() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.remove_receptionist_q ?? 'Remove receptionist?'),
        content: Text(t.remove_receptionist_desc ??
            'This will deactivate the receptionist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: Text(t.action_cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(_, true),
            child: Text(t.action_remove ?? 'Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _svc.deactivateReceptionist(widget.providerId, _m.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.removed_from_team ?? 'Removed from team')),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final avatar = (_m.avatarUrl ?? '').trim();
    final normalized = avatar.isEmpty
        ? null
        : (ApiService.normalizeMediaUrl(avatar) ?? avatar);

    String pretty(String? s) => (s == null || s.isEmpty) ? '—' : s;
    String prettyGender(String? g) {
      switch ((g ?? '').toUpperCase()) {
        case 'MALE':
          return t.gender_male ?? 'Male';
        case 'FEMALE':
          return t.gender_female ?? 'Female';
        case 'OTHER':
          return t.gender_other ?? 'Other';
        default:
          return '—';
      }
    }

    final theme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: _Brand.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _Brand.ink,
        elevation: 0.5,
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_m.displayName),
          actions: [
            IconButton(
              tooltip: t.action_edit ?? 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.push<ReceptionistMember?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderReceptionistEditScreen(
                      providerId: widget.providerId,
                      initial: _m,
                    ),
                  ),
                );
                if (updated != null) {
                  setState(() => _m = updated);
                } else {
                  _hydrate();
                }
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFF2F4F7),
                  backgroundImage:
                      normalized == null ? null : NetworkImage(normalized),
                  child: normalized == null
                      ? const Icon(Icons.support_agent_outlined, size: 36)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_m.displayName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_m.isActive ? _Brand.ok : _Brand.danger)
                              .withOpacity(.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _m.isActive
                              ? (t.active ?? 'Active')
                              : (t.inactive ?? 'Inactive'),
                          style: TextStyle(
                            color: _m.isActive ? _Brand.ok : _Brand.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoTile(
              leading: Icons.store_mall_directory_outlined,
              title: pretty(_m.providerName),
              subtitle: t.provider ?? 'Provider',
            ),
            _InfoTile(
              leading: Icons.badge_outlined,
              title: t.receptionist ?? 'Receptionist',
              subtitle: t.role ?? 'Role',
            ),
            _InfoTile(
              leading: Icons.wc_outlined,
              title: prettyGender(_m.gender),
              subtitle: t.gender ?? 'Gender',
            ),
            _InfoTile(
              leading: Icons.call_outlined,
              title: pretty(_m.phoneNumber),
              subtitle: t.phone ?? 'Phone',
            ),
            _InfoTile(
              leading: Icons.alternate_email_outlined,
              title: pretty(_m.email),
              subtitle: t.email ?? 'Email',
            ),
            if ((_m.hireDate ?? '').isNotEmpty)
              _InfoTile(
                leading: Icons.calendar_month_outlined,
                title: pretty(_m.hireDate),
                subtitle: t.hire_date ?? 'Hire date',
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            if (_m.isActive)
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  icon:
                      const Icon(Icons.person_off_outlined, color: Colors.red),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: _loading ? null : _removeFromTeam,
                  label: Text(t.remove_from_team ?? 'Remove from team'),
                ),
              )
            else
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _reactivate,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                      t.reactivate_receptionist ?? 'Reactivate receptionist'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _InfoTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _Brand.border),
      ),
      child: ListTile(
        leading: Icon(leading, color: _Brand.ink),
        title: Text(
          title,
          style:
              const TextStyle(fontWeight: FontWeight.w700, color: _Brand.ink),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: _Brand.subtle)),
        trailing: trailing,
      ),
    );
  }
}
