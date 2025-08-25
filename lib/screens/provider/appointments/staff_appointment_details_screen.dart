import 'package:flutter/material.dart';
import '../../../services/appointments/appointment_service.dart';
import '../../../models/appointment_detail_staff.dart';

class StaffAppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  final DateTime? date; // for No-show logic
  final String? endHHmm; // for No-show logic
  final String? status; // optional

  const StaffAppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
    this.date,
    this.endHHmm,
    this.status,
  });

  bool _isPast() {
    if (date == null || endHHmm == null) return false;
    final parts = endHHmm!.split(':');
    final end = DateTime(date!.year, date!.month, date!.day,
        int.parse(parts[0]), int.parse(parts[1]));
    return DateTime.now().isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final svc = AppointmentService();
    final showNoShow = _isPast();

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: FutureBuilder<AppointmentDetailsStaff>(
        future: svc.getStaffDetails(appointmentId),
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return const Center(child: Text('Failed to load details'));
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        (d.avatarUrl != null && d.avatarUrl!.isNotEmpty)
                            ? NetworkImage(d.avatarUrl!)
                            : null,
                    child: (d.avatarUrl == null || d.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.customerName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                            '${d.date.toIso8601String().split('T').first} • ${d.start}–${d.end}'),
                        if (d.phoneNumber != null && d.phoneNumber!.isNotEmpty)
                          Text(d.phoneNumber!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _kv('Service', d.serviceName),
              _kv('Worker', d.workerName),
              _kv('Provider', d.providerName),
              _kv('Status', d.status),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: Icon(
                      showNoShow ? Icons.person_off : Icons.cancel_outlined),
                  onPressed: () async {
                    try {
                      if (showNoShow) {
                        await AppointmentService().noShow(appointmentId);
                      } else {
                        await AppointmentService().cancel(appointmentId);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } on LateCancellationException catch (e) {
                      final mins = e.minutes;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            mins == null
                                ? 'Too late to cancel.'
                                : 'Too late to cancel (< $mins min).',
                          ),
                        ));
                      }
                    }
                  },
                  label: Text(showNoShow ? 'No-show' : 'Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 96,
                child: Text(k, style: const TextStyle(color: Colors.black54))),
            const SizedBox(width: 8),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
