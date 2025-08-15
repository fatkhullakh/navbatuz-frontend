class AppointmentDetail {
  final String id;
  final DateTime start;
  final DateTime end;
  final String status;

  final String? providerName;
  final String? providerAddress; // built from addressLine1 + city + countryIso2
  final String? providerPhone; // not in payload now, keep nullable

  final String? serviceName;
  final String? workerName;

  final int? price; // UZS, rounded to int
  final int? discount; // keep for future, null for now

  AppointmentDetail({
    required this.id,
    required this.start,
    required this.end,
    required this.status,
    this.providerName,
    this.providerAddress,
    this.providerPhone,
    this.serviceName,
    this.workerName,
    this.price,
    this.discount,
  });

  int get subtotal => price ?? 0;
  int get total => subtotal - (discount ?? 0);

  factory AppointmentDetail.fromJson(Map<String, dynamic> j) {
    // expected now:
    // id, date, startTime, endTime, status,
    // providerName, addressLine1, city, countryIso2,
    // serviceName, price (num), workerName

    String norm(String? t) {
      if (t == null) return '';
      return t.split(':').length == 2 ? '$t:00' : t;
    }

    final date = j['date']?.toString() ?? '';
    final st = norm(j['startTime']?.toString());
    final et = norm(j['endTime']?.toString());

    String? address() {
      final parts = <String>[];
      final l1 = j['addressLine1']?.toString();
      final city = j['city']?.toString();
      final c2 = j['countryIso2']?.toString();
      if (l1 != null && l1.trim().isNotEmpty) parts.add(l1);
      if (city != null && city.trim().isNotEmpty) parts.add(city);
      if (c2 != null && c2.trim().isNotEmpty) parts.add(c2);
      return parts.isEmpty ? null : parts.join(', ');
    }

    int? priceToInt() {
      final p = j['price'];
      if (p == null) return null;
      if (p is int) return p;
      if (p is double) return p.round();
      if (p is num) return p.toInt();
      final parsed = num.tryParse(p.toString());
      return parsed?.round();
    }

    return AppointmentDetail(
      id: (j['id'] ?? '').toString(),
      start: DateTime.parse('${date}T$st'),
      end: DateTime.parse('${date}T$et'),
      status: (j['status'] ?? 'BOOKED').toString(),
      providerName: j['providerName']?.toString(),
      providerAddress: address(),
      providerPhone: j['providerPhone']?.toString(), // not provided now
      serviceName: j['serviceName']?.toString(),
      workerName: j['workerName']?.toString(),
      price: priceToInt(),
      discount: (j['discount'] is num) ? (j['discount'] as num).round() : null,
    );
  }
}
