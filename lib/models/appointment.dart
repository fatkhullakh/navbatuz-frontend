// lib/models/appointment.dart
class AppointmentItem {
  final String id;
  final DateTime start; // combined date + startTime
  final DateTime end; // combined date + endTime
  final String status; // e.g., COMPLETED/BOOKED/CANCELED

  final String? workerName; // new
  final String? providerName; // new
  final String? serviceName; // new

  AppointmentItem({
    required this.id,
    required this.start,
    required this.end,
    required this.status,
    this.workerName,
    this.providerName,
    this.serviceName,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> j) {
    final date = j['date'] as String; // "2025-07-29"
    final startTime = j['startTime'] as String; // "12:00[:00]"
    final endTime = j['endTime'] as String;

    String norm(String t) => t.split(':').length == 2 ? '$t:00' : t;

    return AppointmentItem(
      id: j['id'] as String,
      start: DateTime.parse('${date}T${norm(startTime)}'),
      end: DateTime.parse('${date}T${norm(endTime)}'),
      status: (j['status'] ?? 'BOOKED') as String,
      workerName: j['workerName'] as String?,
      providerName: j['providerName'] as String?,
      serviceName: j['serviceName'] as String?,
    );
  }
}
