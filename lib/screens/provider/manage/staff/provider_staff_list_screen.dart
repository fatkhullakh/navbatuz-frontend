// lib/screens/provider/manage/staff/provider_staff_list_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';

import '../receptionists/provider_receptionist_details_screen.dart';
import '../receptionists/provider_receptionist_invite_screen.dart';
import 'provider_worker_details_screen.dart';
import 'provider_worker_invite_screen.dart';

enum _AddStaffChoice { worker, receptionist }

/// ---- Brand palette (same family as other screens) ----
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);

  static const ok = Color(0xFF12B76A); // available
  static const warn = Color(0xFFF59E0B); // break
  static const info = Color(0xFF2E90FA); // leave (blue, not purple)
  static const muted = Color(0xFF667085); // unavailable
  static const danger = Color(0xFFB42318); // inactive
}

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

  bool _showInactiveWorkers = false;
  bool _showInactiveRecs = false;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _loadReceptionists();
  }

  final Map<String, String?> _workerAvatarCache = {};
  final Set<String> _avatarInFlight = {}; // de-dup requests

  Future<void> _ensureWorkerAvatar(StaffMember m) async {
    // prefer the model's own avatar if it exists
    if ((m.avatarUrl ?? '').isNotEmpty) {
      _workerAvatarCache[m.id] = m.avatarUrl!;
      return;
    }
    if (_workerAvatarCache.containsKey(m.id)) return; // already resolved
    if (_avatarInFlight.contains(m.id)) return; // already fetching

    _avatarInFlight.add(m.id);
    try {
      final detailed = await _service.getWorker(m.id); // returns StaffMember
      final url =
          (detailed.avatarUrl ?? '').trim().isEmpty ? null : detailed.avatarUrl;

      // Update cache and list item
      if (!mounted) return;
      setState(() {
        _workerAvatarCache[m.id] = url;
        _workers = _workers
            .map((w) => w.id == m.id ? w.copyWith(avatarUrl: url) : w)
            .toList();
      });
    } catch (_) {
      // mark as "no avatar" to avoid retry storms
      _workerAvatarCache[m.id] = null;
    } finally {
      _avatarInFlight.remove(m.id);
    }
  }

  Future<void> _loadWorkers() async {
    setState(() => _loadingWorkers = true);
    try {
      final list = await _service.getProviderStaff(
        widget.providerId,
        activeOnly: !_showInactiveWorkers,
      );
      if (mounted) setState(() => _workers = list);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final txt = e.response?.data?.toString() ?? e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('HTTP $code: $txt')));
      }
    } finally {
      if (mounted) setState(() => _loadingWorkers = false);
    }
  }

  Future<void> _loadReceptionists() async {
    setState(() => _loadingRecs = true);
    try {
      final recs = await _service.getReceptionists(
        widget.providerId,
        active: !_showInactiveRecs,
      );
      if (mounted) setState(() => _receptionists = recs);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final txt = e.response?.data?.toString() ?? e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('HTTP $code: $txt')));
      }
    } finally {
      if (mounted) setState(() => _loadingRecs = false);
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
        return _Brand.info; // blue
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Workers filter
    final workers = _workers.where((m) {
      if (_showInactiveWorkers == false && !m.isActive) return false;
      if (_qWorkers.isNotEmpty) {
        final s =
            '${m.displayName} ${m.role ?? ''} ${m.email ?? ''} ${m.phoneNumber ?? ''}'
                .toLowerCase();
        if (!s.contains(_qWorkers.toLowerCase())) return false;
      }
      if (_onlyAvailable &&
          (m.isActive && m.status != WorkerStatus.AVAILABLE)) {
        return false;
      }
      return true;
    }).toList();

    // Receptionists filter
    final recs = _receptionists.where((r) {
      if (_showInactiveRecs == false && !r.isActive) return false;
      if (_qRecs.isNotEmpty) {
        final s = '${r.displayName} ${r.email ?? ''} ${r.phoneNumber ?? ''}'
            .toLowerCase();
        if (!s.contains(_qRecs.toLowerCase())) return false;
      }
      return true;
    }).toList();

    final theme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: _Brand.bg,
      tabBarTheme: TabBarThemeData(
        labelColor: _Brand.ink,
        unselectedLabelColor: _Brand.subtle,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: _Brand.primary, width: 3),
          insets: EdgeInsets.zero,
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: _Brand.subtle),
        prefixIconColor: _Brand.subtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Brand.primary, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

    return Theme(
      data: theme,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0.5,
            backgroundColor: Colors.white,
            foregroundColor: _Brand.ink,
            title: Text(t.staff_title ?? 'Staff'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Workers'),
                Tab(text: 'Receptionists'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // ------------------- Workers tab -------------------
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _SearchField(
                      hint: t.staff_search_hint ?? 'Search name or phone…',
                      onChanged: (s) => setState(() => _qWorkers = s),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChipBool(
                          label: t.staff_only_available ?? 'Only available',
                          value: _onlyAvailable,
                          onChanged: (v) => setState(() => _onlyAvailable = v),
                        ),
                        _FilterChipBool(
                          label: t.show_inactive_workers ?? 'Show inactive',
                          value: _showInactiveWorkers,
                          onChanged: (v) async {
                            setState(() => _showInactiveWorkers = v);
                            await _loadWorkers();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _loadingWorkers
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _loadWorkers,
                            child: workers.isEmpty
                                ? const _EmptyState(
                                    icon: Icons.group_outlined,
                                    title: 'No workers',
                                    caption:
                                        'Invite your first worker to appear here.',
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 16),
                                    itemCount: workers.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, i) {
                                      final m = workers[i];

                                      // kick off a one-time lazy fetch for avatar (non-blocking)
                                      _ensureWorkerAvatar(m);

                                      // decide which URL to render (model or cached)
                                      final img = (m.avatarUrl ??
                                              _workerAvatarCache[m.id]) ??
                                          '';
                                      final hasImg = img.startsWith('http');

                                      final pillColor = _statusColor(m.status,
                                          active: m.isActive);
                                      final pillBg =
                                          pillColor.withOpacity(0.12);
                                      final pillText =
                                          _statusText(t, m.status, m.isActive);

                                      return _PersonCard(
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: _Brand.bg,
                                          backgroundImage:
                                              hasImg ? NetworkImage(img) : null,
                                          child: hasImg
                                              ? null
                                              : const Icon(Icons.person_outline,
                                                  color: _Brand.subtle),
                                        ),
                                        title: m.displayName,
                                        subtitle: [
                                          if ((m.role ?? '').isNotEmpty)
                                            m.role!,
                                          if ((m.phoneNumber ?? '').isNotEmpty)
                                            m.phoneNumber!,
                                          if ((m.email ?? '').isNotEmpty)
                                            m.email!,
                                        ].join(' • '),
                                        trailing: _StatusPill(
                                            text: pillText,
                                            fg: pillColor,
                                            bg: pillBg),
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _SearchField(
                      hint: t.staff_search_hint ?? 'Search name or phone…',
                      onChanged: (s) => setState(() => _qRecs = s),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _FilterChipBool(
                        label: t.show_inactive_receptionists ?? 'Show inactive',
                        value: _showInactiveRecs,
                        onChanged: (v) async {
                          setState(() => _showInactiveRecs = v);
                          await _loadReceptionists();
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _loadingRecs
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _loadReceptionists,
                            child: recs.isEmpty
                                ? const _EmptyState(
                                    icon: Icons.support_agent_outlined,
                                    title: 'No receptionists',
                                    caption:
                                        'Invite a receptionist to manage bookings.',
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 16),
                                    itemCount: recs.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, i) {
                                      final r = recs[i];
                                      final avatar = (r.avatarUrl ?? '').trim();
                                      final normalized = avatar.isEmpty
                                          ? null
                                          : (ApiService.normalizeMediaUrl(
                                                  avatar) ??
                                              avatar);

                                      final fg = r.isActive
                                          ? _Brand.ok
                                          : _Brand.danger;
                                      final bg = fg.withOpacity(.12);

                                      return _PersonCard(
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: _Brand.bg,
                                          backgroundImage: normalized == null
                                              ? null
                                              : NetworkImage(normalized),
                                          child: normalized == null
                                              ? const Icon(
                                                  Icons.support_agent_outlined,
                                                  color: _Brand.subtle,
                                                )
                                              : null,
                                        ),
                                        title: r.displayName,
                                        subtitle: [
                                          t.receptionist ?? 'Receptionist',
                                          if ((r.phoneNumber ?? '').isNotEmpty)
                                            r.phoneNumber!,
                                          if ((r.email ?? '').isNotEmpty)
                                            r.email!,
                                        ].join(' • '),
                                        trailing: _StatusPill(
                                          text: r.isActive
                                              ? (t.active ?? 'Active')
                                              : (t.inactive ?? 'Inactive'),
                                          fg: fg,
                                          bg: bg,
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
                                          if (changed == true) {
                                            _loadReceptionists();
                                          }
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
            backgroundColor: _Brand.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(t.add_staff ?? 'Add staff'),
            onPressed: () async {
              final choice = await showModalBottomSheet<_AddStaffChoice>(
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
                      ListTile(
                        leading: const Icon(Icons.person_add_rounded),
                        title: Text(t.add_worker ?? 'Add Worker'),
                        onTap: () => Navigator.pop(ctx, _AddStaffChoice.worker),
                      ),
                      ListTile(
                        leading: const Icon(Icons.support_agent_rounded),
                        title: Text(t.add_receptionist ?? 'Add Receptionist'),
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
                    builder: (_) => ProviderWorkerInviteScreen(
                        providerId: widget.providerId),
                  ),
                );
                if (created == true) _loadWorkers();
              } else {
                created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderReceptionistInviteScreen(
                      providerId: widget.providerId,
                    ),
                  ),
                );
                if (created == true) _loadReceptionists();
              }
            },
          ),
        ),
      ),
    );
  }
}

/// -------- atoms --------

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.tune, color: _Brand.subtle),
      ),
      onChanged: onChanged,
    );
  }
}

class _FilterChipBool extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FilterChipBool({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: value,
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: _Brand.primary.withOpacity(.12),
      shape: StadiumBorder(side: BorderSide(color: _Brand.border)),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: value ? _Brand.primary : _Brand.subtle,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: value ? _Brand.primary : _Brand.ink,
            ),
          ),
        ],
      ),
      onSelected: (v) => onChanged(!value ? true : false),
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
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _PersonCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _Brand.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _Brand.ink,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _Brand.subtle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: _Brand.subtle),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _Brand.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _Brand.subtle),
          ),
        ),
      ],
    );
  }
}
