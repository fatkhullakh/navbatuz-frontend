// lib/screens/provider/settings/business/provider_location_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/api_service.dart';
import 'provider_location_picker_screen.dart';

class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);
}

class ProviderLocationScreen extends StatefulWidget {
  final String providerId;
  const ProviderLocationScreen({super.key, required this.providerId});

  @override
  State<ProviderLocationScreen> createState() => _ProviderLocationScreenState();
}

class _ProviderLocationScreenState extends State<ProviderLocationScreen> {
  final _dio = ApiService.client;

  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();

  double? _lat;
  double? _lng;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r =
          await _dio.get('/providers/admin/${widget.providerId}/location');
      final m = (r.data as Map).cast<String, dynamic>();

      _addr1.text = (m['addressLine1'] ?? '').toString();
      _addr2.text = (m['addressLine2'] ?? '').toString();
      _district.text = (m['district'] ?? '').toString();
      _city.text = (m['city'] ?? '').toString();
      _postal.text = (m['postalCode'] ?? '').toString();

      _lat = (m['latitude'] as num?)?.toDouble();
      _lng = (m['longitude'] as num?)?.toDouble();
    } catch (_) {
      // leave empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.push<(double, double)?>(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderLocationPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
        ),
      ),
    );
    if (picked != null && mounted) {
      final (lat, lng) = picked;
      setState(() {
        _lat = lat;
        _lng = lng;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.location_pinned ??
                'Location pinned')),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.pick_on_map_first ??
                'Please pin location on the map')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'addressLine1': _addr1.text.trim().isEmpty ? null : _addr1.text.trim(),
        'addressLine2': _addr2.text.trim().isEmpty ? null : _addr2.text.trim(),
        'district':
            _district.text.trim().isEmpty ? null : _district.text.trim(),
        'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
        'countryIso2': 'UZ',
        'postalCode': _postal.text.trim().isEmpty ? null : _postal.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
      };
      await _dio.put('/providers/${widget.providerId}/location', data: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saved ?? 'Saved')),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('HTTP $code: $body')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _addr1.dispose();
    _addr2.dispose();
    _district.dispose();
    _city.dispose();
    _postal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _Brand.bg,
      appBar: AppBar(
        title: Text(t.business_location_tab ?? 'Business location'),
        backgroundColor: Colors.white,
        foregroundColor: _Brand.ink,
        elevation: 0.5,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            labelStyle: const TextStyle(color: _Brand.subtle),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _Brand.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _Brand.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _Brand.primary, width: 1.4),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SectionCard(
              title: t.address ?? 'Address',
              child: Column(
                children: [
                  TextField(
                    controller: _addr1,
                    decoration: InputDecoration(
                      labelText: t.address_line1 ?? 'Address line 1',
                      prefixIcon: const Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addr2,
                    decoration: InputDecoration(
                      labelText: t.address_line2 ?? 'Address line 2',
                      prefixIcon: const Icon(Icons.more_horiz),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _district,
                          decoration: InputDecoration(
                            labelText: t.district ?? 'District',
                            prefixIcon: const Icon(Icons.hexagon_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _city,
                          decoration: InputDecoration(
                            labelText: t.city ?? 'City',
                            prefixIcon:
                                const Icon(Icons.location_city_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _postal,
                    decoration: InputDecoration(
                      labelText: t.postal_code ?? 'Postal code',
                      prefixIcon: const Icon(Icons.local_post_office_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: t.map_pin ?? 'Map pin',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MapPreview(lat: _lat, lng: _lng, onPick: _pickOnMap),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _CoordField(
                              label: 'Lat',
                              value: _lat,
                              icon: Icons.explore_outlined)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _CoordField(
                              label: 'Lng',
                              value: _lng,
                              icon: Icons.explore_outlined)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_lat == null || _lng == null)
                        ? (t.not_set ?? 'Not set')
                        : '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                    style: const TextStyle(color: _Brand.subtle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Brand.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : Text(t.save ?? 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== UI bits ======

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: _Brand.ink)),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  final double? lat;
  final double? lng;
  final VoidCallback onPick;

  const _MapPreview(
      {required this.lat, required this.lng, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hasPin = lat != null && lng != null;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Brand.border),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(
              hasPin ? Icons.location_on_rounded : Icons.public_outlined,
              size: 48,
              color: hasPin ? _Brand.primary : _Brand.subtle,
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _Brand.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onPressed: onPick,
              icon: const Icon(Icons.pin_drop_outlined, size: 18),
              label: Text(
                  AppLocalizations.of(context)!.pick_on_map ?? 'Pick on map'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  final String label;
  final double? value;
  final IconData icon;

  const _CoordField(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final txt = (value == null) ? '—' : value!.toStringAsFixed(6);
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: Text(txt, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
