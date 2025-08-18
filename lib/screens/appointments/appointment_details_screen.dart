import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment.dart';
import '../../l10n/app_localizations.dart';

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.appointment_cancel_failed_unknown)),
      );
    } finally {
      if (mounted) setState(() => _busyCancel = false);
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
          final status = a.status.toUpperCase();
          final canCancel = status == 'BOOKED' || status == 'CONFIRMED';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: Text(a.serviceName ?? 'Service'),
                  subtitle: Text(a.providerName ?? 'Provider'),
                  trailing: (a.price != null)
                      ? Text(
                          priceFmt.format(a.price),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
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
              if ((a.addressLine1 ?? a.city ?? a.countryIso2) != null)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text([
                      if ((a.addressLine1 ?? '').isNotEmpty) a.addressLine1,
                      if ((a.city ?? '').isNotEmpty) a.city,
                      if ((a.countryIso2 ?? '').isNotEmpty) a.countryIso2
                    ].whereType<String>().join(', ')),
                  ),
                ),
              const SizedBox(height: 12),
              if (a.workerName != null)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(a.workerName!),
                    subtitle: const Text('Staff'),
                  ),
                ),
              const SizedBox(height: 24),
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
