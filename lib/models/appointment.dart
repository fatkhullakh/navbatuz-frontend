import 'package:intl/intl.dart';

class AppointmentItem {
  final String id;
  final DateTime start;
  final DateTime end;
  final String status;
  final String? providerName;
  final String? serviceName;
  final String? workerName;

  // Optional location snippet (if provided by details endpoint)
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

  static DateTime _combine(String d, String t) {
    // d = yyyy-MM-dd, t = HH:mm:ss
    final dt = DateFormat("yyyy-MM-dd HH:mm:ss").parse('$d $t', true).toLocal();
    return dt;
  }

  factory AppointmentItem.fromJson(Map<String, dynamic> j) {
    final hasStart =
        j.containsKey('start') && j.containsKey('end'); // server variant A
    final hasDateTime =
        j.containsKey('date') && j.containsKey('startTime'); // variant B

    DateTime start, end;
    if (hasStart) {
      start = DateTime.parse(j['start'].toString()).toLocal();
      end = DateTime.parse(j['end'].toString()).toLocal();
    } else if (hasDateTime) {
      start = _combine(j['date'].toString(), j['startTime'].toString());
      end = _combine(j['date'].toString(), j['endTime'].toString());
    } else {
      // Fallback to now if bad payload
      start = DateTime.now();
      end = start.add(const Duration(minutes: 25));
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
