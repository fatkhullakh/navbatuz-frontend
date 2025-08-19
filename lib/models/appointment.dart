import 'package:intl/intl.dart';

class AppointmentItem {
  final String id;
  final DateTime start;
  final DateTime end;
  final String status;
  final String? providerName;
  final String? serviceName;
  final String? workerName;
  final String? addressLine1;
  final String? city;
  final String? countryIso2;
  final double? price;

  AppointmentItem({
    required this.id,
    required this.start,
    required this.end,
    required this.status,
    this.providerName,
    this.serviceName,
    this.workerName,
    this.addressLine1,
    this.city,
    this.countryIso2,
    this.price,
  });

  // Server sends date + time with no TZ → treat as LOCAL, do NOT toLocal()
  static DateTime _combineLocal(String d, String t) {
    // If time is "HH:mm", make it "HH:mm:ss"
    final parts = t.split(':');
    final hhmmss = parts.length == 2 ? '$t:00' : t;
    // "yyyy-MM-ddTHH:mm:ss" with no zone = local time in Dart
    return DateTime.parse('${d}T$hhmmss');
  }

  // For ISO strings: only convert to local if the value is actually UTC (ends with Z)
  static DateTime _parseIsoSmart(String s) {
    final dt = DateTime.parse(s);
    return dt.isUtc ? dt.toLocal() : dt;
  }

  factory AppointmentItem.fromJson(Map<String, dynamic> j) {
    final hasIso =
        j.containsKey('start') && j.containsKey('end'); // full ISO variant
    final hasDateTime =
        j.containsKey('date') && j.containsKey('startTime'); // split variant

    DateTime start, end;
    if (hasIso) {
      start = _parseIsoSmart(j['start'].toString());
      end = _parseIsoSmart(j['end'].toString());
    } else if (hasDateTime) {
      start = _combineLocal(j['date'].toString(), j['startTime'].toString());
      end = _combineLocal(j['date'].toString(), j['endTime'].toString());
    } else {
      // fallback
      start = DateTime.now();
      end = start.add(const Duration(minutes: 30));
    }

    return AppointmentItem(
      id: j['id'].toString(),
      start: start,
      end: end,
      status: (j['status'] ?? '').toString(),
      providerName: j['providerName']?.toString(),
      serviceName: j['serviceName']?.toString(),
      workerName: j['workerName']?.toString(),
      addressLine1: j['addressLine1']?.toString(),
      city: j['city']?.toString(),
      countryIso2: j['countryIso2']?.toString(),
      price: (j['price'] is num) ? (j['price'] as num).toDouble() : null,
    );
  }
}
