import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_owner_services_service.dart';
import '../../../../services/workers/worker_services_service.dart';
import 'worker_service_edit_screen.dart';

class WorkerServicesScreen extends StatefulWidget {
  final String workerId;
  final String providerId; // required for “Create”
  const WorkerServicesScreen({
    super.key,
    required this.workerId,
    required this.providerId,
  });

  @override
  State<WorkerServicesScreen> createState() => _WorkerServicesScreenState();
}

class _WorkerServicesScreenState extends State<WorkerServicesScreen> {
  // Owner service client reused for activate/deactivate (API is shared)
  final _svcOwner = ProviderOwnerServicesService();
  // Worker-scoped fetcher
  final _svcWorker = WorkerServicesService();

  late Future<List<OwnerServiceItem>> _future;
  String _query = '';
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OwnerServiceItem>> _load() async {
    // Server now excludes deleted for worker, but filter on UI too for safety
    final all = await _svcWorker.getAllByWorker(widget.workerId);
    return all.where((s) => s.deleted != true).toList();
  }

  Future<void> _refresh() async {
    final fut = _load(); // start async work
    if (!mounted) return;
    setState(() {
      _future = fut;
    }); // <-- block body so setState returns void
    await fut; // await outside of setState
    if (!mounted) return;
  }

  Future<void> _setActive(String id, bool active) async {
    try {
      if (active) {
        await _svcOwner.activate(id);
      } else {
        await _svcOwner.deactivate(id);
      }
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to ${active ? 'activate' : 'deactivate'}: $e')),
      );
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final h = d.inHours, m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Widget _statusChip(bool isActive) {
    final bg = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6);
    final fg = isActive ? const Color(0xFF2E7D32) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(isActive ? 'Active' : 'Inactive',
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final money =
        NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.services_title ?? 'Services'),
        actions: [
          IconButton(
            tooltip: t.action_refresh ?? 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerServiceEditScreen(
                providerId: widget.providerId, // NOTE: provider id (not worker)
                workerId: widget.workerId,
              ),
            ),
          );
          if (created == true && mounted) _refresh();
        },
        icon: const Icon(Icons.add),
        label: Text(t.action_add ?? 'Add'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<OwnerServiceItem>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _Skeleton();
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  _ErrorBox(
                    text: 'Failed: ${snap.error}',
                    onRetry: _refresh,
                    t: t,
                  ),
                ],
              );
            }

            final visible = (snap.data ?? const <OwnerServiceItem>[])
                .where((s) => s.deleted != true)
                .toList();

            final base = _showOnlyActive
                ? visible.where((s) => s.isActive == true).toList()
                : visible;

            final items = (_query.trim().isEmpty)
                ? base
                : base
                    .where((s) =>
                        s.name.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

            if (visible.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 20),
                  _SearchField(
                    hint: t.search_services_hint ?? 'Search services…',
                    onChanged: (v) => setState(() {
                      _query = v;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Active only'),
                          selected: _showOnlyActive,
                          onSelected: (v) => setState(() {
                            _showOnlyActive = v;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: Text(t.no_data ?? 'No services yet')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
              itemCount: items.length + 2,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _SearchField(
                    hint: t.search_services_hint ?? 'Search services…',
                    onChanged: (v) => setState(() {
                      _query = v;
                    }),
                  );
                }
                if (i == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Active only'),
                          selected: _showOnlyActive,
                          onSelected: (v) => setState(() {
                            _showOnlyActive = v;
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${items.length} ${items.length == 1 ? 'service' : 'services'}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                final s = items[i - 2];
                final raw = (s.imageUrl ?? s.logoUrl ?? '').trim();
                final cover = raw.isEmpty
                    ? null
                    : (ApiService.normalizeMediaUrl(raw) ?? raw);
                final isActive = s.isActive == true;
                final priceText = (s.price == null || s.price == 0)
                    ? ''
                    : money.format(s.price);

                return Card(
                  elevation: 0,
                  child: ListTile(
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkerServiceEditScreen(
                            providerId: widget.providerId,
                            workerId: widget.workerId,
                            serviceId: s.id,
                          ),
                        ),
                      );
                      if (changed == true && mounted) _refresh();
                    },
                    leading: SizedBox(
                      width: 44,
                      height: 44,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (cover == null)
                            ? Container(
                                color: const Color(0xFFF2F4F7),
                                child:
                                    const Icon(Icons.design_services_outlined),
                              )
                            : Image.network(
                                cover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF2F4F7),
                                  child:
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isActive ? null : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(isActive),
                      ],
                    ),
                    subtitle: Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (s.duration != null)
                          Text(_formatDuration(s.duration),
                              style: const TextStyle(color: Colors.black54)),
                        if (priceText.isNotEmpty)
                          Text(priceText,
                              style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkerServiceEditScreen(
                                providerId: widget.providerId,
                                workerId: widget.workerId,
                                serviceId: s.id,
                              ),
                            ),
                          );
                          if (changed == true && mounted) _refresh();
                        } else if (v == 'activate') {
                          if (s.id != null) await _setActive(s.id!, true);
                        } else if (v == 'deactivate') {
                          if (s.id != null) await _setActive(s.id!, false);
                        }
                        // NOTE: delete hidden for workers (403 on backend)
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        if (!isActive)
                          const PopupMenuItem(
                            value: 'activate',
                            child: ListTile(
                              leading: Icon(Icons.play_arrow_rounded),
                              title: Text('Activate'),
                            ),
                          ),
                        if (isActive)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: ListTile(
                              leading: Icon(Icons.pause_rounded),
                              title: Text('Deactivate'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A89A7), width: 1.5),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;
  final Future<void> Function() onRetry;
  final AppLocalizations t;
  const _ErrorBox({required this.text, required this.onRetry, required this.t});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          children: [
            Text(text),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: () => onRetry(),
                child: Text(t.action_retry ?? 'Retry')),
          ],
        ),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(12),
          ),
        );
    return ListView(children: [box(48), box(80), box(80), box(80), box(80)]);
  }
}
