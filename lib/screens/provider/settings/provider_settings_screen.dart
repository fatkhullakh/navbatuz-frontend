// lib/screens/provider/settings/provider_settings_screen.dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../manage/business_info/business details/provider_business_details_screen.dart';
import '../manage/business_info/location/provider_location_screen.dart';
import '../manage/hours/provider_business_hours_screen.dart';

class ProviderSettingsScreen extends StatelessWidget {
  final String providerId;
  const ProviderSettingsScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar:
          AppBar(title: Text(t.business_settings_title ?? 'Business settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: Text(t.business_details_title ?? 'Business details'),
            subtitle: Text(t.business_details_subtitle ??
                'Name, description, email, phone, category, logo'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProviderBusinessDetailsScreen(providerId: providerId),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(t.business_location_tab ?? 'Location'),
            subtitle: Text(t.location_details_title ?? 'Address and map pin'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProviderLocationScreen(providerId: providerId),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(t.working_hours ?? 'Working hours'),
            subtitle: Text(t.working_hours_subtitle ?? 'Set business hours'),
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
