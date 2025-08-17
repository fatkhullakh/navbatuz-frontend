import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String appointmentId;
  const BookingSuccessScreen({super.key, required this.appointmentId});

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
                const Icon(Icons.check_circle, size: 96),
                const SizedBox(height: 12),
                Text(t.bookingSuccessTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(t.bookingSuccessDesc, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('#$appointmentId',
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/customer-appointments',
                      (_) => false,
                    );
                  },
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
