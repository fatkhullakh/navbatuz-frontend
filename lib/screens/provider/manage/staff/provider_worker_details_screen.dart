// lib/screens/provider/manage/staff/provider_worker_details_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_staff_service.dart';

import 'provider_worker_services_screen.dart';
import 'provider_worker_availability_screen.dart';

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
  final Dio _dio = ApiService.client;

  late bool _active;
  String? _phone;
  String? _email;
  String? _avatar;
  String? _role;

  bool _toggling = false;
  bool _loadingUser = false;

  @override
  void initState() {
    super.initState();
    _active = widget.member.isActive;
    _phone = widget.member.phoneNumber;
    _email = widget.member.email;
    _avatar = widget.member.avatarUrl;
    _role = widget.member.role;
    _fetchUserIfMissing();
  }

  Future<void> _fetchUserIfMissing() async {
    final needPhone = _phone == null || _phone!.trim().isEmpty;
    final needEmail = _email == null || _email!.trim().isEmpty;
    final needAvatar = _avatar == null || _avatar!.trim().isEmpty;
    if (!needPhone && !needEmail && !needAvatar) return;

    setState(() => _loadingUser = true);
    try {
      final r = await _dio.get('/users/${widget.member.userId}');
      final m = (r.data as Map).cast<String, dynamic>();
      setState(() {
        _phone = (m['phoneNumber'] ?? _phone ?? '').toString();
        _email = (m['email'] ?? _email ?? '').toString();
        _avatar = (m['avatarUrl'] ?? _avatar ?? '').toString();
      });
    } catch (_) {
      // ignore – UI will just show blanks
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _toggleActive() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      if (_active) {
        await _dio.put('/workers/${widget.member.id}/deactivate');
      } else {
        await _dio.put('/workers/${widget.member.id}/activate');
      }
      if (!mounted) return;
      setState(() => _active = !_active);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _active
                ? (AppLocalizations.of(context)!.activate ?? 'Activated')
                : (AppLocalizations.of(context)!.deactivate ?? 'Deactivated'),
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('HTTP $code: $body')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final displayName =
        (widget.member.name == null || widget.member.name!.trim().isEmpty)
            ? (t.staff_title ?? 'Staff')
            : widget.member.name!;
    final avatarUrl = (_avatar ?? '').trim();
    final normalizedAvatar = avatarUrl.isEmpty
        ? null
        : (ApiService.normalizeMediaUrl(avatarUrl) ?? avatarUrl);

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFF2F4F7),
                backgroundImage: normalizedAvatar == null
                    ? null
                    : NetworkImage(normalizedAvatar),
                child: normalizedAvatar == null
                    ? const Icon(Icons.person_outline, size: 36)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(active: _active),
                        OutlinedButton.icon(
                          icon: Icon(
                            _active
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                          ),
                          onPressed: _toggling ? null : _toggleActive,
                          label: Text(
                            _active
                                ? (t.deactivate ?? 'Deactivate')
                                : (t.activate ?? 'Activate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Role
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text((_role ?? '').isEmpty ? '—' : _role!),
              subtitle: const Text('Role'),
            ),
          ),

          // Phone
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.call_outlined),
              title: Text((_phone ?? '').isEmpty ? '—' : _phone!),
              subtitle: Text(t.phone ?? 'Phone'),
              trailing: _loadingUser
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),

          // Email
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.alternate_email_outlined),
              title: Text((_email ?? '').isEmpty ? '—' : _email!),
              subtitle: Text(t.email ?? 'Email'),
              trailing: _loadingUser
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 48,
            child: FilledButton.icon(
              icon: const Icon(Icons.design_services_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderWorkerServicesScreen(
                      providerId: widget.providerId,
                      workerId: widget.member.id,
                      workerName: widget.member.name ?? '—',
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
            child: OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderWorkerAvailabilityScreen(
                      workerId: widget.member.id,
                      workerName: widget.member.name ?? '—',
                    ),
                  ),
                );
              },
              label: Text(t.edit_availability ?? 'Edit availability'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final label = active ? (t.active ?? 'Active') : (t.closed ?? 'Inactive');
    final color = active ? const Color(0xFF12B76A) : const Color(0xFF667085);
    final bg = active ? const Color(0xFFEFFDF6) : const Color(0xFFF2F4F7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle : Icons.pause_circle_filled,
              size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
