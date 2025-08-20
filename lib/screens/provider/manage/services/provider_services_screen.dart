import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/provider_service.dart';
import '../../../../services/provider_services_service.dart';
import '../../../../services/api_service.dart';
import '../../../providers/provider_screen.dart'; // optional if you want to jump to public view
import 'service_edit_screen.dart';

class ProviderServicesScreen extends StatefulWidget {
  final String providerId;
  const ProviderServicesScreen({super.key, required this.providerId});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  final _svc = ProviderServicesService();
  late Future<List<ProviderService>> _future;

  String _query = '';
  bool _showInactive = true;

  @override
  void initState() {
    super.initState();
    _future = _svc.listByProvider(widget.providerId);
  }

  Future<void> _reload() async {
    setState(() => _future = _svc.listByProvider(widget.providerId));
    await _future;
  }

  String _durText(Duration? d) {
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final priceFmt = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_tx(t, 'manage_services_title', 'Services')),
        actions: [
          IconButton(
            tooltip: _tx(t, 'action_refresh', 'Refresh'),
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceEditScreen(
                providerId: widget.providerId,
              ),
            ),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: Text(_tx(t, 'action_add_service', 'Add service')),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<ProviderService>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('Failed: ${snap.error}')),
                  const SizedBox(height: 8),
                  Center(
                    child: OutlinedButton(
                      onPressed: _reload,
                      child: Text(t.provider_retry),
                    ),
                  ),
                ],
              );
            }
            var items = snap.data ?? const <ProviderService>[];

            // simple filters
            if (!_showInactive) {
              items = items.where((s) => s.isActive).toList();
            }
            if (_query.trim().isNotEmpty) {
              final q = _query.trim().toLowerCase();
              items = items
                  .where((s) =>
                      s.name.toLowerCase().contains(q) ||
                      (s.description ?? '').toLowerCase().contains(q))
                  .toList();
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                // search + filters
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: _tx(t, 'search_hint', 'Search services'),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _showInactive,
                              onChanged: (v) => setState(
                                  () => _showInactive = v ?? _showInactive),
                            ),
                            Text(_tx(
                                t, 'filter_show_inactive', 'Show inactive')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(_tx(
                          t, 'empty_services', 'No services yet. Add one!')),
                    ),
                  ),

                for (final s in items) ...[
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: _ServiceThumb(url: s.logoUrl),
                      title: Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if ((s.category).isNotEmpty)
                                Chip(
                                  label: Text(s.category),
                                  avatar: const Icon(Icons.category, size: 14),
                                ),
                              if (s.duration != null)
                                Chip(
                                  label: Text(_durText(s.duration)),
                                  avatar: const Icon(Icons.schedule_outlined,
                                      size: 14),
                                ),
                              Chip(
                                label: Text(s.isActive
                                    ? _tx(t, 'active', 'Active')
                                    : _tx(t, 'inactive', 'Inactive')),
                                avatar: Icon(
                                  s.isActive ? Icons.check : Icons.pause,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                          if (s.price != null)
                            Text(priceFmt.format(s.price),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceEditScreen(
                                  providerId: widget.providerId,
                                  existing: s,
                                ),
                              ),
                            );
                            if (changed == true) _reload();
                          } else if (v == 'toggle') {
                            try {
                              if (s.isActive) {
                                await _svc.deactivate(s.id);
                              } else {
                                await _svc.activate(s.id);
                              }
                              _reload();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          } else if (v == 'delete') {
                            final ok = await _confirmDelete(context, t);
                            if (ok == true) {
                              try {
                                await _svc.delete(s.id);
                                _reload();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            }
                          } else if (v == 'image') {
                            final url =
                                await _askImageUrl(context, t, s.logoUrl);
                            if (url != null && url.trim().isNotEmpty) {
                              try {
                                await _svc.setImage(s.id, url.trim());
                                _reload();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: const Icon(Icons.edit),
                              title: Text(_tx(t, 'action_edit', 'Edit')),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: ListTile(
                              leading: Icon(
                                  s.isActive ? Icons.pause : Icons.play_arrow),
                              title: Text(s.isActive
                                  ? _tx(t, 'action_deactivate', 'Deactivate')
                                  : _tx(t, 'action_activate', 'Activate')),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'image',
                            child: ListTile(
                              leading: const Icon(Icons.image_outlined),
                              title: Text(_tx(t, 'action_change_image',
                                  'Change image URL')),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              title: Text(
                                _tx(t, 'action_delete', 'Delete'),
                                style: const TextStyle(color: Colors.red),
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceEditScreen(
                              providerId: widget.providerId,
                              existing: s,
                            ),
                          ),
                        );
                        if (changed == true) _reload();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, AppLocalizations t) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_tx(t, 'confirm', 'Are you sure?')),
        content: Text(_tx(t, 'confirm_delete_service',
            'This will permanently delete the service.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_tx(t, 'common_no', 'No')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_tx(t, 'common_yes', 'Yes')),
          ),
        ],
      ),
    );
  }

  Future<String?> _askImageUrl(
      BuildContext context, AppLocalizations t, String? initial) {
    final ctl = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_tx(t, 'change_image', 'Change image URL')),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tx(t, 'action_cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctl.text),
            child: Text(_tx(t, 'action_save', 'Save')),
          ),
        ],
      ),
    );
  }

  String _tx(AppLocalizations t, String _key, String fallback) => fallback;
}

class _ServiceThumb extends StatelessWidget {
  final String? url;
  const _ServiceThumb({this.url});
  @override
  Widget build(BuildContext context) {
    final image = (url != null) ? NetworkImage(url!) : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: const Color(0xFFF2F4F7),
        width: 56,
        height: 56,
        child: image == null
            ? const Icon(Icons.medical_services_outlined)
            : Image(image: image, fit: BoxFit.cover),
      ),
    );
  }
}
