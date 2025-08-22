import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../services/api_service.dart';
import 'map_pin_picker_screen.dart';
import 'provider_location_picker_screen.dart';

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
      // no location yet; leave empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.push<(double, double)?>(
      context,
      MaterialPageRoute(
        builder: (_) => const ProviderLocationPickerScreen(
          // pass stored coords if you have them
          initialLat: null, // or current provider lat
          initialLng: null, // or current provider lng
        ),
      ),
    );
    if (picked != null) {
      final (lat, lng) = picked; // ✅ plain tuple
      // update your form fields / send to backend
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on map')),
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
        const SnackBar(content: Text('Location saved')),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed ${e.response?.statusCode}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Business location')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          TextField(
            controller: _addr1,
            decoration: const InputDecoration(labelText: 'Address line 1'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addr2,
            decoration: const InputDecoration(labelText: 'Address line 2'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _district,
            decoration: const InputDecoration(labelText: 'District'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _postal,
            decoration: const InputDecoration(labelText: 'Postal code'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pinned coordinates'),
            subtitle: Text(
              (_lat == null || _lng == null) ? 'Not set' : '$_lat, $_lng',
            ),
            trailing: FilledButton.icon(
              onPressed: _pickOnMap,
              icon: const Icon(Icons.pin_drop_outlined),
              label: const Text('Pick on map'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ),
      ),
    );
  }
}
