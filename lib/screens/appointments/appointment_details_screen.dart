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
    final resp = await _dio.get(
      '/services/public/provider/$providerId/services',
    );
    final list = (resp.data as List?) ?? const [];

    // parse ISO-8601 durations like PT30M, PT1H30M, PT0S
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

    // Prefer non-zero duration; then closest to original duration; then closest price
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

      final nonZeroPenalty = (durMin > 0) ? 0 : 100000; // push PT0S to the end
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Service + Provider (tap provider)
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: Text(a.serviceName ?? 'Service'),
                  subtitle: InkWell(
                    onTap: () => _openProvider(a),
                    child: Text(
                      a.providerName ?? 'Provider',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  trailing: (a.price != null)
                      ? Text(
                          priceFmt.format(a.price),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // Date & time
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(df.format(a.start)),
                  subtitle: Text('${tf.format(a.start)} – ${tf.format(a.end)}'),
                  trailing: Chip(label: Text(status)),
                ),
              ),
              const SizedBox(height: 12),

              // Address
              if ((a.providerAddress ?? '').isNotEmpty)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(a.providerAddress!),
                  ),
                ),
              const SizedBox(height: 12),

              // Worker (tap worker)
              if ((a.workerName ?? '').isNotEmpty)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: InkWell(
                      onTap: () => _openWorker(a),
                      child: Text(
                        a.workerName!,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
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
                child: FilledButton.icon(
                  onPressed: () => _bookAgain(a),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Book again'),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel / Back
              if (canCancel)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _busyCancel ? null : () => _cancel(a),
                  icon: const Icon(Icons.cancel_outlined),
                  label:
                      Text(_busyCancel ? 'Cancelling…' : 'Cancel appointment'),
                )
              else
                OutlinedButton(
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
