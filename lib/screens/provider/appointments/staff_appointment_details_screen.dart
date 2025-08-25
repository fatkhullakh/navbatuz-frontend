import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../services/appointments/appointment_service.dart';
import '../../../models/appointment_detail_staff.dart';

class StaffAppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;

  const StaffAppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<StaffAppointmentDetailsScreen> createState() =>
      _StaffAppointmentDetailsScreenState();
}

class _StaffAppointmentDetailsScreenState
    extends State<StaffAppointmentDetailsScreen> {
  final _svc = AppointmentService();
  late Future<AppointmentDetailsStaff> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.getStaffDetails(widget.appointmentId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _svc.getStaffDetails(widget.appointmentId);
    });
  }

  DateTime _endAsDateTime(AppointmentDetailsStaff d) {
    // d.end is "HH:mm"
    final parts = d.end.split(':');
    return DateTime(
      d.date.year,
      d.date.month,
      d.date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: FutureBuilder<AppointmentDetailsStaff>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return const Center(child: Text('Failed to load details'));
          }
          final d = snap.data!;
          final now = DateTime.now();
          final ended = now.isAfter(_endAsDateTime(d));

          // Back-end rules:
          // - Only BOOKED/COMPLETED -> NO_SHOW (after start + grace, enforced server-side)
          // - Only NO_SHOW -> undo (restores to BOOKED if not passed end, else COMPLETED)
          final status =
              d.status.toUpperCase(); // "BOOKED"/"COMPLETED"/"NO_SHOW"/...
          final canCancel = status == 'BOOKED' && !ended;
          final canNoShow =
              (status == 'BOOKED' || status == 'COMPLETED') && ended;
          final canUndoNoShow = status == 'NO_SHOW';

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
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
                          if (d.phoneNumber != null &&
                              d.phoneNumber!.isNotEmpty)
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
                const SizedBox(height: 16),
                if (!canCancel && !canNoShow && !canUndoNoShow)
                  const Text(
                    'No actions available for this status.',
                    style: TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: FutureBuilder<AppointmentDetailsStaff>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done ||
                snap.data == null) {
              return const SizedBox.shrink();
            }
            final d = snap.data!;
            final now = DateTime.now();
            final ended = now.isAfter(_endAsDateTime(d));
            final status = d.status.toUpperCase();

            final canCancel = status == 'BOOKED' && !ended;
            final canNoShow =
                (status == 'BOOKED' || status == 'COMPLETED') && ended;
            final canUndoNoShow = status == 'NO_SHOW';

            if (!canCancel && !canNoShow && !canUndoNoShow) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (canCancel)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel'),
                        onPressed: () async {
                          try {
                            await _svc.cancel(widget.appointmentId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Appointment cancelled')),
                            );
                            await _refresh();
                          } on LateCancellationException catch (e) {
                            final mins = e.minutes;
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                mins == null
                                    ? 'Too late to cancel.'
                                    : 'Too late to cancel (< $mins min).',
                              ),
                            ));
                          } on DioException catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.response?.data?.toString() ??
                                  e.message ??
                                  'Cancel failed'),
                            ));
                          }
                        },
                      ),
                    ),
                  if (canCancel && (canNoShow || canUndoNoShow))
                    const SizedBox(width: 12),
                  if (canNoShow)
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.person_off),
                        label: const Text('Mark no-show'),
                        onPressed: () async {
                          try {
                            await _svc.noShow(widget.appointmentId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Marked as no-show')),
                            );
                            await _refresh();
                          } on DioException catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.response?.data?.toString() ??
                                  e.message ??
                                  'No-show failed'),
                            ));
                          }
                        },
                      ),
                    ),
                  if (canUndoNoShow)
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo no-show'),
                        onPressed: () async {
                          try {
                            await _svc.undoNoShow(widget.appointmentId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No-show undone')),
                            );
                            await _refresh();
                          } on DioException catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(e.response?.data?.toString() ??
                                  e.message ??
                                  'Undo failed'),
                            ));
                          }
                        },
                      ),
                    ),
                ],
              ),
            );
          },
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
              child: Text(k, style: const TextStyle(color: Colors.black54)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
