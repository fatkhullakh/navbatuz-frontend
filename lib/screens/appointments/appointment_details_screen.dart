import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/appointment_detail.dart';
import '../../services/appointment_service.dart';
import '../../services/api_service.dart';

import '../providers/provider_screen.dart';
import '../../screens/worker/worker_screen.dart';
import '../../screens/booking/service_booking_screen.dart';

/* ---------------------------- Brand constants ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7); // #6A89A7
  static const accent = Color(0xFF88BDF2); // #88BDF2
  static const accentSoft = Color(0xFFBDDDFC); // #BDDDFC
  static const ink = Color(0xFF384959); // #384959
  static const border = Color(0xFFE6ECF2);
}

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final _svc = AppointmentService();
  final Dio _dio = ApiService.client;

  late Future<AppointmentDetail> _future;
  bool _busyCancel = false;

  @override
  void initState() {
    super.initState();
    _future = _svc.getById(widget.appointmentId);
  }

  Future<void> _cancel(AppointmentDetail a) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.appointment_cancel_confirm_title),
        content: Text(t.appointment_cancel_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common_no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.appointment_cancel_confirm_yes),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyCancel = true);
    try {
      await _svc.cancel(a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.appointment_cancel_success)),
      );
      Navigator.pop(context, true);
    } on LateCancellationException catch (e) {
      if (!mounted) return;
      final msg = (e.minutes != null)
          ? t.appointment_cancel_too_late_with_window(e.minutes!)
          : t.appointment_cancel_too_late;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final msg = (code == 401)
          ? t.error_session_expired
          : t.appointment_cancel_failed_generic(code?.toString() ?? '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.appointment_cancel_failed_unknown)),
      );
    } finally {
      if (mounted) setState(() => _busyCancel = false);
    }
  }

  // ---- Fallback resolvers (when IDs are missing in payload) ----

  Future<String?> _findProviderIdByName(String? providerName) async {
    if (providerName == null || providerName.trim().isEmpty) return null;
    try {
      final r = await _dio.get('/providers/public/all',
          queryParameters: {'page': 0, 'size': 100, 'sortBy': 'name'});
      final list = (r.data is Map && (r.data as Map)['content'] is List)
          ? ((r.data as Map)['content'] as List)
          : const <dynamic>[];
      for (final e in list) {
        if (e is Map &&
            (e['name']?.toString().toLowerCase().trim() ?? '') ==
                providerName.toLowerCase().trim()) {
          return e['id']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _findWorkerIdByName({
    required String? providerId,
    required String? workerName,
  }) async {
    if (providerId == null || workerName == null) return null;
    try {
      final d = await _dio.get('/providers/public/$providerId/details');
      final workers = (d.data is Map && (d.data as Map)['workers'] is List)
          ? ((d.data as Map)['workers'] as List)
          : const <dynamic>[];
      for (final w in workers) {
        if (w is Map &&
            (w['name']?.toString().toLowerCase().trim() ?? '') ==
                workerName.toLowerCase().trim()) {
          return w['id']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _findServiceIdSmart({
    required String providerId,
    required String serviceName,
    required AppointmentDetail appointmentDetail,
  }) async {
    final resp =
        await _dio.get('/services/public/provider/$providerId/services');
    final list = (resp.data as List?) ?? const [];

    int parseIsoMinutes(String? iso) {
      if (iso == null || iso.isEmpty) return 0;
      final s = iso.toUpperCase();
      if (!s.startsWith('PT')) return 0;
      int h = 0, m = 0, sec = 0;
      final hIdx = s.indexOf('H');
      final mIdx = s.indexOf('M');
      final sIdx = s.indexOf('S');
      if (hIdx != -1) h = int.tryParse(s.substring(2, hIdx)) ?? 0;
      if (mIdx != -1) {
        final start = (hIdx == -1) ? 2 : hIdx + 1;
        m = int.tryParse(s.substring(start, mIdx)) ?? 0;
      }
      if (sIdx != -1) {
        final start = (mIdx != -1) ? mIdx + 1 : (hIdx != -1 ? hIdx + 1 : 2);
        sec = int.tryParse(s.substring(start, sIdx)) ?? 0;
      }
      return Duration(hours: h, minutes: m, seconds: sec).inMinutes;
    }

    String norm(String v) => v.toLowerCase().trim();

    final matches = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is Map && norm(e['name']?.toString() ?? '') == norm(serviceName)) {
        matches.add(Map<String, dynamic>.from(e));
      }
    }
    if (matches.isEmpty) return null;

    final int apptDurMin =
        appointmentDetail.end.difference(appointmentDetail.start).inMinutes;
    final int? apptPrice = appointmentDetail.price;

    Map<String, dynamic>? best;
    int bestScore = 1 << 30;

    for (final e in matches) {
      final durMin = parseIsoMinutes(e['duration']?.toString());
      final priceNum = e['price'];
      final priceInt =
          (priceNum is num) ? priceNum.round() : int.tryParse('$priceNum');

      final nonZeroPenalty = (durMin > 0) ? 0 : 100000;
      final durDelta = (durMin - apptDurMin).abs();
      final priceDelta = (apptPrice != null && priceInt != null)
          ? (priceInt - apptPrice).abs()
          : 0;

      final score = nonZeroPenalty + (durDelta * 100) + priceDelta;
      if (score < bestScore) {
        bestScore = score;
        best = e;
      }
    }

    return best?['id']?.toString();
  }

  Future<void> _openProvider(AppointmentDetail a) async {
    var pid = a.providerId;
    pid ??= await _findProviderIdByName(a.providerName);
    if (pid == null || pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider not found')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProviderScreen(providerId: pid!),
    ));
  }

  Future<void> _openWorker(AppointmentDetail a) async {
    var pid = a.providerId;
    pid ??= await _findProviderIdByName(a.providerName);
    if (pid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider not found')),
      );
      return;
    }

    var wid = a.workerId;
    wid ??=
        await _findWorkerIdByName(providerId: pid, workerName: a.workerName);

    if (wid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker not found')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WorkerScreen(
        workerId: wid!,
        providerId: pid,
        workerNameFallback: a.workerName,
      ),
    ));
  }

  Future<void> _bookAgain(AppointmentDetail a) async {
    var pid = a.providerId ?? await _findProviderIdByName(a.providerName);
    if (pid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking info is incomplete.')),
      );
      return;
    }

    final sid = a.serviceId ??
        await _findServiceIdSmart(
          providerId: pid,
          serviceName: a.serviceName ?? '',
          appointmentDetail: a,
        );

    var wid = a.workerId ??
        await _findWorkerIdByName(
          providerId: pid,
          workerName: a.workerName,
        );

    if (sid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve service for booking.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ServiceBookingScreen(
        serviceId: sid,
        providerId: pid,
        initialWorkerId: wid,
      ),
    ));
  }

  // ---- Brand helpers ----
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'FINISHED':
        return const Color(0xFF2E7D32); // green
      case 'NO_SHOW':
        return const Color(0xFFEF6C00); // orange
      case 'CANCELED':
      case 'CANCELLED':
        return const Color(0xFFB00020); // red
      case 'BOOKED':
        return _Brand.primary;
      case 'CONFIRMED':
      case 'RESCHEDULED':
      default:
        return _Brand.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final df = DateFormat('EEE, d MMM yyyy');
    final tf = DateFormat('HH:mm');
    final priceFmt = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(t.appointment_details_title)),
      body: FutureBuilder<AppointmentDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Failed to load: ${snap.error}'));
          }
          final a = snap.data!;
          final status = a.status.toUpperCase();
          final canCancel = status == 'BOOKED' || status == 'CONFIRMED';
          final statusColor = _statusColor(status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Service + Provider (tap provider)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: _Brand.border, width: 1.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.medical_services_outlined,
                      color: _Brand.ink),
                  title: Text(
                    a.serviceName ?? 'Service',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: InkWell(
                    onTap: () => _openProvider(a),
                    child: Text(
                      a.providerName ?? 'Provider',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        color: _Brand.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: (a.price != null)
                      ? _PricePill(text: priceFmt.format(a.price))
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // Date & time + status
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: _Brand.border, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateTimePill(
                          dateText: df.format(a.start),
                          timeText:
                              '${tf.format(a.start)} – ${tf.format(a.end)}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(text: status, color: statusColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Address
              if ((a.providerAddress ?? '').isNotEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _Brand.border, width: 1.0),
                  ),
                  child: ListTile(
                    leading:
                        const Icon(Icons.place_outlined, color: _Brand.ink),
                    title: Text(a.providerAddress!),
                  ),
                ),
              if ((a.providerAddress ?? '').isNotEmpty)
                const SizedBox(height: 12),

              // Worker (tap worker)
              if ((a.workerName ?? '').isNotEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _Brand.border, width: 1.0),
                  ),
                  child: ListTile(
                    leading:
                        const Icon(Icons.person_outline, color: _Brand.ink),
                    title: InkWell(
                      onTap: () => _openWorker(a),
                      child: Text(
                        a.workerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: _Brand.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    subtitle: const Text('Staff'),
                  ),
                ),

              const SizedBox(height: 20),

              // Book again
              SizedBox(
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: () => _bookAgain(a),
                  icon: const Icon(Icons.refresh),
                  label: Text(t.appointment_action_book_again),
                  style: FilledButton.styleFrom(
                    backgroundColor: _Brand.accentSoft.withOpacity(.75),
                    foregroundColor: _Brand.ink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel / Back
              if (canCancel)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _busyCancel ? null : () => _cancel(a),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(_busyCancel
                      ? 'Cancelling…'
                      : t.appointment_action_cancel),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _Brand.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    foregroundColor: _Brand.ink,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
            ],
          );
        },
      ),
    );
  }
}

/* ----------------------------- Small UI -------------------------------- */

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.28), width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _DateTimePill extends StatelessWidget {
  final String dateText;
  final String timeText;
  const _DateTimePill({required this.dateText, required this.timeText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _Brand.accentSoft.withOpacity(.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _Brand.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.7)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              dateText,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text("•", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              timeText,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String text;
  const _PricePill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Brand.accentSoft.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _Brand.border),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, color: _Brand.ink),
      ),
    );
  }
}
