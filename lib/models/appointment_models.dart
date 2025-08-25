// Supports /appointments/... (STAFF responses too)

enum AppointmentStatus { BOOKED, RESCHEDULED, CANCELLED, COMPLETED }

AppointmentStatus statusFromString(String s) => AppointmentStatus.values
    .firstWhere((e) => e.name == s, orElse: () => AppointmentStatus.BOOKED);

class Appointment {
  final String id;
  final String workerId;
  final String serviceId;
  final String providerId;
  final DateTime date; // local date at midnight
  final String start; // "HH:mm"
  final String end; // "HH:mm"
  final AppointmentStatus status;
  final String? customerId;
  final String? guestId;
  final String? guestMask; // "********1234"

  // extra fields available from *staff* endpoints
  final String? serviceName;
  final String? customerName;
  final String? workerName;
  final String? providerName;

  Appointment({
    required this.id,
    required this.workerId,
    required this.serviceId,
    required this.providerId,
    required this.date,
    required this.start,
    required this.end,
    required this.status,
    this.customerId,
    this.guestId,
    this.guestMask,
    this.serviceName,
    this.customerName,
    this.workerName,
    this.providerName,
  });

  factory Appointment.fromJson(Map<String, dynamic> m) {
    // backend sometimes returns startTime/endTime keys
    final start = (m['startTime'] ?? m['start'] ?? '').toString();
    final end = (m['endTime'] ?? m['end'] ?? '').toString();
    return Appointment(
      id: m['id'].toString(),
      workerId: m['workerId'].toString(),
      serviceId: m['serviceId'].toString(),
      providerId: m['providerId'].toString(),
      date: DateTime.parse(m['date']), // "YYYY-MM-DD"
      start: start,
      end: end,
      status: statusFromString(m['status'].toString()),
      customerId: m['customerId']?.toString(),
      guestId: m['guestId']?.toString(),
      guestMask: m['guestMask']?.toString(),
      serviceName: m['serviceName']?.toString(),
      customerName: m['customerName']?.toString(),
      workerName: m['workerName']?.toString(),
      providerName: m['providerName']?.toString(),
    );
  }
}

class NewAppointmentCmd {
  final String workerId;
  final String serviceId;
  final DateTime date;
  final String startTime; // "HH:mm"
  final String? customerId; // nullable
  final String? guestId; // nullable
  final String? guestPhone; // if guestId is null, you can pass phone+name
  final String? guestName;

  NewAppointmentCmd({
    required this.workerId,
    required this.serviceId,
    required this.date,
    required this.startTime,
    this.customerId,
    this.guestId,
    this.guestPhone,
    this.guestName,
  });

  Map<String, dynamic> toJson() => {
        'workerId': workerId,
        'serviceId': serviceId,
        'date': date.toIso8601String().split('T').first,
        'startTime': startTime,
        if (customerId != null) 'customerId': customerId,
        if (guestId != null) 'guestId': guestId,
        if (guestPhone != null) 'guestPhone': guestPhone,
        if (guestName != null) 'guestName': guestName,
      };
}
