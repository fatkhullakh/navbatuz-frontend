import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';

import 'provider_worker_services_screen.dart';
import 'provider_worker_availability_screen.dart';
import 'provider_worker_edit_screen.dart';

class ProviderWorkerDetailsScreen extends StatefulWidget {
  final String providerId;
  final StaffMember member;

  const ProviderWorkerDetailsScreen({
    super.key,
    required this.providerId,
    required this.member,
  });

  @override
  State<ProviderWorkerDetailsScreen> createState() =>
      _ProviderWorkerDetailsScreenState();
}

class _ProviderWorkerDetailsScreenState
    extends State<ProviderWorkerDetailsScreen> {
  final ProviderStaffService _staff = ProviderStaffService();

  late StaffMember _m;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _m = widget.member;
    _hydrate();
  }

  Future<void> _hydrate() async {
    setState(() => _loading = true);
    try {
      final fetched = await _staff.getWorker(_m.id);
      setState(() => _m = fetched);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(WorkerStatus? s) {
    switch (s) {
      case WorkerStatus.AVAILABLE:
        return const Color(0xFF12B76A);
      case WorkerStatus.ON_BREAK:
        return const Color(0xFFF59E0B);
      case WorkerStatus.ON_LEAVE:
        return const Color(0xFF7C3AED);
      case WorkerStatus.UNAVAILABLE:
      default:
        return const Color(0xFF667085);
    }
  }

  String _statusText(WorkerStatus? s) {
    switch (s) {
      case WorkerStatus.AVAILABLE:
        return 'Available';
      case WorkerStatus.UNAVAILABLE:
        return 'Unavailable';
      case WorkerStatus.ON_BREAK:
        return 'On break';
      case WorkerStatus.ON_LEAVE:
        return 'On leave';
      default:
        return '—';
    }
  }

  Future<void> _changeStatus() async {
    final choice = await showModalBottomSheet<WorkerStatus>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _StatusPickTile(
              label: 'Available',
              color: _statusColor(WorkerStatus.AVAILABLE),
              selected: _m.status == WorkerStatus.AVAILABLE,
              onTap: () => Navigator.pop(ctx, WorkerStatus.AVAILABLE),
            ),
            _StatusPickTile(
              label: 'Unavailable',
              color: _statusColor(WorkerStatus.UNAVAILABLE),
              selected: _m.status == WorkerStatus.UNAVAILABLE,
              onTap: () => Navigator.pop(ctx, WorkerStatus.UNAVAILABLE),
            ),
            _StatusPickTile(
              label: 'On break',
              color: _statusColor(WorkerStatus.ON_BREAK),
              selected: _m.status == WorkerStatus.ON_BREAK,
              onTap: () => Navigator.pop(ctx, WorkerStatus.ON_BREAK),
            ),
            _StatusPickTile(
              label: 'On leave',
              color: _statusColor(WorkerStatus.ON_LEAVE),
              selected: _m.status == WorkerStatus.ON_LEAVE,
              onTap: () => Navigator.pop(ctx, WorkerStatus.ON_LEAVE),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;
    setState(() => _loading = true);
    try {
      final updated = await _staff.updateWorker(_m.id, status: choice);
      setState(() => _m = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status: ${_statusText(_m.status)}')),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFromTeam() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove worker?'),
        content: const Text(
            'This will deactivate the worker (soft delete). You can re-invite later.'),
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
      await _staff.deactivate(_m.id);
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

    final avatarUrl = (_m.avatarUrl ?? '').trim();
    final normalizedAvatar = avatarUrl.isEmpty
        ? null
        : (ApiService.normalizeMediaUrl(avatarUrl) ?? avatarUrl);

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
              final updated = await Navigator.push<StaffMember?>(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderWorkerEditScreen(initial: _m),
                ),
              );
              if (updated != null) {
                setState(() => _m = updated);
              } else {
                // re-hydrate in case server changed something
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
                backgroundImage: normalizedAvatar == null
                    ? null
                    : NetworkImage(normalizedAvatar),
                child: normalizedAvatar == null
                    ? const Icon(Icons.person_outline, size: 36)
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
                            color: _statusColor(_m.status).withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  size: 10, color: _statusColor(_m.status)),
                              const SizedBox(width: 6),
                              Text(_statusText(_m.status),
                                  style: TextStyle(
                                      color: _statusColor(_m.status),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: _loading ? null : _changeStatus,
                          label: const Text('Change status'),
                        ),
                        if (_m.avgRating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Color(0xFFFFB703)),
                              const SizedBox(width: 4),
                              Text('${_m.avgRating!.toStringAsFixed(1)}'),
                            ],
                          ),
                        if ((_m.hireDate ?? '').isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Color(0xFF667085)),
                            ],
                          ),
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
          _InfoTile(
            leading: Icons.badge_outlined,
            title: pretty(_m.role),
            subtitle: 'Role',
          ),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              icon: const Icon(Icons.design_services_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderWorkerServicesScreen(
                      providerId: widget.providerId,
                      workerId: _m.id,
                      workerName: _m.displayName,
                    ),
                  ),
                );
              },
              label: Text(t.manage_services ?? 'Manage services'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderWorkerAvailabilityScreen(
                      workerId: _m.id,
                      workerName: _m.displayName,
                    ),
                  ),
                );
              },
              label: Text(t.edit_availability ?? 'Edit availability'),
            ),
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
                side: const BorderSide(color: Colors.red),
              ),
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
      child: ListTile(
        leading: Icon(leading),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}

class _StatusPickTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusPickTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.circle, color: color),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}
