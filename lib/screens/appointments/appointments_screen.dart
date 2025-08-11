// lib/screens/appointments/appointments_screen.dart
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
  final _items = <AppointmentItem>[];
  bool _loading = false;

  final _lineFmt = DateFormat('EEE, d MMM • HH:mm'); // Tue, 29 Jul • 12:00

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _svc.listMine();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list);
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

  Future<void> _refresh() => _load();

  // inside _AppointmentsScreenState
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

  @override
  Widget build(BuildContext context) {
    final body = _loading && _items.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _AppointmentCard(
                  item: _items[i],
                  lineFmt: _lineFmt,
                  onCancel: (_items[i].status == 'BOOKED')
                      ? () => _cancel(_items[i].id)
                      : null,
                ),
              );

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: RefreshIndicator(onRefresh: _refresh, child: body),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentItem item;
  final DateFormat lineFmt;
  final VoidCallback? onCancel;

  const _AppointmentCard({
    required this.item,
    required this.lineFmt,
    this.onCancel,
  });

  Color _statusColor(BuildContext c) {
    switch (item.status) {
      case 'COMPLETED':
        return Colors.green.shade600;
      case 'CANCELED':
        return Colors.red.shade600;
      default:
        return Theme.of(c).colorScheme.primary; // BOOKED / others
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = lineFmt.format(item.start.toLocal());
    final end = DateFormat('HH:mm').format(item.end.toLocal());

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: const Icon(Icons.event_note_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: Service name or generic
                  Text(
                    (item.serviceName?.isNotEmpty ?? false)
                        ? item.serviceName!
                        : 'Appointment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  // Date/time
                  Text('$start – $end'),
                  // Provider + worker
                  if ((item.providerName ?? '').isNotEmpty)
                    Text(item.providerName!,
                        style: TextStyle(color: Colors.grey[700])),
                  if ((item.workerName ?? '').isNotEmpty)
                    Text('by ${item.workerName!}',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: _statusColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('No appointments yet'),
            const SizedBox(height: 4),
            Text('Book a service to see it here.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
