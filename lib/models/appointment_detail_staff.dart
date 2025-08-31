// DTO for GET /appointments/{appointmentId}/staff

class AppointmentDetailsStaff {
  final String id;
  final DateTime date;
  final String start; // "HH:mm"
  final String end; // "HH:mm"
  final String status;

  final String workerName;
  final String providerName;
  final String serviceName;
  final String customerName;

  final String? phoneNumber;
  final String? avatarUrl;

  AppointmentDetailsStaff({
    required this.id,
    required this.date,
    required this.start,
    required this.end,
    required this.status,
    required this.workerName,
    required this.providerName,
    required this.serviceName,
    required this.customerName,
    this.phoneNumber,
    this.avatarUrl,
  });

  factory AppointmentDetailsStaff.fromJson(Map<String, dynamic> m) {
    final start = (m['startTime'] ?? m['start'] ?? '').toString();
    final end = (m['endTime'] ?? m['end'] ?? '').toString();
    return AppointmentDetailsStaff(
      id: m['id'].toString(),
      date: DateTime.parse(m['date']),
      start: start,
      end: end,
      status: m['status'].toString(),
      workerName: m['workerName']?.toString() ?? '',
      providerName: m['providerName']?.toString() ?? '',
      serviceName: m['serviceName']?.toString() ?? '',
      customerName: m['customerName']?.toString() ?? '',
      phoneNumber: m['phoneNumber']?.toString(),
      avatarUrl: m['avatarUrl']?.toString(),
    );
  }
}
