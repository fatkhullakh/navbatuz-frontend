import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPinPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPinPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPinPickerScreen> createState() => _MapPinPickerScreenState();
}

class _MapPinPickerScreenState extends State<MapPinPickerScreen> {
  final _c = Completer<GoogleMapController>();
  CameraPosition? _lastCam;
  bool _popped = false;
  bool _myLocEnabled = false;

  LatLng _fallback = const LatLng(41.311081, 69.240562); // Tashkent

  LatLng get _startLatLng => LatLng(widget.initialLat ?? _fallback.latitude,
      widget.initialLng ?? _fallback.longitude);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Try to get user location; if granted, move camera there.
    try {
      final granted = await _ensureLocationPermission();
      if (!mounted) return;
      if (granted) {
        final pos = await Geolocator.getCurrentPosition();
        _fallback = LatLng(pos.latitude, pos.longitude);
        _myLocEnabled = true;
        final controller = await _c.future;
        await controller
            .animateCamera(CameraUpdate.newLatLngZoom(_fallback, 15));
      }
    } catch (_) {
      // keep fallback
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _confirm() async {
    if (_popped) return;
    _popped = true;
    final center = _lastCam?.target ?? _startLatLng;
    // Return a **positional** record:
    Navigator.of(context).pop((center.latitude, center.longitude));
  }

  Future<void> _goToMyLocation() async {
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) return;
      final pos = await Geolocator.getCurrentPosition();
      final controller = await _c.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        16,
      ));
      if (mounted) setState(() => _myLocEnabled = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final initial = CameraPosition(target: _startLatLng, zoom: 15);

    return Scaffold(
      appBar: AppBar(title: const Text('Pick location')),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initial,
            onMapCreated: (controller) async {
              if (!_c.isCompleted) _c.complete(controller);
              // If we have a saved initial different from fallback, ensure we start there:
              if ((widget.initialLat != null && widget.initialLng != null)) {
                await controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_startLatLng, 15),
                );
              }
            },
            onCameraMove: (pos) => _lastCam = pos,
            myLocationEnabled: _myLocEnabled,
            myLocationButtonEnabled: false, // we show our own
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),

          // Center pin
          IgnorePointer(
            child: Center(
              child: Icon(Icons.location_pin, size: 48, color: Colors.red),
            ),
          ),

          // My location FAB
          Positioned(
            right: 16,
            bottom: 90,
            child: FloatingActionButton(
              mini: true,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check),
                label: const Text('Confirm'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
