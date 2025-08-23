import 'package:dio/dio.dart';
import '../api_service.dart';

class ProviderStaffService {
  final Dio _dio = ApiService.client;

  Future<List<StaffMember>> list(String providerId) async {
    // Owner/receptionist list (includes inactive)
    final r = await _dio.get('/workers/provider/$providerId');
    final data = (r.data as List?) ?? const [];
    return data.whereType<Map>().map((m0) {
      final m = m0.cast<String, dynamic>();
      // WorkerResponse should include user.* — if your mapper names differ, adjust below
      final user = (m['user'] is Map)
          ? (m['user'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      return StaffMember(
        id: (m['id'] ?? '').toString(),
        userId: (user['id'] ?? m['userId'] ?? '').toString(),
        name: [
          (user['name'] ?? m['name'] ?? '').toString(),
          (user['surname'] ?? m['surname'] ?? '').toString()
        ].where((s) => s.toString().trim().isNotEmpty).join(' ').trim(),
        role: (m['workerType'] ?? m['role'] ?? '').toString(),
        isActive: (m['isActive'] ?? m['active'] ?? true) == true,
        phoneNumber: (user['phoneNumber'] ?? m['phoneNumber'] ?? '').toString(),
        email: (user['email'] ?? m['email'] ?? '').toString(),
        avatarUrl: (user['avatarUrl'] ?? m['avatarUrl'] ?? '').toString(),
      );
    }).toList();
  }

  Future<void> invite(CreateWorkerReq req) async {
    await _dio.post('/workers', data: {
      'user': req.user,
      'provider': req.provider,
      'workerType': req.workerType,
    });
  }

  /// New aggregated invite (register + worker + assign + availability + message)
  Future<InviteWorkerResponse> inviteAndRegister(
      InviteWorkerRequest req) async {
    final r = await _dio.post('/invitations/worker', data: req.toJson());
    final m = (r.data as Map).cast<String, dynamic>();
    return InviteWorkerResponse(
      userId: (m['userId'] ?? '').toString(),
      workerId: (m['workerId'] ?? '').toString(),
      tempPassword: (m['tempPassword'] ?? '').toString(),
    );
  }
}

class StaffMember {
  final String id;
  final String userId;
  final String? name;
  final String? role;
  final bool isActive;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  StaffMember({
    required this.id,
    required this.userId,
    required this.isActive,
    this.name,
    this.role,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
  });

  StaffMember copyWith({bool? isActive}) => StaffMember(
        id: id,
        userId: userId,
        isActive: isActive ?? this.isActive,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        email: email,
        avatarUrl: avatarUrl,
      );
}

class CreateWorkerReq {
  final String user; // UUID
  final String provider; // UUID
  final String workerType; // e.g. BARBER
  CreateWorkerReq(
      {required this.user, required this.provider, required this.workerType});
}

/// Payload for aggregated invite endpoint (owner flow)
class InviteWorkerRequest {
  final String providerId;
  final String workerType; // e.g. BARBER
  final NewUser user; // personal/contact/avatar
  final List<String> serviceIds;
  final List<PlannedDay> planned; // weekly planned availability
  InviteWorkerRequest({
    required this.providerId,
    required this.workerType,
    required this.user,
    this.serviceIds = const [],
    this.planned = const [],
  });

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'workerType': workerType,
        'user': user.toJson(),
        'serviceIds': serviceIds,
        'planned': planned.map((e) => e.toJson()).toList(),
      };
}

class InviteWorkerResponse {
  final String userId;
  final String workerId;
  final String tempPassword; // if backend returns (useful for SMS)
  InviteWorkerResponse(
      {required this.userId,
      required this.workerId,
      required this.tempPassword});
}

class NewUser {
  final String name;
  final String surname;
  final String email;
  final String phoneNumber;
  final String? avatarUrl;
  final String? gender; // optional
  NewUser({
    required this.name,
    required this.surname,
    required this.email,
    required this.phoneNumber,
    this.avatarUrl,
    this.gender,
  });
  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'email': email,
        'phoneNumber': phoneNumber,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (gender != null) 'gender': gender,
      };
}

class PlannedDay {
  final String day; // MONDAY..SUNDAY
  final String? start; // "09:00"
  final String? end; // "18:00"
  final bool working;
  PlannedDay({required this.day, this.start, this.end, required this.working});
  Map<String, dynamic> toJson() => {
        'day': day,
        if (start != null) 'startTime': '$start:00',
        if (end != null) 'endTime': '$end:00',
        'working': working,
        'bufferBetweenAppointments': 'PT0M',
      };
}
