// lib/screens/provider/manage/staff/provider_worker_services_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';

class ProviderWorkerServicesScreen extends StatefulWidget {
  final String providerId;
  final String workerId;
  final String workerName;
  const ProviderWorkerServicesScreen({
    super.key,
    required this.providerId,
    required this.workerId,
    required this.workerName,
  });

  @override
  State<ProviderWorkerServicesScreen> createState() =>
      _ProviderWorkerServicesScreenState();
}

class _ProviderWorkerServicesScreenState
    extends State<ProviderWorkerServicesScreen> {
  final _dio = ApiService.client;

  bool _loading = true;
  bool _saving = false;

  List<_Svc> _all = [];
  late Set<String> _assigned;

  // UI filters
  String _q = '';
  bool _onlyActive = false;
  bool _onlyAssigned = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rAll =
          await _dio.get('/services/provider/all/${widget.providerId}');
      final listAll = (rAll.data as List?) ?? [];

      final rMine = await _dio.get('/services/worker/all/${widget.workerId}');
      final listMine = (rMine.data as List?) ?? [];

      _all = listAll.whereType<Map>().map((m) {
        final mm = m.cast<String, dynamic>();
        return _Svc(
          id: (mm['id'] ?? '').toString(),
          name: (mm['name'] ?? '').toString(),
          isActive: mm['isActive'] == true,
        );
      }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _assigned = listMine
          .whereType<Map>()
          .map((m) => (m['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_Svc> get _filtered {
    return _all.where((s) {
      if (_onlyActive && !s.isActive) return false;
      if (_onlyAssigned && !_assigned.contains(s.id)) return false;
      if (_q.isNotEmpty &&
          !s.name.toLowerCase().contains(_q.trim().toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _toggle(String serviceId, bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    final t = AppLocalizations.of(context)!;
    try {
      if (value) {
        await _dio.put('/services/$serviceId/add-worker/${widget.workerId}');
        _assigned.add(serviceId);
      } else {
        await _dio.put('/services/$serviceId/remove-worker/${widget.workerId}');
        _assigned.remove(serviceId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(value ? (t.added ?? 'Added') : (t.removed ?? 'Removed')),
        ),
      );
      setState(() {});
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed ($code): $body')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- bulk actions over "visible" (filtered) items ----
  Future<void> _bulkAssignVisible(bool assign) async {
    if (_saving) return;
    setState(() => _saving = true);
    final t = AppLocalizations.of(context)!;

    final visible = _filtered;
    int changed = 0;

    try {
      for (final s in visible) {
        final already = _assigned.contains(s.id);
        if (assign && !already) {
          await _dio.put('/services/${s.id}/add-worker/${widget.workerId}');
          _assigned.add(s.id);
          changed++;
        } else if (!assign && already) {
          await _dio.put('/services/${s.id}/remove-worker/${widget.workerId}');
          _assigned.remove(s.id);
          changed++;
        }
      }
      if (!mounted) return;
      final msg =
          assign ? t.added_n_services(changed) : t.removed_n_services(changed);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() {});
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed ($code): $body')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${t.services_title ?? 'Services'} – ${widget.workerName}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: t.action_refresh ?? 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Search
                  TextField(
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: t.search_services_hint ?? 'Search services…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _q.isEmpty
                          ? const Icon(Icons.tune, color: Color(0xFF7C8B9B))
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _q = ''),
                            ),
                    ),
                    onChanged: (s) => setState(() => _q = s),
                  ),
                  const SizedBox(height: 10),

                  // Filter chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChipBool(
                        label: t.only_active ?? 'Only active',
                        value: _onlyActive,
                        onChanged: (v) => setState(() => _onlyActive = v),
                      ),
                      _ChipBool(
                        label: t.only_assigned ?? 'Only assigned',
                        value: _onlyAssigned,
                        onChanged: (v) => setState(() => _onlyAssigned = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Bulk actions + selected count (single-line, no vertical wrap)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.selected_n(_assigned.length),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed:
                            _saving ? null : () => _bulkAssignVisible(false),
                        icon: const Icon(Icons.remove_done),
                        label: Text(t.remove_visible ?? 'Remove visible'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed:
                            _saving ? null : () => _bulkAssignVisible(true),
                        icon: const Icon(Icons.playlist_add_check_rounded),
                        label: Text(t.assign_visible ?? 'Assign visible'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (items.isEmpty)
                    _Empty(
                      title: t.no_services_found ?? 'No services',
                      caption: t.no_services_found_caption ??
                          'Try adjusting filters or search.',
                    )
                  else
                    ...List.generate(items.length, (i) {
                      final s = items[i];
                      final checked = _assigned.contains(s.id);
                      return _ServiceTile(
                        title: s.name,
                        inactiveLabel: t.service_inactive ?? 'Inactive service',
                        isActive: s.isActive,
                        checked: checked,
                        onChanged: (v) => _toggle(s.id, v),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

/* ---------- UI bits ---------- */

class _ServiceTile extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool checked;
  final String inactiveLabel;
  final ValueChanged<bool> onChanged;
  const _ServiceTile({
    required this.title,
    required this.isActive,
    required this.checked,
    required this.inactiveLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE6ECF2)),
      ),
      child: CheckboxListTile(
        value: checked,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.trailing,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isActive ? const Color(0xFF384959) : Colors.black54,
          ),
        ),
        subtitle: isActive
            ? null
            : Text(
                inactiveLabel,
                style: const TextStyle(color: Color(0xFF7C8B9B)),
              ),
      ),
    );
  }
}

class _ChipBool extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ChipBool({
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
      selectedColor: const Color(0xFF6A89A7).withOpacity(.12),
      shape: const StadiumBorder(
        side: BorderSide(color: Color(0xFFE6ECF2)),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: value ? const Color(0xFF6A89A7) : const Color(0xFF7C8B9B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: value ? const Color(0xFF6A89A7) : const Color(0xFF384959),
            ),
          ),
        ],
      ),
      onSelected: (v) => onChanged(!value ? true : false),
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String caption;
  const _Empty({required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.design_services_outlined,
              size: 56, color: Color(0xFF7C8B9B)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF384959),
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
              style: const TextStyle(color: Color(0xFF7C8B9B)),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- Model ---------- */

class _Svc {
  final String id;
  final String name;
  final bool isActive;
  _Svc({required this.id, required this.name, required this.isActive});
}
