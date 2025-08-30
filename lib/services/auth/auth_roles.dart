// lib/services/auth_roles.dart
enum AppRole { customer, provider, worker, receptionist, owner }

Set<AppRole> parseRoles(dynamic raw) {
  final out = <AppRole>{};

  void addFrom(String s) {
    final u = s.toUpperCase();
    if (u.contains('OWNER')) out.add(AppRole.owner);
    if (u.contains('RECEPTIONIST')) out.add(AppRole.receptionist);
    if (u.contains('PROVIDER')) out.add(AppRole.provider);
    if (u.contains('WORKER')) out.add(AppRole.worker);
    if (u.contains('CUSTOMER')) out.add(AppRole.customer);
  }

  if (raw is String) {
    addFrom(raw);
  } else if (raw is List) {
    for (final r in raw) addFrom(r.toString());
  }

  if (out.isEmpty) out.add(AppRole.customer);
  return out;
}
