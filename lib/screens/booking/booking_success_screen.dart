// lib/screens/booking/booking_success_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/appointment.dart';

class BookingSuccessScreen extends StatelessWidget {
  final AppointmentItem appointment;
  const BookingSuccessScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 96),
                const SizedBox(height: 12),
                Text(t.bookingSuccessTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                //Text('${appointment.date} | ${appointment.startTime} – ${appointment.endTime}'),
                const SizedBox(height: 16),
                Text(t.bookingSuccessDesc, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: Text(t.continueLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
