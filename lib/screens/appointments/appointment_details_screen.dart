// lib/screens/appointments/appointment_details_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';

// screens we navigate to
import '../providers/provider_screen.dart';
import '../worker/worker_screen.dart';
import '../booking/service_booking_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final _svc = AppointmentService();
  late Future<AppointmentItem> _future;
  bool _busyCancel = false;

  @override
  void initState() {
    super.initState();
    _future = _svc.getById(widget.appointmentId);
  }

  Future<void> _cancel(AppointmentItem a) async {
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

  void _openProvider(AppointmentItem a) {
    if (a.providerId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScreen(providerId: a.providerId!),
      ),
    );
  }

  void _openWorker(AppointmentItem a) {
    if (a.workerId == null || a.providerId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkerScreen(
          workerId: a.workerId!,
          providerId: a.providerId!,
        ),
      ),
    );
  }

  void _bookAgain(AppointmentItem a) {
    if (a.serviceId == null || a.providerId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceBookingScreen(
          serviceId: a.serviceId!,
          providerId: a.providerId!,
          preferredWorkerId: a.workerId, // may be null → “Anyone”
        ),
      ),
    );
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
      body: FutureBuilder<AppointmentItem>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Failed to load: ${snap.error}'));
          }

          final a = snap.data!;
          final status = (a.status).toUpperCase();
          final canCancel = status == 'BOOKED' || status == 'CONFIRMED';
          final canBookAgain = a.serviceId != null && a.providerId != null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Service
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: Text(a.serviceName ?? 'Service'),
                  subtitle: (a.providerName == null)
                      ? null
                      : InkWell(
                          onTap: () => _openProvider(a),
                          child: Text(
                            a.providerName!,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
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

              // Location
              if ((a.addressLine1 ?? a.city ?? a.countryIso2) != null)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text([
                      if ((a.addressLine1 ?? '').isNotEmpty) a.addressLine1,
                      if ((a.city ?? '').isNotEmpty) a.city,
                      if ((a.countryIso2 ?? '').isNotEmpty) a.countryIso2,
                    ].whereType<String>().join(', ')),
                  ),
                ),

              const SizedBox(height: 12),

              // Worker (tappable)
              if ((a.workerName ?? '').isNotEmpty)
                Card(
                  elevation: 0,
                  child: ListTile(
                    onTap: () => _openWorker(a),
                    leading: const Icon(Icons.person_outline),
                    title: Text(a.workerName!),
                    subtitle: const Text('Staff'),
                    trailing: (a.workerId != null && a.providerId != null)
                        ? const Icon(Icons.chevron_right)
                        : null,
                  ),
                ),

              const SizedBox(height: 24),

              // Actions
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
                ),

              if (canBookAgain) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _bookAgain(a),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Book again'),
                ),
              ],

              if (!canCancel && !canBookAgain)
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
