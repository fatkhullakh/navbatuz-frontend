import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';
import 'provider_worker_details_screen.dart';
import 'provider_worker_invite_screen.dart';

class ProviderStaffListScreen extends StatefulWidget {
  final String providerId;
  const ProviderStaffListScreen({super.key, required this.providerId});

  @override
  State<ProviderStaffListScreen> createState() =>
      _ProviderStaffListScreenState();
}

class _ProviderStaffListScreenState extends State<ProviderStaffListScreen> {
  final ProviderStaffService _service = ProviderStaffService();
  final Dio _dio = ApiService.client;

  bool _loading = true;
  List<StaffMember> _items = const [];
  String _q = '';
  bool _onlyAvailable = false; // <-- new

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getProviderStaff(widget.providerId);
      setState(() => _items = list);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final txt = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('HTTP $code: $txt')),
      );
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final filtered = _items.where((m) {
      // never show inactive for owners
      if (!m.isActive) return false;

      // search
      if (_q.isNotEmpty) {
        final s =
            '${m.displayName} ${m.role ?? ''} ${m.email ?? ''} ${m.phoneNumber ?? ''}'
                .toLowerCase();
        if (!s.contains(_q.toLowerCase())) return false;
      }

      // “Only available”
      if (_onlyAvailable && m.status != WorkerStatus.AVAILABLE) return false;

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(t.staff_title ?? 'Staff')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: t.staff_search_hint ?? 'Search name or phone…',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (s) => setState(() => _q = s),
            ),
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.staff_only_available ??
                'Show only available'),
            value: _onlyAvailable,
            onChanged: (v) => setState(() => _onlyAvailable = v),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final m = filtered[i];
                        final avatar = (m.avatarUrl ?? '').trim();
                        final normalized = avatar.isEmpty
                            ? null
                            : (ApiService.normalizeMediaUrl(avatar) ?? avatar);

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
                              color: _statusColor(m.status).withOpacity(.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusText(m.status),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _statusColor(m.status),
                              ),
                            ),
                          ),
                          onTap: () async {
                            final changed = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProviderWorkerDetailsScreen(
                                  providerId: widget.providerId,
                                  member: m,
                                ),
                              ),
                            );
                            if (changed == true) _load();
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(t.staff_add_member ?? 'Add staff'),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProviderWorkerInviteScreen(providerId: widget.providerId),
            ),
          );
          if (created == true) _load(); // refresh list after successful invite
        },
      ),
    );
  }
}
