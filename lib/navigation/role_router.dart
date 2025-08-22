// lib/navigation/role_router.dart
import 'package:flutter/material.dart';
import '../services/auth/auth_roles.dart';

class RoleRouter {
  static Future<void> goHome(BuildContext context, Set<AppRole> roles) async {
    // If user has both provider & worker, let them choose
    if (roles.contains(AppRole.provider) && roles.contains(AppRole.worker)) {
      final selected = await showDialog<AppRole>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Continue as'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, AppRole.provider),
              child: const Text('Provider'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, AppRole.worker),
              child: const Text('Worker'),
            ),
          ],
        ),
      );
      if (selected == AppRole.worker) {
        _replace(context, '/workers');
        return;
      }
      // default to provider if dialog dismissed
      _replace(context, '/providers');
      return;
    }

    if (roles.contains(AppRole.provider)) {
      _replace(context, '/providers');
    } else if (roles.contains(AppRole.worker)) {
      _replace(context, '/workers');
    } else {
      _replace(context, '/customers');
    }
  }

  static void _replace(BuildContext context, String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }
}
