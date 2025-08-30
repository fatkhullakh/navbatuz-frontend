import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/screens/provider/manage/staff/provider_worker_availability_screen.dart';
import 'package:frontend/screens/provider/manage/staff/provider_worker_services_screen.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';

// Existing manage screens
import 'services/provider_services_screen.dart';
import 'staff/provider_staff_list_screen.dart';
import 'hours/provider_business_hours_screen.dart';
import '../manage/business_info/provider_settings_screen.dart';

// Optional public worker view
// import '../../workers/worker_screen.dart';

/* ---------------------------- Brand constants ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
}

/* ------------------------------ Screen ---------------------------------- */
class ProviderManageScreen extends StatefulWidget {
  final String? providerId;
  const ProviderManageScreen({super.key, required this.providerId});

  @override
  State<ProviderManageScreen> createState() => _ProviderManageScreenState();
}

class _ProviderManageScreenState extends State<ProviderManageScreen> {
  final Dio _dio = ApiService.client;

  // owner-as-worker state
  bool _checkingMe = true;
  String? _meWorkerId;
  String? _meName;
  String? _meAvatarUrl;
  String? _meStatus; // AVAILABLE / UNAVAILABLE / ...
  double? _meAvgRating;
  bool _meActive = false; // ← NEW: track active flag

  // enable form
  String _workerType = 'GENERAL';
  String _status = 'AVAILABLE';
  bool _busyEnable = false;
  bool _busyReactivate = false; // ← NEW

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() {
      _checkingMe = true;
    });
    try {
      final r = await _dio.get('/workers/me'); // 403/404 if not a worker yet
      if (r.data is Map) {
        final m = Map<String, dynamic>.from(r.data as Map);
        setState(() {
          _meWorkerId = (m['id'] ?? '').toString();
          _meName = (m['name'] ?? '').toString();
          _meStatus = m['status']?.toString();
          _meAvgRating = (m['avgRating'] is num)
              ? (m['avgRating'] as num).toDouble()
              : double.tryParse('${m['avgRating']}');
          final rawAvatar = (m['avatarUrl'] ?? '').toString();
          _meAvatarUrl = ApiService.normalizeMediaUrl(rawAvatar) ?? rawAvatar;

          // tolerate both "active" and "isActive"
          final dynamic act = (m['active'] ?? m['isActive']);
          _meActive = act == true || act?.toString() == 'true';
        });
      } else {
        setState(() {
          _meWorkerId = null;
          _meActive = false;
        });
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 403 || code == 404) {
        setState(() {
          _meWorkerId = null;
          _meActive = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to check worker profile: ${e.message}')),
          );
        }
        setState(() {
          _meWorkerId = null;
          _meActive = false;
        });
      }
    } finally {
      if (mounted) setState(() => _checkingMe = false);
    }
  }

  void _needProvider(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(ctx)!.error_generic ?? 'Provider is not selected',
        ),
      ),
    );
  }

  Future<void> _enableOwnerAsWorker() async {
    if (widget.providerId == null) {
      _needProvider(context);
      return;
    }
    setState(() => _busyEnable = true);
    try {
      final body = {
        'workerType': _workerType,
        'status': _status,
        'isActive': true, // ensure active on create/enable
      };
      final r = await _dio.post(
        '/providers/${widget.providerId}/owner-as-worker',
        data: body,
      );

      if (r.data is Map) {
        final m = Map<String, dynamic>.from(r.data as Map);
        setState(() {
          _meWorkerId = (m['id'] ?? '').toString();
          _meName = (m['name'] ?? '').toString();
          _meStatus = m['status']?.toString();
          _meAvgRating = (m['avgRating'] is num)
              ? (m['avgRating'] as num).toDouble()
              : double.tryParse('${m['avgRating']}');
          final rawAvatar = (m['avatarUrl'] ?? '').toString();
          _meAvatarUrl = ApiService.normalizeMediaUrl(rawAvatar) ?? rawAvatar;

          final dynamic act = (m['active'] ?? m['isActive']);
          _meActive = act == true || act?.toString() == 'true';
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now enabled as a worker')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('HTTP $code: $msg')),
      );
    } finally {
      if (mounted) setState(() => _busyEnable = false);
    }
  }

  Future<void> _reactivateMe() async {
    if (_meWorkerId == null) return;
    setState(() => _busyReactivate = true);
    try {
      await _dio.put('/workers/${_meWorkerId}/activate');
      await _loadMe(); // refresh state
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker profile re-enabled')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('HTTP $code: $msg')),
      );
    } finally {
      if (mounted) setState(() => _busyReactivate = false);
    }
  }

  Color _statusColor(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'AVAILABLE':
        return const Color(0xFF12B76A);
      case 'ON_BREAK':
        return const Color(0xFFF59E0B);
      case 'ON_LEAVE':
        return const Color(0xFF7C3AED);
      case 'UNAVAILABLE':
      default:
        return _Brand.subtle;
    }
  }

  String _statusText(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'AVAILABLE':
        return 'Available';
      case 'UNAVAILABLE':
        return 'Unavailable';
      case 'ON_BREAK':
        return 'On break';
      case 'ON_LEAVE':
        return 'On leave';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.provider_tab_details ?? 'Manage')),
      body: RefreshIndicator(
        onRefresh: _loadMe,
        color: _Brand.primary,
        child: ListView(
          children: [
            // -------- Owner-as-worker section (top) --------
            if (_checkingMe)
              const _SkeletonCard()
            else if (_meWorkerId != null)
              Card(
                elevation: 0,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your worker profile',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: _Brand.ink)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFF2F4F7),
                            backgroundImage:
                                (_meAvatarUrl == null || _meAvatarUrl!.isEmpty)
                                    ? null
                                    : NetworkImage(_meAvatarUrl!),
                            child:
                                (_meAvatarUrl == null || _meAvatarUrl!.isEmpty)
                                    ? const Icon(Icons.person_outline,
                                        color: _Brand.subtle)
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_meName ?? 'Me',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _StatusChip(
                                      text: _statusText(_meStatus),
                                      color: _statusColor(_meStatus),
                                    ),
                                    if (!_meActive)
                                      const _StatusChip(
                                        text: 'Inactive',
                                        color: Color(0xFFB42318), // red-ish
                                      ),
                                    if (_meAvgRating != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star,
                                              size: 16,
                                              color: Color(0xFFFFB703)),
                                          const SizedBox(width: 4),
                                          Text(
                                              _meAvgRating!.toStringAsFixed(1)),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_meActive) // normal shortcuts
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.schedule),
                              label: const Text('My availability'),
                              onPressed: () {
                                if (widget.providerId == null) {
                                  _needProvider(context);
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProviderWorkerAvailabilityScreen(
                                      workerId: _meWorkerId!,
                                      workerName: _meName ?? 'Me',
                                    ),
                                  ),
                                );
                              },
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.design_services_outlined),
                              label: const Text('My services'),
                              onPressed: () {
                                if (widget.providerId == null) {
                                  _needProvider(context);
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProviderWorkerServicesScreen(
                                      providerId: widget.providerId!,
                                      workerId: _meWorkerId!,
                                      workerName: _meName ?? 'Me',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      else // inactive → show re-enable CTA
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'You are currently removed from the team.',
                              style:
                                  TextStyle(fontSize: 12, color: _Brand.subtle),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: FilledButton.icon(
                                onPressed:
                                    _busyReactivate ? null : _reactivateMe,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(_busyReactivate
                                    ? 'Re-enabling…'
                                    : 'Re-enable me'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )
            else
              // Not a worker yet → enable card
              Card(
                elevation: 0,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Work as staff',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: _Brand.ink)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _workerType,
                        items: const [
                          DropdownMenuItem(
                              value: 'GENERAL', child: Text('General')),
                          DropdownMenuItem(
                              value: 'BARBER', child: Text('Barber')),
                          DropdownMenuItem(
                              value: 'THERAPIST', child: Text('Therapist')),
                          DropdownMenuItem(
                              value: 'STYLIST', child: Text('Stylist')),
                        ],
                        onChanged: (v) =>
                            setState(() => _workerType = v ?? 'GENERAL'),
                        decoration:
                            const InputDecoration(labelText: 'Worker type'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _status,
                        items: const [
                          DropdownMenuItem(
                              value: 'AVAILABLE', child: Text('Available')),
                          DropdownMenuItem(
                              value: 'UNAVAILABLE', child: Text('Unavailable')),
                          DropdownMenuItem(
                              value: 'ON_BREAK', child: Text('On break')),
                          DropdownMenuItem(
                              value: 'ON_LEAVE', child: Text('On leave')),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? 'AVAILABLE'),
                        decoration:
                            const InputDecoration(labelText: 'Initial status'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: _busyEnable ? null : _enableOwnerAsWorker,
                          child: Text(_busyEnable
                              ? 'Enabling…'
                              : 'Enable me as a worker'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You’ll be able to set your hours and assign services to yourself after enabling.',
                        style: TextStyle(fontSize: 12, color: _Brand.subtle),
                      ),
                    ],
                  ),
                ),
              ),

            // -------- Existing manage tiles --------
            _Tile(
              icon: Icons.design_services_outlined,
              title: t.provider_manage_services_title ?? 'Services',
              subtitle: t.provider_manage_services_subtitle ??
                  'Create, edit, and organize services',
              onTap: () {
                if (widget.providerId == null) return _needProvider(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProviderServicesScreen(providerId: widget.providerId!),
                  ),
                );
              },
            ),
            _Tile(
              icon: Icons.business_outlined,
              title: t.provider_manage_business_title ?? 'Business info',
              subtitle: t.provider_manage_business_subtitle ??
                  'Name, contacts, address, about',
              onTap: () {
                if (widget.providerId == null) return _needProvider(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProviderSettingsScreen(providerId: widget.providerId!),
                  ),
                );
              },
            ),
            _Tile(
              icon: Icons.group_outlined,
              title: t.provider_manage_staff_title ?? 'Staff',
              subtitle: t.provider_manage_staff_subtitle ??
                  'Invite and manage workers',
              onTap: () {
                if (widget.providerId == null) return _needProvider(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProviderStaffListScreen(providerId: widget.providerId!),
                  ),
                );
              },
            ),
            _Tile(
              icon: Icons.schedule_outlined,
              title: t.provider_manage_hours_title ?? 'Working hours',
              subtitle: t.provider_manage_hours_subtitle ??
                  'Set business schedule and breaks',
              onTap: () {
                if (widget.providerId == null) return _needProvider(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderBusinessHoursScreen(
                      providerId: widget.providerId!,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- Small bits ------------------------------- */

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: (subtitle == null) ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.28), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
          height: h,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(12),
          ),
        );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [box(18), box(56), box(36)],
        ),
      ),
    );
  }
}
