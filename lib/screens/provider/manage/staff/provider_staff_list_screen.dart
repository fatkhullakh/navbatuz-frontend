import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';
import 'provider_worker_details_screen.dart';

class ProviderStaffScreen extends StatefulWidget {
  final String providerId;
  const ProviderStaffScreen({super.key, required this.providerId});

  @override
  State<ProviderStaffScreen> createState() => _ProviderStaffScreenState();
}

class _ProviderStaffScreenState extends State<ProviderStaffScreen> {
  final _svc = ProviderStaffService();
  late Future<List<StaffMember>> _future;
  String _query = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<StaffMember>> _load() async => _svc.list(widget.providerId);

  Future<void> _refresh() async {
    final fut = _load();
    if (!mounted) return;
    setState(() => _future = fut);
    await fut;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.staff_title ?? 'Staff'),
        actions: [
          IconButton(
            tooltip: t.action_refresh ?? 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteBottomSheet(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(t.staff_add_member ?? 'Add staff'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<StaffMember>>(
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
                    text:
                        '${t.error_generic ?? 'Something went wrong.'}\n${snap.error}',
                    onRetry: _refresh,
                    t: t,
                  ),
                ],
              );
            }

            final all = (snap.data ?? const <StaffMember>[]);
            final filtered = all.where((m) {
              if (!_showInactive && !m.isActive) return false;
              if (_query.trim().isEmpty) return true;
              final q = _query.toLowerCase();
              final name = (m.name ?? '').toLowerCase();
              final phone = (m.phoneNumber ?? '').toLowerCase();
              final email = (m.email ?? '').toLowerCase();
              return name.contains(q) || phone.contains(q) || email.contains(q);
            }).toList();

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
              itemCount: filtered.length + 2,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _SearchField(
                    hint: t.staff_search_hint ?? 'Search name or phone…',
                    onChanged: (v) => setState(() => _query = v),
                  );
                }
                if (i == 1) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.staff_show_inactive ?? 'Show inactive',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: _showInactive,
                        onChanged: (v) => setState(() => _showInactive = v),
                      ),
                    ],
                  );
                }

                final m = filtered[i - 2];
                final avatarUrl = (m.avatarUrl ?? '').trim();
                final sub = [
                  if ((m.role ?? '').isNotEmpty) m.role!,
                  if ((m.phoneNumber ?? '').isNotEmpty) m.phoneNumber!,
                  if ((m.email ?? '').isNotEmpty) m.email!,
                ].join(' • ');

                return Card(
                  elevation: 0,
                  child: ListTile(
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderWorkerDetailsScreen(
                            providerId: widget.providerId,
                            member: m,
                          ),
                        ),
                      );
                      if (changed == true) _refresh();
                    },
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFF2F4F7),
                      backgroundImage: avatarUrl.isEmpty
                          ? null
                          : NetworkImage(
                              ApiService.normalizeMediaUrl(avatarUrl) ??
                                  avatarUrl),
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person_outline,
                              color: Colors.black45)
                          : null,
                    ),
                    title: Text(
                      (m.name?.isNotEmpty ?? false) ? m.name! : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      sub.isEmpty ? ' ' : sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _StatusChip(active: m.isActive),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showInviteBottomSheet(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final key = GlobalKey<FormState>();
    final userIdCtrl = TextEditingController();
    final workerTypeCtrl = TextEditingController(text: 'WORKER');
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setS) {
              return Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.staff_invite_title ?? 'Invite staff',
                        style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: userIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'User ID (UUID)',
                        hintText: 'e.g. 413eb3…',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (t.required ?? 'Required')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: workerTypeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Worker type',
                        hintText: 'e.g. BARBER',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (t.required ?? 'Required')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!key.currentState!.validate()) return;
                                setS(() => saving = true);
                                try {
                                  final req = CreateWorkerReq(
                                    user: userIdCtrl.text.trim(),
                                    provider: widget.providerId,
                                    workerType: workerTypeCtrl.text.trim(),
                                  );
                                  await _svc.invite(req);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(t.invite ?? 'Invite')),
                                  );
                                  Navigator.pop(ctx);
                                  await _refresh();
                                } on DioException catch (e) {
                                  if (!mounted) return;
                                  final code = e.response?.statusCode;
                                  final body = e.response?.data;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Failed ($code): $body')),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                } finally {
                                  setS(() => saving = false);
                                }
                              },
                        child: Text(t.invite ?? 'Invite'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------- UI bits ----------

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});
  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFE9F7EF) : const Color(0xFFFDECEC);
    final fg = active ? const Color(0xFF1E7D3B) : const Color(0xFFB42318);
    final label = active ? 'Active' : 'Inactive';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style:
              TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
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
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: Text(t.action_retry ?? 'Retry'),
            ),
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
