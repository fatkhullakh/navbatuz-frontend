import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';
import 'provider_receptionist_edit_screen.dart';

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

  Future<void> _removeFromTeam() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove receptionist?'),
        content: const Text('This will deactivate the receptionist.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _svc.deactivateReceptionist(widget.providerId, _m.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Removed from team')));
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
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
          return 'Male';
        case 'FEMALE':
          return 'Female';
        case 'OTHER':
          return 'Other';
        default:
          return '—';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_m.displayName),
        actions: [
          IconButton(
            tooltip: 'Edit',
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_m.isActive
                                    ? const Color(0xFF12B76A)
                                    : const Color(0xFFB42318))
                                .withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _m.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: _m.isActive
                                  ? const Color(0xFF12B76A)
                                  : const Color(0xFFB42318),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if ((_m.hireDate ?? '').isNotEmpty)
                          Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.calendar_today,
                                size: 14, color: Color(0xFF667085)),
                          ]),
                      ],
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
            subtitle: 'Provider',
          ),
          const _InfoTile(
              leading: Icons.badge_outlined,
              title: 'Receptionist',
              subtitle: 'Role'),
          _InfoTile(
            leading: Icons.wc_outlined,
            title: prettyGender(_m.gender),
            subtitle: 'Gender',
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
              subtitle: 'Hire date',
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Danger zone',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.red)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_off_outlined, color: Colors.red),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red)),
              onPressed: _loading ? null : _removeFromTeam,
              label: const Text('Remove from team'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _InfoTile(
      {required this.leading,
      required this.title,
      required this.subtitle,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(leading),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
