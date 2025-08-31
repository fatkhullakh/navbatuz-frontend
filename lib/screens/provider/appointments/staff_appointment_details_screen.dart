import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/appointments/appointment_service.dart';
import '../../../models/appointment_detail_staff.dart';

// Stormy Morning palette
const _kStormDark = Color(0xFF384959); // deep slate
const _kStormMuted = Color(0xFF6A89A7); // slate blue-gray

/// Status colors (visual only)
Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'BOOKED':
      return const Color(0xFF12B76A);
    case 'RESCHEDULED':
      return const Color(0xFF7F56D9);
    case 'COMPLETED':
      return const Color(0xFF155EEF);
    case 'NO_SHOW':
      return const Color(0xFFB54708);
    case 'CANCELLED':
      return const Color(0xFFD92D20);
    default:
      return _kStormMuted;
  }
}

/// Localized status label
String _statusText(String status, AppLocalizations t) {
  switch (status.toUpperCase()) {
    case 'BOOKED':
      return t.status_booked;
    case 'COMPLETED':
      return t.status_completed;
    case 'CANCELLED':
      return t.status_cancelled;
    case 'RESCHEDULED':
      return t.status_rescheduled;
    case 'NO_SHOW':
      return t.status_no_show;
    default:
      return status; // fallback
  }
}

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
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appointment_details_title),
        backgroundColor: Colors.white,
        foregroundColor: _kStormDark,
        elevation: 0,
      ),
      body: FutureBuilder<AppointmentDetailsStaff>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(child: Text(t.error_generic));
          }

          final d = snap.data!;
          final now = DateTime.now();
          final ended = now.isAfter(_endAsDateTime(d));
          final status = d.status.toUpperCase();

          // Permissions (no business logic change)
          final canCancel = status == 'BOOKED' && !ended;
          final canNoShow =
              (status == 'BOOKED' || status == 'COMPLETED') && ended;
          final canUndoNoShow = status == 'NO_SHOW';

          final chipColor = _statusColor(status);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                // Header
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: _kStormDark.withOpacity(.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _kStormDark.withOpacity(.06),
                          backgroundImage:
                              (d.avatarUrl != null && d.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(d.avatarUrl!)
                                  : null,
                          child: (d.avatarUrl == null || d.avatarUrl!.isEmpty)
                              ? const Icon(Icons.person, color: _kStormDark)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _kStormDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${d.date.toIso8601String().split('T').first} • ${d.start}–${d.end}',
                                style: TextStyle(
                                    color: _kStormDark.withOpacity(.7)),
                              ),
                              if (d.phoneNumber != null &&
                                  d.phoneNumber!.isNotEmpty)
                                Text(d.phoneNumber!,
                                    style: TextStyle(
                                        color: _kStormDark.withOpacity(.7))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(.12),
                            border:
                                Border.all(color: chipColor.withOpacity(.45)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _statusText(status, t),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: chipColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _infoTile(
                    icon: Icons.design_services_outlined,
                    label: t.common_service,
                    value: d.serviceName),
                _infoTile(
                    icon: Icons.person_outline,
                    label: t.appointment_staff_label,
                    value: d.workerName),
                _infoTile(
                    icon: Icons.store_mall_directory_outlined,
                    label: t.common_provider,
                    value: d.providerName),
                _infoTile(
                    icon: Icons.info_outline,
                    label: t.status_label,
                    value: _statusText(status, t)),

                const SizedBox(height: 12),

                if (!canCancel && !canNoShow && !canUndoNoShow)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      t.appointment_no_actions,
                      style: TextStyle(color: _kStormDark.withOpacity(.6)),
                    ),
                  ),
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
            final t = AppLocalizations.of(context)!;
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

            final filledStyle = FilledButton.styleFrom(
              backgroundColor: _kStormDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            );

            final outlinedStyle = OutlinedButton.styleFrom(
              foregroundColor: _kStormDark,
              side: const BorderSide(color: _kStormDark, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  if (canCancel)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: outlinedStyle,
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(t.appointment_action_cancel),
                        onPressed: () async {
                          try {
                            await _svc.cancel(widget.appointmentId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(t.appointment_cancel_success)),
                            );
                            await _refresh();
                          } on LateCancellationException catch (e) {
                            final mins = e.minutes;
                            if (!mounted) return;
                            final msg = mins == null
                                ? t.appointment_cancel_too_late
                                : t.appointment_cancel_too_late_with_window(
                                    mins);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg)));
                          } on DioException catch (e) {
                            if (!mounted) return;
                            final msg = e.response?.data?.toString() ??
                                e.message ??
                                t.error_generic;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                      ),
                    ),
                  if (canCancel && (canNoShow || canUndoNoShow))
                    const SizedBox(width: 12),
                  if (canNoShow)
                    Expanded(
                      child: FilledButton.icon(
                        style: filledStyle,
                        icon: const Icon(Icons.person_off),
                        label: Text(t.action_mark_no_show),
                        onPressed: () async {
                          try {
                            await _svc.noShow(widget.appointmentId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.toast_marked_no_show)),
                            );
                            await _refresh();
                          } on DioException catch (e) {
                            if (!mounted) return;
                            final msg = e.response?.data?.toString() ??
                                e.message ??
                                t.error_generic;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                      ),
                    ),
                  if (canUndoNoShow)
                    Expanded(
                      child: FilledButton.icon(
                        style: filledStyle,
                        icon: const Icon(Icons.undo),
                        label: Text(t.action_undo_no_show),
                        onPressed: () async {
                          try {
                            await _svc.undoNoShow(widget.appointmentId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.toast_undo_no_show)),
                            );
                            await _refresh();
                          } on DioException catch (e) {
                            if (!mounted) return;
                            final msg = e.response?.data?.toString() ??
                                e.message ??
                                t.error_generic;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg)));
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

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _kStormDark.withOpacity(.08)),
      ),
      child: ListTile(
        leading: Icon(icon, color: _kStormDark),
        title:
            Text(label, style: TextStyle(color: _kStormDark.withOpacity(.7))),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _kStormDark,
          ),
        ),
      ),
    );
  }
}
