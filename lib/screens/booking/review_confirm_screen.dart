import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/appointment_service.dart';
import '../../services/profile_service.dart';
import 'booking_success_screen.dart';

class ReviewConfirmScreen extends StatefulWidget {
  final String providerId;
  final String providerName;

  final String serviceId;
  final String serviceName;
  final int price;
  final int durationMinutes;

  final String workerId;
  final String workerName;

  final String dateIso; // yyyy-MM-dd
  final String startTime; // HH:mm:ss

  const ReviewConfirmScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.durationMinutes,
    required this.workerId,
    required this.workerName,
    required this.dateIso,
    required this.startTime,
  });

  @override
  State<ReviewConfirmScreen> createState() => _ReviewConfirmScreenState();
}

class _ReviewConfirmScreenState extends State<ReviewConfirmScreen> {
  final _appt = AppointmentService();
  final _profile = ProfileService();

  bool _saving = false;
  String? _error;

  String _fmt(String hhmmss) {
    final p = hhmmss.split(':');
    if (p.length >= 2) return '${p[0]}:${p[1]}';
    return hhmmss;
  }

  String _endFrom(String start, int minutes) {
    final p = start.split(':');
    final base = DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1]));
    final end = base.add(Duration(minutes: minutes));
    return DateFormat('HH:mm:ss').format(end);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final dateLabel =
        '${DateFormat('MMM d, yyyy').format(DateTime.parse(widget.dateIso))} • '
        '${_fmt(widget.startTime)} – ${_fmt(_endFrom(widget.startTime, widget.durationMinutes))}';

    return Scaffold(
      appBar: AppBar(title: Text(t.reviewTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(widget.providerName,
                      style: const TextStyle(color: Colors.black54)),
                  const Divider(height: 16),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(widget.serviceName),
                    subtitle: Text('${t.withWorker} ${widget.workerName}'),
                    trailing: Text(
                      NumberFormat.currency(
                              locale: 'en_US', symbol: '', decimalDigits: 0)
                          .format(widget.price),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text(t.subtotal)),
                      Text(
                        NumberFormat.currency(
                                locale: 'en_US', symbol: '', decimalDigits: 0)
                            .format(widget.price),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(t.howPay, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          RadioListTile<String>(
            value: 'cash',
            groupValue: 'cash',
            onChanged: (_) {},
            title: Text(t.payCash),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator())
                : Text(t.confirmAndBook),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final me = await _profile.getMe(force: true);
      final created = await _appt.create(
        workerId: widget.workerId,
        serviceId: widget.serviceId,
        customerId: me.id,
        dateIso: widget.dateIso,
        startTime: widget.startTime,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(appointmentId: created.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
