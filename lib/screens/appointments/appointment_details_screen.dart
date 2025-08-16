import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyCancel = true);
    try {
      await _svc.cancel(a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Appointment canceled')));
      Navigator.pop(context, true); // notify parent to refresh
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancel failed: ${code ?? ''}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    } finally {
      if (mounted) setState(() => _busyCancel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, d MMM yyyy');
    final tf = DateFormat('HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
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
