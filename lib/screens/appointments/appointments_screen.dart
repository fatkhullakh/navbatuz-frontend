import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../services/user_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _apptSvc = AppointmentService();
  final _items = <AppointmentItem>[];
  bool _loading = false;

  final _fmt = DateFormat('EEE, d MMM • HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _apptSvc.listMine(); // <-- just call /appointments/me
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _AppointmentCard(item: _items[i], fmt: _fmt),
              ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentItem item;
  final DateFormat fmt;
  final VoidCallback? onCancel;

  const _AppointmentCard(
      {required this.item, required this.fmt, this.onCancel});

  Color _statusColor(BuildContext c) {
    switch (item.status) {
      case 'COMPLETED':
        return Colors.green.shade600;
      case 'CANCELED':
        return Colors.red.shade600;
      default:
        return Theme.of(c).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = fmt.format(item.start.toLocal());
    final end = DateFormat('HH:mm').format(item.end.toLocal());

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: const Icon(Icons.event_note_rounded),
        ),
        title:
            Text('Appointment', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$start – $end'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item.status,
                  style: TextStyle(
                    color: _statusColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  )),
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 8),
              InkWell(
                  onTap: onCancel,
                  child: const Text('Cancel', style: TextStyle(fontSize: 12))),
            ],
          ],
        ),
      ),
    );
  }
}
