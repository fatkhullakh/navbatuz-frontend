// Replace your file with this version

class AppointmentDetail {
  final String id;
  final DateTime start;
  final DateTime end;
  final String status;

  // IDs (optional, but enable navigation/booking)
  final String? providerId;
  final String? workerId;
  final String? serviceId;

  final String? providerName;
  final String? providerAddress; // addressLine1 + city + countryIso2
  final String? providerPhone;

  final String? serviceName;
  final String? workerName;

  final int? price; // UZS, rounded
  final int? discount; // future

  AppointmentDetail({
    required this.id,
    required this.start,
    required this.end,
    required this.status,
    this.providerId,
    this.workerId,
    this.serviceId,
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
    // Supports either:
    // A) { date, startTime, endTime }  OR
    // B) { start, end } ISO
    DateTime? start;
    DateTime? end;

    String norm(String? t) {
      if (t == null) return '';
      return t.split(':').length == 2 ? '$t:00' : t;
    }

    if (j['start'] != null && j['end'] != null) {
      start = DateTime.tryParse(j['start'].toString());
      end = DateTime.tryParse(j['end'].toString());
    } else {
      final date = j['date']?.toString() ?? '';
      final st = norm(j['startTime']?.toString());
      final et = norm(j['endTime']?.toString());
      if (date.isNotEmpty && st.isNotEmpty) {
        start = DateTime.parse('${date}T$st');
      }
      if (date.isNotEmpty && et.isNotEmpty) {
        end = DateTime.parse('${date}T$et');
      }
    }

    start ??= DateTime.now();
    end ??= start.add(const Duration(minutes: 30));

    String? address() {
      final parts = <String>[];
      void add(String? s) {
        if (s != null && s.trim().isNotEmpty) parts.add(s);
      }

      add(j['addressLine1']?.toString());
      add(j['city']?.toString());
      add(j['countryIso2']?.toString());
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
      start: start,
      end: end,
      status: (j['status'] ?? 'BOOKED').toString(),

      // IDs if backend sends them
      providerId: j['providerId']?.toString(),
      workerId: j['workerId']?.toString(),
      serviceId: j['serviceId']?.toString(),

      providerName: j['providerName']?.toString(),
      providerAddress: address(),
      providerPhone: j['providerPhone']?.toString(),

      serviceName: j['serviceName']?.toString(),
      workerName: j['workerName']?.toString(),

      price: priceToInt(),
      discount: (j['discount'] is num) ? (j['discount'] as num).round() : null,
    );
  }
}
