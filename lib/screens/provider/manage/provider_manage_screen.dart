import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'services/provider_services_screen.dart';
import 'staff/provider_staff_list_screen.dart';
import 'hours/provider_business_hours_screen.dart';
import '../manage/business_info/provider_settings_screen.dart';

class ProviderManageScreen extends StatelessWidget {
  final String? providerId; // ← nullable now
  const ProviderManageScreen({super.key, required this.providerId});

  void _needProvider(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(ctx)!.error_generic ??
              'Provider is not selected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.provider_tab_details ?? 'Manage')),
      body: ListView(
        children: [
          _Tile(
            icon: Icons.design_services_outlined,
            title: t.provider_manage_services_title ?? 'Services',
            subtitle: t.provider_manage_services_subtitle ??
                'Create, edit, and organize services',
            onTap: () {
              if (providerId == null) return _needProvider(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProviderServicesScreen(providerId: providerId!),
                ),
              );
            },
          ),
          _Tile(
            icon: Icons.business_outlined,
            title: t.provider_manage_business_title ?? 'Business info',
            subtitle: t.provider_manage_business_subtitle ??
                'Name, contacts, address, about',
            onTap: () {
              if (providerId == null) return _needProvider(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProviderSettingsScreen(providerId: providerId!),
                ),
              );
            },
          ),
          _Tile(
            icon: Icons.group_outlined,
            title: t.provider_manage_staff_title ?? 'Staff',
            subtitle:
                t.provider_manage_staff_subtitle ?? 'Invite and manage workers',
            onTap: () {
              if (providerId == null) return _needProvider(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProviderStaffListScreen(providerId: providerId!),
                ),
              );
            },
          ),
          _Tile(
            icon: Icons.schedule_outlined,
            title: t.provider_manage_hours_title ?? 'Working hours',
            subtitle: t.provider_manage_hours_subtitle ??
                'Set business schedule and breaks',
            onTap: () {
              if (providerId == null) return _needProvider(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProviderBusinessHoursScreen(providerId: providerId!),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: (subtitle == null) ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
