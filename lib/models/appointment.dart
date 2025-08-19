// lib/models/appointment.dart
import 'package:intl/intl.dart';

DateTime _combineLocalDateAndTime(String dateT, String time) {
  // date: "YYYY-MM-DD", time: "HH:mm:ss"
  return DateTime.parse('$dateT$time');
}

int? _toIntPrice(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.toInt();
  final s = v.toString();
  final d = double.tryParse(s);
  return d?.round();
}

class AppointmentItem {
  final String id;

  /// Always filled by parser (from either `start` ISO or `date`+`startTime`)
  final DateTime start;

  /// Always filled by parser (from either `end` ISO or `date`+`endTime`)
  final DateTime end;

  /// BOOKED / CONFIRMED / CANCELLED / COMPLETED ...
  final String status;

  // --- optional IDs (used for navigation / book again) ---
  final String? providerId;
  final String? workerId;
  final String? serviceId;

  // --- optional display names ---
  final String? providerName;
  final String? workerName;
  final String? serviceName;

  // --- optional location bits ---
  final String? addressLine1;
  final String? city;
  final String? countryIso2;

  // --- optional price ---
  final int? price;

  AppointmentItem({
    required this.id,
    required this.start,
    required this.end,
    required this.status,
    this.providerId,
    this.workerId,
    this.serviceId,
    this.providerName,
    this.workerName,
    this.serviceName,
    this.addressLine1,
    this.city,
    this.countryIso2,
    this.price,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> j) {
    // Try ISO datetimes first (details payload)
    DateTime? start;
    DateTime? end;

    final startIso = j['start']?.toString();
    final endIso = j['end']?.toString();
    if (startIso != null && startIso.isNotEmpty) {
      start = DateTime.tryParse(startIso);
    }
    if (endIso != null && endIso.isNotEmpty) {
      end = DateTime.tryParse(endIso);
    }

    // Fallback to list payload: date + startTime/endTime (e.g., "2025-08-25" + "09:00:00")
    if (start == null || end == null) {
      final date = j['date']?.toString();
      final st = j['startTime']?.toString();
      final et = j['endTime']?.toString();
      if (date != null && st != null)
        start = _combineLocalDateAndTime(date, st);
      if (date != null && et != null) end = _combineLocalDateAndTime(date, et);
    }

    // Safe fallbacks if backend is inconsistent
    final now = DateTime.now();
    start ??= now;
    end ??= start.add(const Duration(minutes: 30));

    return AppointmentItem(
      id: (j['id'] ?? '').toString(),
      start: start,
      end: end,
      status: (j['status'] ?? '').toString(),

      // IDs if your backend sends them (keep null-safe)
      providerId: j['providerId']?.toString(),
      workerId: j['workerId']?.toString(),
      serviceId: j['serviceId']?.toString(),

      // Names (your /appointments/me returns these)
      providerName: j['providerName']?.toString(),
      workerName: j['workerName']?.toString(),
      serviceName: j['serviceName']?.toString(),

      // Location (adapt if your backend nests this in 'location')
      addressLine1: j['addressLine1']?.toString() ??
          (j['location'] is Map
              ? (j['location']['addressLine1']?.toString())
              : null),
      city: j['city']?.toString() ??
          (j['location'] is Map ? (j['location']['city']?.toString()) : null),
      countryIso2: j['countryIso2']?.toString() ??
          (j['location'] is Map
              ? (j['location']['countryIso2']?.toString())
              : null),

      price: _toIntPrice(j['price']),
    );
  }
}
