import 'package:flutter/material.dart';
import 'package:frontend/screens/provider/manage/business_info/business%20details/provider_business_details_screen.dart';
import 'package:frontend/screens/provider/manage/business_info/location/provider_location_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../manage/hours/provider_business_hours_screen.dart';

/* ---------- Brand ---------- */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const primarySoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const surface = Color(0xFFF6F8FC);
}

class ProviderSettingsScreen extends StatelessWidget {
  final String providerId;
  const ProviderSettingsScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    Widget tile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
    }) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _Brand.border),
        ),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _Brand.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _Brand.ink),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: (subtitle == null)
              ? null
              : Text(subtitle, style: const TextStyle(color: _Brand.subtle)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.business_settings_title ?? 'Business settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Text(
              t.business_settings_title ?? 'Business settings',
              style: const TextStyle(
                color: _Brand.ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          tile(
            icon: Icons.store_outlined,
            title: t.business_details_title ?? 'Business details',
            subtitle: t.business_details_subtitle ??
                'Name, description, email, phone, category, logo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProviderBusinessDetailsScreen(providerId: providerId),
              ),
            ),
          ),
          tile(
            icon: Icons.location_on_outlined,
            title: t.business_location_tab ?? 'Location',
            subtitle: t.location_details_title ?? 'Address and map pin',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProviderLocationScreen(providerId: providerId),
              ),
            ),
          ),
          tile(
            icon: Icons.schedule_outlined,
            title: t.working_hours ?? 'Working hours',
            subtitle: t.working_hours_subtitle ?? 'Set business hours',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProviderBusinessHoursScreen(providerId: providerId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
