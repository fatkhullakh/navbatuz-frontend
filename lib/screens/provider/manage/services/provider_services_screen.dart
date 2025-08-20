import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_owner_services_service.dart';
import 'service_edit_screen.dart';

class ProviderServicesScreen extends StatefulWidget {
  final String providerId;
  const ProviderServicesScreen({super.key, required this.providerId});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  final _svc = ProviderOwnerServicesService();
  late Future<List<OwnerServiceItem>> _future;
  String _query = '';
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OwnerServiceItem>> _load() async {
    // returns ALL non-deleted + deleted; we'll filter deleted on UI
    return _svc.getAllByProvider(widget.providerId);
  }

  Future<void> _refresh() async {
    final fut = _load(); // start async work OUTSIDE setState
    if (!mounted) return;
    setState(() {
      _future = fut; // setState is sync
    });
    await fut;
    if (!mounted) return;
  }

  Future<void> _deleteFromList(BuildContext pageCtx, String id) async {
    final ok = await showDialog<bool>(
      context: pageCtx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppLocalizations.of(dialogCtx)!.confirm_delete_title ??
            'Delete service?'),
        content: Text(AppLocalizations.of(dialogCtx)!.confirm_delete_msg ??
            'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child:
                Text(AppLocalizations.of(dialogCtx)!.action_cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child:
                Text(AppLocalizations.of(dialogCtx)!.action_delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _svc.delete(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.deleted ?? 'Deleted')),
      );
      await _refresh();
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed $code: $body')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _setActive(String id, bool active) async {
    try {
      if (active) {
        await _svc.activate(id);
      } else {
        await _svc.deactivate(id);
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
    final label = isActive ? 'Active' : 'Inactive';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
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
              builder: (_) => ProviderServiceEditScreen(
                providerId: widget.providerId,
              ),
            ),
          );
          if (created == true) _refresh();
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

            final all = snap.data ?? const <OwnerServiceItem>[];

            // show both active & inactive, but hide deleted (soft-deleted)
            final visible = all.where((s) => s.deleted != true).toList();
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
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Active only'),
                          selected: _showOnlyActive,
                          onSelected: (v) =>
                              setState(() => _showOnlyActive = v),
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
              itemCount: items.length + 2, // + search/header controls
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _SearchField(
                    hint: t.search_services_hint ?? 'Search services…',
                    onChanged: (v) => setState(() => _query = v),
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
                          onSelected: (v) =>
                              setState(() => _showOnlyActive = v),
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

                String? cover() {
                  final raw = (s.imageUrl ?? s.logoUrl ?? '').trim();
                  if (raw.isEmpty) return null;
                  final n = ApiService.normalizeMediaUrl(raw);
                  final u = (n ?? raw).trim();
                  return u.isEmpty ? null : u;
                }

                final c = cover();
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
                          builder: (_) => ProviderServiceEditScreen(
                            providerId: widget.providerId,
                            serviceId: s.id,
                          ),
                        ),
                      );
                      if (changed == true) _refresh();
                    },
                    leading: SizedBox(
                      width: 44,
                      height: 44,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (c == null)
                            ? Container(
                                color: const Color(0xFFF2F4F7),
                                child:
                                    const Icon(Icons.design_services_outlined),
                              )
                            : Image.network(
                                c,
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
                        if (v == 'delete') {
                          final id = s.id;
                          if (id == null || id.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Missing service id')),
                            );
                            return;
                          }
                          await _deleteFromList(context, id);
                        } else if (v == 'edit') {
                          Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderServiceEditScreen(
                                providerId: widget.providerId,
                                serviceId: s.id,
                              ),
                            ),
                          ).then((changed) {
                            if (changed == true) _refresh();
                          });
                        } else if (v == 'activate') {
                          if (s.id != null) _setActive(s.id!, true);
                        } else if (v == 'deactivate') {
                          if (s.id != null) _setActive(s.id!, false);
                        }
                      },
                      itemBuilder: (_) {
                        final items = <PopupMenuEntry<String>>[
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
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading:
                                  Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Delete'),
                            ),
                          ),
                        ];
                        return items;
                      },
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
