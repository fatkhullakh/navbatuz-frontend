// lib/screens/provider/manage/staff/provider_worker_details_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';

import 'provider_worker_services_screen.dart';
import 'provider_worker_availability_screen.dart';
import 'provider_worker_edit_screen.dart';

/// ---- Brand palette (consistent with other screens) ----
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);

  static const ok = Color(0xFF12B76A); // available
  static const warn = Color(0xFFF59E0B); // break
  static const info = Color(0xFF2E90FA); // leave (blue)
  static const muted = Color(0xFF667085); // unavailable
  static const danger = Color(0xFFB42318); // inactive
}

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
      if (!mounted) return;
      setState(() => _m = fetched);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(WorkerStatus? s, {required bool active}) {
    if (!active) return _Brand.danger;
    switch (s) {
      case WorkerStatus.AVAILABLE:
        return _Brand.ok;
      case WorkerStatus.ON_BREAK:
        return _Brand.warn;
      case WorkerStatus.ON_LEAVE:
        return _Brand.info;
      case WorkerStatus.UNAVAILABLE:
      default:
        return _Brand.muted;
    }
  }

  String _statusText(AppLocalizations t, WorkerStatus? s, bool active) {
    if (!active) return t.inactive ?? 'Inactive';
    switch (s) {
      case WorkerStatus.AVAILABLE:
        return t.available ?? 'Available';
      case WorkerStatus.ON_BREAK:
        return t.on_break ?? 'On break';
      case WorkerStatus.ON_LEAVE:
        return t.on_leave ?? 'On leave';
      case WorkerStatus.UNAVAILABLE:
      default:
        return t.unavailable ?? 'Unavailable';
    }
  }

  Future<void> _changeStatus() async {
    final t = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<WorkerStatus>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            _StatusPickTile(
              label: t.available ?? 'Available',
              color: _Brand.ok,
              selected: _m.status == WorkerStatus.AVAILABLE && _m.isActive,
              onTap: () => Navigator.pop(ctx, WorkerStatus.AVAILABLE),
            ),
            _StatusPickTile(
              label: t.unavailable ?? 'Unavailable',
              color: _Brand.muted,
              selected: _m.status == WorkerStatus.UNAVAILABLE && _m.isActive,
              onTap: () => Navigator.pop(ctx, WorkerStatus.UNAVAILABLE),
            ),
            _StatusPickTile(
              label: t.on_break ?? 'On break',
              color: _Brand.warn,
              selected: _m.status == WorkerStatus.ON_BREAK && _m.isActive,
              onTap: () => Navigator.pop(ctx, WorkerStatus.ON_BREAK),
            ),
            _StatusPickTile(
              label: t.on_leave ?? 'On leave',
              color: _Brand.info,
              selected: _m.status == WorkerStatus.ON_LEAVE && _m.isActive,
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
      if (!mounted) return;
      setState(() => _m = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${t.status ?? "Status"}: ${_statusText(t, _m.status, _m.isActive)}')),
      );
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
        title: Text(t.remove_worker_q ?? 'Remove worker?'),
        content: Text(t.remove_worker_desc ??
            'This will deactivate the worker (soft delete). You can reactivate later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: Text(t.action_cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(_, true),
            style: FilledButton.styleFrom(backgroundColor: _Brand.danger),
            child: Text(t.remove ?? 'Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _staff.deactivateWorker(_m.id);
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

  Future<void> _reactivate() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final updated = await _staff.activateWorker(_m.id);
      if (!mounted) return;
      setState(() => _m = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.worker_activated ?? 'Worker reactivated')),
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

    final avatarUrl = (_m.avatarUrl ?? '').trim();
    final normalizedAvatar = avatarUrl.isEmpty
        ? null
        : (ApiService.normalizeMediaUrl(avatarUrl) ?? avatarUrl);

    String pretty(String? s) => (s == null || s.isEmpty) ? '—' : s;
    String prettyGender(String? g) {
      switch ((g ?? '').toUpperCase()) {
        case 'MALE':
          return t.male ?? 'Male';
        case 'FEMALE':
          return t.female ?? 'Female';
        case 'OTHER':
          return t.other ?? 'Other';
        default:
          return '—';
      }
    }

    final statusFg = _statusColor(_m.status, active: _m.isActive);
    final statusBg = statusFg.withOpacity(.12);
    final statusText = _statusText(t, _m.status, _m.isActive);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _Brand.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: _Brand.ink,
          elevation: 0.5,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_m.displayName),
          actions: [
            IconButton(
              tooltip: t.edit ?? 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.push<StaffMember?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderWorkerEditScreen(initial: _m),
                  ),
                );
                if (updated != null) {
                  if (!mounted) return;
                  setState(() => _m = updated);
                } else {
                  _hydrate();
                }
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _hydrate,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Header card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: _Brand.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFFF2F4F7),
                        backgroundImage: normalizedAvatar == null
                            ? null
                            : NetworkImage(normalizedAvatar),
                        child: normalizedAvatar == null
                            ? const Icon(Icons.person_outline,
                                size: 34, color: _Brand.subtle)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_m.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _Brand.ink,
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _StatusPill(
                                    text: statusText,
                                    fg: statusFg,
                                    bg: statusBg),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.swap_horiz),
                                  onPressed: _loading ? null : _changeStatus,
                                  label:
                                      Text(t.change_status ?? 'Change status'),
                                ),
                                if (_m.avgRating != null)
                                  _ChipRow(
                                    icon: Icons.star,
                                    iconColor: const Color(0xFFFFB703),
                                    text: _m.avgRating!.toStringAsFixed(1),
                                  ),
                                if ((_m.hireDate ?? '').isNotEmpty)
                                  _ChipRow(
                                    icon: Icons.calendar_today,
                                    iconColor: _Brand.subtle,
                                    text: _m.hireDate!,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Details section
              _SectionCard(
                title: t.details ?? 'Details',
                child: Column(
                  children: [
                    _InfoTile(
                      leading: Icons.store_mall_directory_outlined,
                      title: pretty(_m.providerName),
                      subtitle: t.provider ?? 'Provider',
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      leading: Icons.badge_outlined,
                      title: pretty(_m.role),
                      subtitle: t.role ?? 'Role',
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      leading: Icons.wc_outlined,
                      title: prettyGender(_m.gender),
                      subtitle: t.gender ?? 'Gender',
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      leading: Icons.call_outlined,
                      title: pretty(_m.phoneNumber),
                      subtitle: t.phone ?? 'Phone',
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      leading: Icons.alternate_email_outlined,
                      title: pretty(_m.email),
                      subtitle: t.email ?? 'Email',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Manage section (only if active)
              if (_m.isActive)
                _SectionCard(
                  title: t.manage ?? 'Manage',
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _Brand.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.schedule),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProviderWorkerAvailabilityScreen(
                                  workerId: _m.id,
                                  workerName: _m.displayName,
                                ),
                              ),
                            );
                          },
                          label:
                              Text(t.edit_availability ?? 'Edit availability'),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Danger zone
              _SectionCard(
                title: t.danger_zone ?? 'Danger zone',
                titleColor: _Brand.danger,
                child: _m.isActive
                    ? SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _Brand.danger,
                            side: const BorderSide(color: _Brand.danger),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.person_off_outlined),
                          onPressed: _loading ? null : _removeFromTeam,
                          label: Text(t.remove_from_team ?? 'Remove from team'),
                        ),
                      )
                    : SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _Brand.ok,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _loading ? null : _reactivate,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label:
                              Text(t.reactivate_worker ?? 'Reactivate worker'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----- UI bits -----

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? titleColor;
  const _SectionCard({
    required this.title,
    required this.child,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor ?? _Brand.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            child,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        border: Border.all(color: _Brand.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(leading, color: _Brand.subtle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle,
                    style: const TextStyle(
                      color: _Brand.subtle,
                      fontSize: 12,
                    )),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: _Brand.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  const _StatusPill({required this.text, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
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
      trailing: selected ? const Icon(Icons.check, color: _Brand.ok) : null,
      onTap: onTap,
    );
  }
}

class _ChipRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _ChipRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        border: Border.all(color: _Brand.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _Brand.ink,
            ),
          ),
        ],
      ),
    );
  }
}
