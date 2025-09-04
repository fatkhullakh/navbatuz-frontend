import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_owner_services_service.dart';
import 'service_edit_screen.dart';

class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const soft = Color(0xFFBDDDFC);
  static const card = Colors.white;
  static const bg = Color(0xFFF8F9FB);
  static const green = Color(0xFF2E7D32);
  static const greenBg = Color(0xFFE8F5E9);
  static const gray = Color(0xFF6B7280);
  static const grayBg = Color(0xFFF3F4F6);
}

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

  // optimistic toggle bookkeeping
  final Set<String> _busyIds = <String>{};
  final Map<String, bool> _activeOverride = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OwnerServiceItem>> _load() async {
    return _svc.getAllByProvider(widget.providerId);
  }

  Future<void> _refresh() async {
    final fut = _load();
    if (!mounted) return;
    setState(() {
      _future = fut; // sync only – no async in setState
    });
    await fut;
    if (!mounted) return;
    setState(() {
      _busyIds.clear();
      _activeOverride.clear();
    });
  }

  Future<void> _delete(BuildContext ctx, String id) async {
    final t = AppLocalizations.of(ctx)!;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(t.confirm_delete_title ?? 'Delete service?'),
        content: Text(t.confirm_delete_msg ?? 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(t.action_cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(t.action_delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _svc.delete(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.action_delete ?? 'Deleted')),
      );
      await _refresh();
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed $code: $body')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _setActive(String id, bool active) async {
    if (_busyIds.contains(id)) return;

    // optimistic, synchronous
    setState(() {
      _busyIds.add(id);
      _activeOverride[id] = active;
    });

    try {
      if (active) {
        await _svc.activate(id);
      } else {
        await _svc.deactivate(id);
      }
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyIds.remove(id);
        _activeOverride.remove(id); // rollback
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to ${active ? 'activate' : 'deactivate'}: $e')),
      );
    }
  }

  String _fmtDuration(Duration? d) {
    if (d == null) return '';
    final h = d.inHours, m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  /// Formats money as "123 000 so'm / сум / sum" depending on locale language.
  String _fmtMoney(num? v, BuildContext ctx) {
    if (v == null || v == 0) return '';
    final loc = Localizations.localeOf(ctx);
    final number = NumberFormat.decimalPattern(loc.toLanguageTag()).format(v);
    final suffix = _currencySuffixFor(loc, AppLocalizations.of(ctx)!);
    return '$number $suffix';
  }

  /// For now we only support UZS word by language.
  String _currencySuffixFor(Locale loc, AppLocalizations t) {
    final lang = (loc.languageCode).toLowerCase();
    switch (lang) {
      case 'uz':
        // Latin or Cyrillic – you can split later if needed
        return t.currency_sum ?? "so'm";
      case 'ru':
        return t.currency_sum ?? 'сум';
      default:
        return t.currency_sum ?? 'sum';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _Brand.bg,
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
      floatingActionButton: _FabPrimary(
        label: t.action_add ?? 'Add',
        onTap: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProviderServiceEditScreen(providerId: widget.providerId),
            ),
          );
          if (created == true) _refresh();
        },
      ),
      body: RefreshIndicator(
        color: _Brand.primary,
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

            final all = (snap.data ?? const <OwnerServiceItem>[]);
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

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: items.length + 2,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _SearchField(
                    hint: t.search_services_hint ?? 'Search services…',
                    onChanged: (v) => setState(() => _query = v),
                  );
                }
                if (i == 1) {
                  final countText = '${items.length} '
                      '${items.length == 1 ? (t.unit_service_singular ?? "service") : (t.unit_service_plural ?? "services")}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(t.filter_active_only ?? 'Active only'),
                          selected: _showOnlyActive,
                          onSelected: (v) =>
                              setState(() => _showOnlyActive = v),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: _Brand.primary.withOpacity(.22),
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(countText,
                            style: const TextStyle(color: _Brand.subtle)),
                      ],
                    ),
                  );
                }

                final s = items[i - 2];

                String? coverUrl() {
                  final raw = (s.imageUrl ?? s.logoUrl ?? '').trim();
                  if (raw.isEmpty) return null;
                  final n = ApiService.normalizeMediaUrl(raw);
                  final u = (n ?? raw).trim();
                  return u.isEmpty ? null : u;
                }

                final c = coverUrl();

                final rawActive = s.isActive == true;
                final isActive = _activeOverride.containsKey(s.id)
                    ? _activeOverride[s.id]!
                    : rawActive;

                final priceText = _fmtMoney(s.price, context);
                final busy = s.id != null && _busyIds.contains(s.id);

                return _ServiceCard(
                  title: s.name,
                  duration: _fmtDuration(s.duration),
                  price: priceText,
                  coverUrl: c,
                  isActive: isActive,
                  busy: busy,
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
                  onMenu: (v) {
                    if (v == 'edit') {
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
                    } else if (v == 'activate' && s.id != null) {
                      _setActive(s.id!, true);
                    } else if (v == 'deactivate' && s.id != null) {
                      _setActive(s.id!, false);
                    } else if (v == 'delete' && s.id != null) {
                      _delete(context, s.id!);
                    }
                  },
                  t: t,
                  onToggle: (v) {
                    if (s.id == null || busy) return;
                    _setActive(s.id!, v);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/* ---------- Widgets ---------- */

class _ServiceCard extends StatelessWidget {
  final String title;
  final String duration;
  final String price;
  final String? coverUrl;
  final bool isActive;
  final bool busy;
  final VoidCallback onTap;
  final void Function(String value) onMenu;
  final void Function(bool v) onToggle;
  final AppLocalizations t;

  const _ServiceCard({
    required this.title,
    required this.duration,
    required this.price,
    required this.coverUrl,
    required this.isActive,
    required this.busy,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _Brand.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Brand.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _Cover(coverUrl: coverUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _Brand.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          active: isActive,
                          labelActive: t.status_active ?? 'Active',
                          labelInactive: t.status_inactive ?? 'Inactive',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (duration.isNotEmpty)
                          _InfoPill(icon: Icons.schedule, text: duration),
                        if (price.isNotEmpty)
                          _InfoPill(
                              icon: Icons.attach_money_rounded, text: price),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                PopupMenuButton<String>(
                  tooltip: t.more ?? 'More',
                  onSelected: onMenu,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(t.action_edit ?? 'Edit'),
                      ),
                    ),
                    if (!isActive)
                      PopupMenuItem(
                        value: 'activate',
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.play_arrow_rounded),
                          title: Text(t.action_activate ?? 'Activate'),
                        ),
                      ),
                    if (isActive)
                      PopupMenuItem(
                        value: 'deactivate',
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.pause_rounded),
                          title: Text(t.action_deactivate ?? 'Deactivate'),
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        title: Text(t.action_delete ?? 'Delete'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: isActive,
                    onChanged: busy ? null : onToggle,
                    activeColor: _Brand.card,
                    activeTrackColor: _Brand.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? coverUrl;
  const _Cover({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: _Brand.soft.withOpacity(.35),
        child: (coverUrl == null || coverUrl!.isEmpty)
            ? const Icon(Icons.design_services_outlined, color: _Brand.subtle)
            : Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: _Brand.subtle,
                ),
              ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Brand.soft.withOpacity(.40),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _Brand.soft.withOpacity(.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _Brand.ink.withOpacity(.9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _Brand.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  final String labelActive;
  final String labelInactive;
  const _StatusChip({
    required this.active,
    required this.labelActive,
    required this.labelInactive,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? _Brand.greenBg : _Brand.grayBg;
    final fg = active ? _Brand.green : _Brand.gray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.25)),
      ),
      child: Text(
        active ? labelActive : labelInactive,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
        prefixIcon: const Icon(Icons.search_rounded, color: _Brand.subtle),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Brand.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Brand.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _FabPrimary extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FabPrimary({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: _Brand.soft.withOpacity(.9),
      foregroundColor: _Brand.ink,
      icon: const Icon(Icons.add),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;
  final Future<void> Function() onRetry;
  final AppLocalizations t;
  const _ErrorBox({required this.text, required this.onRetry, required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Brand.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Brand.border),
        ),
        child: Column(
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: Text(t.action_retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
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
            borderRadius: BorderRadius.circular(14),
          ),
        );
    return ListView(children: [box(52), box(90), box(90), box(90), box(90)]);
  }
}
