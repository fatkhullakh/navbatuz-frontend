import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _svc = AppointmentService();

  bool _loading = false;
  List<AppointmentItem> _upcoming = [];
  List<AppointmentItem> _past = [];

  final _dateFmt = DateFormat('EEE, d MMM');
  final _timeFmt = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _svc.listMine();

      final now = DateTime.now();
      final upcoming = <AppointmentItem>[];
      final past = <AppointmentItem>[];

      for (final a in all) {
        final s = a.status.toUpperCase();
        final isUpcomingStatus = s == 'BOOKED' || s == 'CONFIRMED';
        if (isUpcomingStatus && a.start.isAfter(now)) {
          upcoming.add(a);
        } else {
          past.add(a);
        }
      }

      // Sort: upcoming by date ASC, past by date DESC
      upcoming.sort((a, b) => a.start.compareTo(b.start));
      past.sort((a, b) => b.start.compareTo(a.start));

      setState(() {
        _upcoming = upcoming;
        _past = past;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(String id) async {
    final ok = await showDialog<bool>(
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
    if (ok != true) return;

    try {
      await _svc.cancel(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment canceled')),
      );
      await _load(); // refresh list
    } on DioException catch (e) {
      if (!mounted) return;
      // Optional: handle 401 → force login
      if (e.response?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/login', (_) => false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Cancel failed: ${e.response?.statusCode ?? ''}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed: $e')),
      );
    }
  }

  void _bookAgain(AppointmentItem a) {
    // Navigate to provider/service — wire this to your routes.
    // Example:
    // Navigator.pushNamed(context, '/provider',
    //   arguments: {'providerId': a.providerId, 'serviceId': a.serviceId});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: open provider to book again')),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'FINISHED':
        return Colors.green.shade600;
      case 'CANCELED':
      case 'CANCELLED':
        return Colors.red.shade600;
      case 'CONFIRMED':
      case 'BOOKED':
      default:
        return const Color(0xFF6C5CE7); // lavender-ish primary
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _upcoming.isEmpty && _past.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (_upcoming.isNotEmpty)
                    _Section(
                      title: 'Upcoming Appointments',
                      children: _upcoming
                          .map((a) => _AppointmentCard(
                                item: a,
                                dateFmt: _dateFmt,
                                timeFmt: _timeFmt,
                                statusColor: _statusColor(a.status),
                                primaryActionText: 'Cancel',
                                onPrimaryAction: () => _cancel(a.id),
                              ))
                          .toList(),
                    ),
                  if (_past.isNotEmpty) const SizedBox(height: 12),
                  if (_past.isNotEmpty)
                    _Section(
                      title: 'Finished Appointments',
                      children: _past
                          .map((a) => _AppointmentCard(
                                item: a,
                                dateFmt: _dateFmt,
                                timeFmt: _timeFmt,
                                statusColor: _statusColor(a.status),
                                primaryActionText: 'Book again',
                                onPrimaryAction: () => _bookAgain(a),
                              ))
                          .toList(),
                    ),
                  if (_upcoming.isEmpty && _past.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48.0),
                        child: Text("You don't have any appointments yet."),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...children.expand((w) sync* {
          yield w;
          yield const SizedBox(height: 12);
        })
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentItem item;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final Color statusColor;
  final String primaryActionText;
  final VoidCallback onPrimaryAction;

  const _AppointmentCard({
    required this.item,
    required this.dateFmt,
    required this.timeFmt,
    required this.statusColor,
    required this.primaryActionText,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = dateFmt.format(item.start);
    final timeText =
        "${timeFmt.format(item.start)} – ${timeFmt.format(item.end)}";

    final title = item.serviceName ?? 'Service';
    final provider = item.providerName ?? 'Provider';
    final worker = item.workerName != null ? "with ${item.workerName}" : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_rounded, size: 24),
            ),
            const SizedBox(width: 12),
            // Main text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chip aligned to top-right on small screens? keep here top-left inside column
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (worker != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        worker,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      provider,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(.8),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(dateText,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      const Text("•"),
                      const SizedBox(width: 8),
                      Text(timeText,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onPrimaryAction,
                      child: Text(primaryActionText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
