// lib/screens/provider/settings/business/provider_location_picker_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ProviderLocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const ProviderLocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<ProviderLocationPickerScreen> createState() =>
      _ProviderLocationPickerScreenState();
}

class _ProviderLocationPickerScreenState
    extends State<ProviderLocationPickerScreen> {
  final _mapCompleter = Completer<GoogleMapController>();
  bool _mapReady = false;
  bool _permDenied = false;
  bool _myLocationEnabled = false;

  // Default to Tashkent center if no stored coords
  static const _fallback = LatLng(41.311081, 69.240562);
  late LatLng _cameraTarget;

  @override
  void initState() {
    super.initState();
    _cameraTarget = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _fallback;
    _ensureLocationPermission();
  }

  Future<void> _ensureLocationPermission() async {
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever ||
        p == LocationPermission.denied) {
      setState(() {
        _permDenied = true;
        _myLocationEnabled = false;
      });
      return;
    }
    setState(() {
      _permDenied = false;
      _myLocationEnabled = true;
    });
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final ctrl = await _mapCompleter.future;
      final target = LatLng(pos.latitude, pos.longitude);
      await ctrl.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ));
    } catch (_) {
      // ignore — keep fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick location')),
      body: Stack(
        children: [
          // Make sure the map has size!
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _cameraTarget,
                zoom: 15,
              ),
              onMapCreated: (c) async {
                _mapCompleter.complete(c);
                setState(() => _mapReady = true);
              },
              myLocationEnabled: _myLocationEnabled,
              myLocationButtonEnabled: false,
              onCameraMove: (pos) => _cameraTarget = pos.target,
              compassEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          // Center pin
          IgnorePointer(
            child: Center(
              child:
                  Icon(Icons.location_pin, size: 48, color: Colors.redAccent),
            ),
          ),
          // Loading / permission banner
          if (!_mapReady)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_permDenied)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Material(
                color: Colors.amber.shade100,
                elevation: 0,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Location permission denied. You can still move the map and drop a pin manually.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          // FABs
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'gps',
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          // Confirm button
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Use this location'),
                onPressed: () async {
                  final lat = _cameraTarget.latitude;
                  final lng = _cameraTarget.longitude;
                  // Return a plain tuple (double, double) to match your caller
                  await Future<void>.delayed(Duration.zero);
                  if (!mounted) return;
                  Navigator.of(context).pop((lat, lng));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
