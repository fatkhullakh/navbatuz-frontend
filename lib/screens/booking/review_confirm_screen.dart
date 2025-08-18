// lib/screens/booking/review_confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/appointment_service.dart';
import '../../services/service_catalog_service.dart';
import '../../services/provider_public_service.dart';
import 'booking_success_screen.dart';
import '../../services/customer_service.dart';
import '../../services/appointment_service.dart';

class ReviewConfirmScreen extends StatefulWidget {
  final ServiceDetails service;
  final ProvidersDetails provider;
  final WorkerLite worker;
  final DateTime date; // selected day
  final String startHHmmss; // "HH:mm:ss"

  const ReviewConfirmScreen({
    super.key,
    required this.service,
    required this.provider,
    required this.worker,
    required this.date,
    required this.startHHmmss,
  });

  @override
  State<ReviewConfirmScreen> createState() => _ReviewConfirmScreenState();
}

class _ReviewConfirmScreenState extends State<ReviewConfirmScreen> {
  final _appointments = AppointmentService();
  final _customers = CustomerService();
  bool _submitting = false;
  String _payment = 'cash'; // cash only

  DateTime get _start {
    final parts = widget.startHHmmss.split(':');
    return DateTime(widget.date.year, widget.date.month, widget.date.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime get _end => _start.add(widget.service.duration ?? Duration.zero);

  String _fmtDT(DateTime dt) =>
      '${DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(dt)} | '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtRange(DateTime a, DateTime b) =>
      '${a.hour.toString().padLeft(2, '0')}:${a.minute.toString().padLeft(2, '0')} - '
      '${b.hour.toString().padLeft(2, '0')}:${b.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final price = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    ).format(widget.service.price);

    return Scaffold(
      appBar: AppBar(title: Text(t.reviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_fmtDT(_start),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(widget.service.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                      Text(price),
                    ]),
                    const SizedBox(height: 4),
                    Text('${t.withWorker} ${widget.worker.name}'),
                    Text('${t.timeRange}: ${_fmtRange(_start, _end)}'),
                    const Divider(height: 20),
                    Row(children: [
                      Expanded(child: Text(t.subtotal)),
                      Text(price,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ]),
            ),
          ),
          const SizedBox(height: 16),
          Text(t.howPay, style: Theme.of(context).textTheme.titleMedium),
          RadioListTile<String>(
              value: 'cash',
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v!),
              title: Text(t.payCash)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitting
                ? null
                : () async {
                    setState(() => _submitting = true);
                    try {
                      final customerId = await _customers.myId(); // <- crucial
                      final appt = await _appointments.create(
                        serviceId: widget.service.id,
                        workerId: widget.worker.id,
                        date: widget.date,
                        startTimeHHmmss: widget.startHHmmss,
                        customerId: customerId,
                      );
                      if (!mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) =>
                                BookingSuccessScreen(appointment: appt)),
                      );
                    } on SlotUnavailableException {
                      final start = _start;
                      final end = _end;
                      final range =
                          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'
                          ' - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Selected time is not available for ${widget.worker.name}: $range. Choose another slot.')),
                      );
                    } on CustomerMissingException {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Customer profile not found. Log in as a customer or create a customer account.')),
                      );
                    } on NotAuthorizedException {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Forbidden. Your account is not allowed to book.')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Failed: $e')));
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.confirmAndBook),
          ),
        ],
      ),
    );
  }
}
