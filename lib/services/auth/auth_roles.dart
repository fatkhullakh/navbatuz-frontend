// lib/services/auth_roles.dart
enum AppRole { customer, provider, worker }

Set<AppRole> parseRoles(dynamic raw) {
  // raw can be List<dynamic> like ["CUSTOMER","PROVIDER"]
  final out = <AppRole>{};
  if (raw is List) {
    for (final r in raw) {
      final s = r.toString().toUpperCase();
      if (s.contains('PROVIDER')) out.add(AppRole.provider);
      if (s.contains('WORKER')) out.add(AppRole.worker);
      if (s.contains('CUSTOMER')) out.add(AppRole.customer);
    }
  }
  // always default to customer if nothing is present
  if (out.isEmpty) out.add(AppRole.customer);
  return out;
}
