import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_detail.dart';
import '../../services/appointment_service.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String id;
  const AppointmentDetailsScreen({super.key, required this.id});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final _svc = AppointmentService();
  late Future<AppointmentDetail> _future;

  final _headerFmt = DateFormat('HH:mm - EEE, MMM d');
  final _timeFmt = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _future = _svc.getDetails(widget.id);
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'COMPLETED':
      case 'FINISHED':
        return Colors.green.shade700;
      case 'CANCELED':
      case 'CANCELLED':
        return Colors.red.shade700;
      case 'CONFIRMED':
      case 'BOOKED':
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  Future<void> _cancel(AppointmentDetail d) async {
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
      await AppointmentService().cancel(d.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Appointment canceled')));
      Navigator.pop(context, true); // return to list; let it refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppointmentDetail>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final d = snap.data!;
        final canCancel = (d.status.toUpperCase() == 'BOOKED' ||
                d.status.toUpperCase() == 'CONFIRMED') &&
            d.start.isAfter(DateTime.now());

        return Scaffold(
          appBar: AppBar(
            title: Text(_headerFmt.format(d.start)),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Text(
                  d.status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _statusColor(d.status),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Provider card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(),
                  title: Text(d.providerName ?? 'Provider',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(d.providerAddress ?? '—',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.place_outlined),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('TODO: open map')),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Service block
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(d.serviceName ?? 'Service',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        d.workerName != null ? 'with ${d.workerName}' : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        d.price != null ? _sum(d.price!) : '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Time'),
                          Text(
                              '${_timeFmt.format(d.start)} - ${_timeFmt.format(d.end)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Price summary
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      _row('Subtotal', _sum(d.subtotal)),
                      const SizedBox(height: 8),
                      _row('Discount',
                          d.discount != null ? '- ${_sum(d.discount!)}' : '-'),
                      const Divider(height: 20),
                      _row('Total', _sum(d.total), bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Contact
              if ((d.providerPhone ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(d.providerPhone!),
                      TextButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('TODO: dial phone')),
                        ),
                        child: const Text('Call'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: canCancel
                    ? () => _cancel(d)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('TODO: book again')),
                        );
                      },
                child: Text(canCancel ? 'Cancel' : 'Book again'),
              ),
            ),
          ),
        );
      },
    );
  }

  String _sum(int v) {
    // simple thousands formatter for UZS; replace with intl NumberFormat if you prefer
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write(',');
    }
    return '$s'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',') +
        ' sum';
  }

  Widget _row(String l, String r, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(r,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        ],
      );
}
