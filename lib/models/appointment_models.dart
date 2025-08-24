// lib/models/appointment_models.dart
import 'dart:convert';

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
  });

  factory Appointment.fromJson(Map<String, dynamic> m) {
    return Appointment(
      id: m['id'],
      workerId: m['workerId'],
      serviceId: m['serviceId'],
      providerId: m['providerId'],
      date: DateTime.parse(m['date']), // "YYYY-MM-DD"
      start: (m['startTime'] ?? '').toString(),
      end: (m['endTime'] ?? '').toString(),
      status: statusFromString(m['status']),
      customerId: m['customerId'],
      guestId: m['guestId'],
      guestMask: m['guestMask'],
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
