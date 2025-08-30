import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:frontend/screens/provider/manage/receptionists/provider_receptionist_invite_screen.dart';
import 'package:frontend/screens/provider/manage/receptionists/provider_receptionist_details_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';
import 'provider_worker_details_screen.dart';
import 'provider_worker_invite_screen.dart';

enum _AddStaffChoice { worker, receptionist }

class ProviderStaffListScreen extends StatefulWidget {
  final String providerId;
  const ProviderStaffListScreen({super.key, required this.providerId});

  @override
  State<ProviderStaffListScreen> createState() =>
      _ProviderStaffListScreenState();
}

class _ProviderStaffListScreenState extends State<ProviderStaffListScreen>
    with SingleTickerProviderStateMixin {
  final ProviderStaffService _service = ProviderStaffService();
  final Dio _dio = ApiService.client;

  bool _loadingWorkers = true;
  bool _loadingRecs = true;

  List<StaffMember> _workers = const [];
  List<ReceptionistMember> _receptionists = const [];

  String _qWorkers = '';
  String _qRecs = '';
  bool _onlyAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _loadReceptionists();
  }

  Future<void> _loadWorkers() async {
    setState(() => _loadingWorkers = true);
    try {
      final list = await _service.getProviderStaff(widget.providerId);
      setState(() => _workers = list);
    } finally {
      if (mounted) setState(() => _loadingWorkers = false);
    }
  }

  Future<void> _loadReceptionists() async {
    setState(() => _loadingRecs = true);
    try {
      final recs = await _service.getActiveReceptionists(widget.providerId);
      setState(() => _receptionists = recs);
    } finally {
      if (mounted) setState(() => _loadingRecs = false);
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Workers filtering
    final workers = _workers.where((m) {
      if (!m.isActive) return false;
      if (_qWorkers.isNotEmpty) {
        final s =
            '${m.displayName} ${m.role ?? ''} ${m.email ?? ''} ${m.phoneNumber ?? ''}'
                .toLowerCase();
        if (!s.contains(_qWorkers.toLowerCase())) return false;
      }
      if (_onlyAvailable && m.status != WorkerStatus.AVAILABLE) return false;
      return true;
    }).toList();

    // Receptionists filtering (already active only from backend)
    final recs = _receptionists.where((r) {
      if (_qRecs.isNotEmpty) {
        final s = '${r.displayName} ${r.email ?? ''} ${r.phoneNumber ?? ''}'
            .toLowerCase();
        if (!s.contains(_qRecs.toLowerCase())) return false;
      }
      return true;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.staff_title ?? 'Staff'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Workers'),
            Tab(text: 'Receptionists'),
          ]),
        ),
        body: TabBarView(
          children: [
            // ------------------- Workers tab -------------------
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: t.staff_search_hint ?? 'Search name or phone…',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (s) => setState(() => _qWorkers = s),
                  ),
                ),
                SwitchListTile(
                  title: Text(t.staff_only_available ?? 'Show only available'),
                  value: _onlyAvailable,
                  onChanged: (v) => setState(() => _onlyAvailable = v),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _loadingWorkers
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadWorkers,
                          child: ListView.builder(
                            itemCount: workers.length,
                            itemBuilder: (_, i) {
                              final m = workers[i];
                              final avatar = (m.avatarUrl ?? '').trim();
                              final normalized = avatar.isEmpty
                                  ? null
                                  : (ApiService.normalizeMediaUrl(avatar) ??
                                      avatar);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: normalized == null
                                      ? null
                                      : NetworkImage(normalized),
                                  child: normalized == null
                                      ? const Icon(Icons.person_outline)
                                      : null,
                                ),
                                title: Text(m.displayName),
                                subtitle: Text([
                                  if ((m.role ?? '').isNotEmpty) m.role!,
                                  if ((m.phoneNumber ?? '').isNotEmpty)
                                    m.phoneNumber!,
                                  if ((m.email ?? '').isNotEmpty) m.email!,
                                ].join(' • ')),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        _statusColor(m.status).withOpacity(.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(_statusText(m.status),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(m.status),
                                      )),
                                ),
                                onTap: () async {
                                  final changed = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProviderWorkerDetailsScreen(
                                        providerId: widget.providerId,
                                        member: m,
                                      ),
                                    ),
                                  );
                                  if (changed == true) _loadWorkers();
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),

            // ---------------- Receptionists tab ----------------
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search name or phone…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (s) => setState(() => _qRecs = s),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _loadingRecs
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadReceptionists,
                          child: ListView.builder(
                            itemCount: recs.length,
                            itemBuilder: (_, i) {
                              final r = recs[i];
                              final avatar = (r.avatarUrl ?? '').trim();
                              final normalized = avatar.isEmpty
                                  ? null
                                  : (ApiService.normalizeMediaUrl(avatar) ??
                                      avatar);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: normalized == null
                                      ? null
                                      : NetworkImage(normalized),
                                  child: normalized == null
                                      ? const Icon(Icons.support_agent_outlined)
                                      : null,
                                ),
                                title: Text(r.displayName),
                                subtitle: Text([
                                  'Receptionist',
                                  if ((r.phoneNumber ?? '').isNotEmpty)
                                    r.phoneNumber!,
                                  if ((r.email ?? '').isNotEmpty) r.email!,
                                ].join(' • ')),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (r.isActive
                                            ? const Color(0xFF12B76A)
                                            : const Color(0xFFB42318))
                                        .withOpacity(.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    r.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: r.isActive
                                          ? const Color(0xFF12B76A)
                                          : const Color(0xFFB42318),
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  final changed = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProviderReceptionistDetailsScreen(
                                        providerId: widget.providerId,
                                        initial: r,
                                      ),
                                    ),
                                  );
                                  if (changed == true) _loadReceptionists();
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add staff'),
          onPressed: () async {
            final choice = await showModalBottomSheet<_AddStaffChoice>(
              context: context,
              showDragHandle: true,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_add_rounded),
                      title: const Text('Add Worker'),
                      onTap: () => Navigator.pop(ctx, _AddStaffChoice.worker),
                    ),
                    ListTile(
                      leading: const Icon(Icons.support_agent_rounded),
                      title: const Text('Add Receptionist'),
                      onTap: () =>
                          Navigator.pop(ctx, _AddStaffChoice.receptionist),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
            if (!mounted || choice == null) return;

            bool? created;
            if (choice == _AddStaffChoice.worker) {
              created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProviderWorkerInviteScreen(providerId: widget.providerId),
                ),
              );
              if (created == true) _loadWorkers();
            } else {
              created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderReceptionistInviteScreen(
                      providerId: widget.providerId),
                ),
              );
              if (created == true) _loadReceptionists();
            }
          },
        ),
      ),
    );
  }
}
