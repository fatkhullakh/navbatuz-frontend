// lib/screens/provider/settings/business/provider_location_picker_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart' as ymap;

class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);
}

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
  ymap.YandexMapController? _controller;
  bool _mapReady = false;
  bool _permDenied = false;

  // Tashkent fallback
  static const _fallback =
      ymap.Point(latitude: 41.311081, longitude: 69.240562);
  late ymap.Point _picked; // current pin (camera center)

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _picked = (widget.initialLat != null && widget.initialLng != null)
        ? ymap.Point(
            latitude: widget.initialLat!, longitude: widget.initialLng!)
        : _fallback;
    _ensureLocationPermission();
  }

  Future<void> _ensureLocationPermission() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    setState(() {
      _permDenied = (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever);
    });
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final target =
          ymap.Point(latitude: pos.latitude, longitude: pos.longitude);
      await _controller?.moveCamera(
        ymap.CameraUpdate.newCameraPosition(
          ymap.CameraPosition(target: target, zoom: 16),
        ),
        animation: const ymap.MapAnimation(
          type: ymap.MapAnimationType.smooth,
          duration: 0.35,
        ),
      );
    } catch (_) {/* ignore */}
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    Navigator.of(context).pop((_picked.latitude, _picked.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const bgCard = Color(0xFFF6F8FC);
    const border = Color(0xFFE6ECF2);
    final subtle = Colors.black.withOpacity(0.6);

    return Scaffold(
      body: Stack(
        children: [
          // MAP
          Positioned.fill(
            child: ymap.YandexMap(
              onMapCreated: (c) async {
                _controller = c;
                await _controller?.moveCamera(
                  ymap.CameraUpdate.newCameraPosition(
                    ymap.CameraPosition(target: _picked, zoom: 15),
                  ),
                );
                setState(() => _mapReady = true);
              },
              onMapTap: (pt) {
                setState(() => _picked = pt);
              },
              onCameraPositionChanged: (ymap.CameraPosition pos,
                  ymap.CameraUpdateReason _, bool finished) {
                _picked = pos.target;
                if (finished && mounted) setState(() {});
              },
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              logoAlignment: const ymap.MapAlignment(
                horizontal: ymap.HorizontalAlignment.left,
                vertical: ymap.VerticalAlignment.bottom,
              ),
            ),
          ),

          // FROSTED HEADER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Pick location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'My location',
                          child: IconButton.filledTonal(
                            style: const ButtonStyle(
                              padding:
                                  WidgetStatePropertyAll(EdgeInsets.all(8)),
                            ),
                            onPressed: _goToCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // CENTER PIN
          IgnorePointer(
            child: Center(
              child: Icon(Icons.location_pin, size: 48, color: cs.primary),
            ),
          ),

          // LOADING
          if (!_mapReady)
            const Positioned.fill(
              child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator())),
            ),

          // PERMISSION BANNER
          if (_permDenied)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 64, 12, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE8B3)),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    'Location permission denied. You can still move the map and drop a pin manually.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),

          // ACTION BAR
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 12,
                          offset: Offset(0, 6))
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_picked.latitude.toStringAsFixed(6)}, ${_picked.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: subtle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Center to my location',
                            onPressed: _goToCurrentLocation,
                            icon: const Icon(Icons.my_location),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _Brand.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Use this location'),
                          onPressed: _saving ? null : _confirm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
