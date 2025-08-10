class AppointmentItem {
  final String id;
  final String workerId;
  final String serviceId;
  final String customerId;
  final String providerId;
  final DateTime start; // combined date + startTime
  final DateTime end; // combined date + endTime
  final String status;

  AppointmentItem({
    required this.id,
    required this.workerId,
    required this.serviceId,
    required this.customerId,
    required this.providerId,
    required this.start,
    required this.end,
    required this.status,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String; // "2025-08-10"
    final startTime = json['startTime'] as String; // "14:30[:00]"
    final endTime = json['endTime'] as String;

    DateTime parseDT(String d, String t) {
      // Normalize "HH:mm" -> "HH:mm:00" to be safe
      final tt = t.split(':').length == 2 ? '$t:00' : t;
      return DateTime.parse('${d}T$tt'); // ✅ Correct interpolation
    }

    return AppointmentItem(
      id: (json['id'] ?? '') as String,
      workerId: (json['workerId'] ?? '') as String,
      serviceId: (json['serviceId'] ?? '') as String,
      customerId: (json['customerId'] ?? '') as String,
      providerId: (json['providerId'] ?? '') as String,
      start: parseDT(date, startTime),
      end: parseDT(date, endTime),
      status: (json['status'] ?? 'BOOKED') as String,
    );
  }
}
