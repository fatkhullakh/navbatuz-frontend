import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/appointments/appointment_service.dart';
import '../../services/services/service_catalog_service.dart';
import '../../services/services/provider_public_service.dart';
import 'booking_success_screen.dart';
import '../../services/customers/customer_service.dart';

/* ---------------------------- Brand constants ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

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
    return DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  DateTime get _end => _start.add(widget.service.duration ?? Duration.zero);

  String _fmtDT(DateTime dt) =>
      '${DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(dt)}'
      ' • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtRange(DateTime a, DateTime b) =>
      '${a.hour.toString().padLeft(2, '0')}:${a.minute.toString().padLeft(2, '0')}'
      ' – ${b.hour.toString().padLeft(2, '0')}:${b.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final price = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    ).format(widget.service.price);

    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: AppBar(
        title: Text(t.reviewTitle,
            style: const TextStyle(
                color: _Brand.ink, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _Brand.border),
        ),
        iconTheme: const IconThemeData(color: _Brand.ink),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_fmtDT(_start),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _Brand.ink)),
          const SizedBox(height: 12),
          _Card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(widget.service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: _Brand.ink)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _Brand.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _Brand.border),
                  ),
                  child: Text(price,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: _Brand.ink)),
                ),
              ]),
              const SizedBox(height: 4),
              if ((widget.service.description ?? '').isNotEmpty)
                Text(widget.service.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _Brand.subtle)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 18, color: _Brand.subtle),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text('${t.withWorker} ${widget.worker.name}',
                          style: const TextStyle(color: _Brand.ink))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: _Brand.subtle),
                  const SizedBox(width: 6),
                  Text('${t.timeRange}: ${_fmtRange(_start, _end)}',
                      style: const TextStyle(color: _Brand.ink)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 18, color: _Brand.subtle),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(widget.provider.name,
                          style: const TextStyle(color: _Brand.ink))),
                ],
              ),
              const Divider(height: 20),
              Row(children: [
                Expanded(
                    child: Text(t.subtotal,
                        style: const TextStyle(color: _Brand.ink))),
                Text(price,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _Brand.ink)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Text(t.howPay,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: _Brand.ink)),
          const SizedBox(height: 8),
          _Card(
            child: RadioListTile<String>(
              value: 'cash',
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v!),
              title: Text(t.payCash, style: const TextStyle(color: _Brand.ink)),
              activeColor: _Brand.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _Brand.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      try {
                        final customerId = await _customers.myId(); // required
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
                        final range = _fmtRange(_start, _end);
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
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')));
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.confirmAndBook),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Small UI bits ---------------------------- */
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _Brand.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: child,
    );
  }
}
