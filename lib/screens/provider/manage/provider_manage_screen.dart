import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

import 'package:frontend/screens/provider/manage/staff/provider_worker_availability_screen.dart';
import 'package:frontend/screens/provider/manage/staff/provider_worker_services_screen.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';

// Existing manage screens
import 'services/provider_services_screen.dart';
import 'staff/provider_staff_list_screen.dart';
import 'hours/provider_business_hours_screen.dart';
import '../manage/business_info/provider_settings_screen.dart';

/// Stormy Morning palette
class _Brand {
  static const dark = Color(0xFF384959);
  static const steel = Color(0xFF6A89A7);
  static const sky = Color(0xFF88BDF2);
  static const ice = Color(0xFFBDDDFC);

  static const ink = dark;
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
}

class ProviderManageScreen extends StatefulWidget {
  final String? providerId;
  const ProviderManageScreen({super.key, required this.providerId});

  @override
  State<ProviderManageScreen> createState() => _ProviderManageScreenState();
}

class _ProviderManageScreenState extends State<ProviderManageScreen> {
  final Dio _dio = ApiService.client;

  // role flags
  bool _roleResolved = false;
  bool _isOwner = false;
  bool _isReceptionist = false;

  // owner-as-worker state
  bool _checkingMe = false;
  String? _meWorkerId;
  String? _meName;
  String? _meAvatarUrl;
  String? _meStatus;
  double? _meAvgRating;
  bool _meActive = false;

  // enable form (owner-as-worker)
  String _workerType = 'GENERAL';
  String _status = 'AVAILABLE';
  bool _busyEnable = false;
  bool _busyReactivate = false;

  @override
  void initState() {
    super.initState();
    _resolveRoleAndLoad();
  }

  Future<void> _resolveRoleAndLoad() async {
    // read JWT and detect roles
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    String rolesCsv = '';
    if (token != null && token.isNotEmpty) {
      final claims = Jwt.parseJwt(token);
      final raw = claims['role'] ?? claims['roles'] ?? claims['authorities'];
      if (raw is List) {
        rolesCsv = raw.map((e) => e.toString()).join(',');
      } else if (raw != null) {
        rolesCsv = raw.toString();
      }
    }
    final u = rolesCsv.toUpperCase();
    _isOwner = u.contains('OWNER');
    _isReceptionist = u.contains('RECEPTIONIST');

    if (_isOwner) {
      _loadMe();
    } else {
      setState(() {
        _roleResolved = true;
        _checkingMe = false;
      });
    }
  }

  Future<void> _loadMe() async {
    setState(() {
      _roleResolved = true;
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
              content: Text(
                '${AppLocalizations.of(context)!.http_error(':')} ${e.message}',
              ),
            ),
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
    final t = AppLocalizations.of(ctx)!;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(t.error_generic)),
    );
  }

  Future<void> _enableOwnerAsWorker() async {
    final t = AppLocalizations.of(context)!;
    if (widget.providerId == null) {
      _needProvider(context);
      return;
    }
    setState(() => _busyEnable = true);
    try {
      final body = {
        'workerType': _workerType,
        'status': _status,
        'isActive': true
      };
      final r = await _dio
          .post('/providers/${widget.providerId}/owner-as-worker', data: body);

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
        SnackBar(content: Text(t.owner_enabled_as_worker)),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.http_error('HTTP $code: $msg'))),
      );
    } finally {
      if (mounted) setState(() => _busyEnable = false);
    }
  }

  Future<void> _reactivateMe() async {
    final t = AppLocalizations.of(context)!;
    if (_meWorkerId == null) return;
    setState(() => _busyReactivate = true);
    try {
      await _dio.put('/workers/$_meWorkerId/activate');
      await _loadMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.worker_profile_reenabled)),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.http_error('HTTP $code: $msg'))),
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

  String _statusText(BuildContext context, String? s) {
    final t = AppLocalizations.of(context)!;
    switch ((s ?? '').toUpperCase()) {
      case 'AVAILABLE':
        return t.worker_status_available;
      case 'UNAVAILABLE':
        return t.worker_status_unavailable;
      case 'ON_BREAK':
        return t.worker_status_on_break;
      case 'ON_LEAVE':
        return t.worker_status_on_leave;
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.provider_tab_details),
        backgroundColor: _Brand.dark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_isOwner) {
            await _loadMe();
          } else {
            setState(() {});
          }
        },
        color: _Brand.steel,
        child: ListView(
          children: [
            // ---------- OWNER-ONLY: owner-as-worker card(s) ----------
            if (_roleResolved && _isOwner) ...[
              if (_checkingMe)
                const _SkeletonCard()
              else if (_meWorkerId != null)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: _Brand.steel.withOpacity(.25)),
                  ),
                  color: _Brand.ice.withOpacity(.5),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.owner_worker_profile,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _Brand.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: _Brand.sky.withOpacity(.25),
                              backgroundImage: (_meAvatarUrl == null ||
                                      _meAvatarUrl!.isEmpty)
                                  ? null
                                  : NetworkImage(_meAvatarUrl!),
                              child: (_meAvatarUrl == null ||
                                      _meAvatarUrl!.isEmpty)
                                  ? const Icon(Icons.person_outline,
                                      color: _Brand.subtle)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      _meName?.isNotEmpty == true
                                          ? _meName!
                                          : t.me_label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _StatusChip(
                                        text: _statusText(context, _meStatus),
                                        color: _statusColor(_meStatus),
                                      ),
                                      if (!_meActive)
                                        _StatusChip(
                                          text: t.status_inactive,
                                          color: const Color(0xFFB42318),
                                        ),
                                      if (_meAvgRating != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star,
                                                size: 16,
                                                color: Color(0xFFFFB703)),
                                            const SizedBox(width: 4),
                                            Text(_meAvgRating!
                                                .toStringAsFixed(1)),
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
                        if (_meActive)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _Brand.ink,
                                  side: BorderSide(
                                      color: _Brand.steel.withOpacity(.4)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.schedule),
                                label: Text(t.my_availability),
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
                                        workerName: _meName ?? t.me_label,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _Brand.ink,
                                  side: BorderSide(
                                      color: _Brand.steel.withOpacity(.4)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon:
                                    const Icon(Icons.design_services_outlined),
                                label: Text(t.my_services),
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
                                        workerName: _meName ?? t.me_label,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.removed_from_team_hint,
                                style: const TextStyle(
                                    fontSize: 12, color: _Brand.subtle),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 44,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _Brand.dark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      _busyReactivate ? null : _reactivateMe,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(
                                    _busyReactivate
                                        ? t.reenabling_ellipsis
                                        : t.reenable_me,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: _Brand.steel.withOpacity(.25)),
                  ),
                  color: _Brand.ice.withOpacity(.5),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.work_as_staff_title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _Brand.ink)),
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
                          decoration: InputDecoration(
                            labelText: t.worker_type_label,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _status,
                          items: [
                            DropdownMenuItem(
                                value: 'AVAILABLE',
                                child: Text(t.worker_status_available)),
                            DropdownMenuItem(
                                value: 'UNAVAILABLE',
                                child: Text(t.worker_status_unavailable)),
                            DropdownMenuItem(
                                value: 'ON_BREAK',
                                child: Text(t.worker_status_on_break)),
                            DropdownMenuItem(
                                value: 'ON_LEAVE',
                                child: Text(t.worker_status_on_leave)),
                          ],
                          onChanged: (v) =>
                              setState(() => _status = v ?? 'AVAILABLE'),
                          decoration: InputDecoration(
                            labelText: t.initial_status_label,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _Brand.dark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                _busyEnable ? null : _enableOwnerAsWorker,
                            child: Text(
                              _busyEnable
                                  ? t.enabling_ellipsis
                                  : t.enable_me_as_worker,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.enable_hint_after,
                          style: const TextStyle(
                              fontSize: 12, color: _Brand.subtle),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            // ---------- Common manage tiles ----------
            _Tile(
              icon: Icons.design_services_outlined,
              title: t.provider_manage_services_title,
              subtitle: t.provider_manage_services_subtitle,
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
              title: t.provider_manage_business_title,
              subtitle: t.provider_manage_business_subtitle,
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
              title: t.provider_manage_staff_title,
              subtitle: t.provider_manage_staff_subtitle,
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
              title: t.provider_manage_hours_title,
              subtitle: t.provider_manage_hours_subtitle,
              onTap: () {
                if (widget.providerId == null) return _needProvider(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderBusinessHoursScreen(
                        providerId: widget.providerId!),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _Brand.steel.withOpacity(.25)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _Brand.sky.withOpacity(.25),
          child: Icon(icon, color: _Brand.ink),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: (subtitle == null) ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right, color: _Brand.ink),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [box(18), box(56), box(36)]),
      ),
    );
  }
}
