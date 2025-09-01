// lib/screens/onboarding/location_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/models/onboarding_data.dart';
import 'package:frontend/screens/onboarding/onboarding_ui.dart';
import 'package:frontend/screens/onboarding/role_screen.dart';
import 'package:frontend/screens/provider/manage/business_info/location/provider_location_picker_screen.dart';

class ProviderBusinessLocationScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const ProviderBusinessLocationScreen(
      {super.key, required this.onboardingData});

  @override
  State<ProviderBusinessLocationScreen> createState() =>
      _ProviderBusinessLocationScreenState();
}

class _ProviderBusinessLocationScreenState
    extends State<ProviderBusinessLocationScreen> {
  double? _lat;
  double? _lng;

  String get _lang {
    final picked = (widget.onboardingData.languageCode ?? '').toLowerCase();
    if (picked == 'ru' || picked == 'uz' || picked == 'en') return picked;
    final ctx = Localizations.localeOf(context).languageCode.toLowerCase();
    if (ctx == 'ru' || ctx == 'uz') return ctx;
    return 'en';
  }

  // ---- localized strings (business location; no skipping) ----
  String get _stepLabel => switch (_lang) {
        'ru' => 'Шаг 4 из 5',
        'uz' => '4-qadam / 5',
        _ => 'Step 4 of 5',
      };
  String get _title => switch (_lang) {
        'ru' => 'Укажите местоположение бизнеса',
        'uz' => 'Biznes joylashuvini kiriting',
        _ => 'Set your business location',
      };
  String get _subtitle => switch (_lang) {
        'ru' =>
          'Закрепите точку на карте — клиенты увидят вас и смогут построить маршрут.',
        'uz' =>
          'Xaritada pin qo‘ying — mijozlar sizni ko‘radi va yo‘l topa oladi.',
        _ =>
          'Drop a pin on the map so customers can find you and get directions.',
      };
  String get _pickOnMap => switch (_lang) {
        'ru' => 'Выбрать на карте',
        'uz' => 'Xaritadan tanlash',
        _ => 'Choose on map',
      };
  String get _continue => switch (_lang) {
        'ru' => 'Продолжить',
        'uz' => 'Davom etish',
        _ => 'Continue',
      };
  String get _savedSnack => switch (_lang) {
        'ru' => 'Локация сохранена',
        'uz' => 'Joylashuv saqlandi',
        _ => 'Location saved',
      };
  String selectedCoords(double lat, double lng) => switch (_lang) {
        'ru' => 'Выбрано: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        'uz' =>
          'Tanlandi: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        _ => 'Selected: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      };
  String get _editPin => switch (_lang) {
        'ru' => 'Изменить пин',
        'uz' => 'Pinni tahrirlash',
        _ => 'Edit pin',
      };

  @override
  void initState() {
    super.initState();
    _lat = widget.onboardingData.lat;
    _lng = widget.onboardingData.lng;
  }

  Future<void> _pickOnMapFlow() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderLocationPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
        ),
      ),
    );

    double? lat;
    double? lng;
    if (res is (double, double)) {
      final (a, b) = res;
      lat = a;
      lng = b;
    } else if (res is List &&
        res.length == 2 &&
        res[0] is double &&
        res[1] is double) {
      lat = res[0] as double;
      lng = res[1] as double;
    }

    if (lat != null && lng != null) {
      setState(() {
        _lat = lat;
        _lng = lng;
      });
      widget.onboardingData
        ..lat = lat
        ..lng = lng;

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_savedSnack)));
      }
    }
  }

  void _goNext() {
    if (_lat == null || _lng == null) return;

    // Prefer providerLat/providerLng going forward (you updated the model).
    widget.onboardingData
      ..providerLat = _lat
      ..providerLng = _lng;

    Navigator.of(context, rootNavigator: true).pushNamed(
      '/onboarding/provider/address',
      arguments: widget.onboardingData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = _lat != null && _lng != null;

    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(stepLabel: _stepLabel, progress: 0.8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            H1(_title),
            const SizedBox(height: 8),
            Sub(_subtitle),

            const SizedBox(height: 24),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Brand.accentSoft,
                border: Border.all(color: Brand.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                  child: Icon(Icons.map, size: 56, color: Brand.primary)),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _pickOnMapFlow,
                icon: const Icon(Icons.location_on),
                label: Text(_pickOnMap,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),

            if (hasPin) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Brand.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, color: Brand.subtle),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedCoords(_lat!, _lng!),
                        style: const TextStyle(
                            color: Brand.ink, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickOnMapFlow,
                      icon: const Icon(Icons.edit_location_alt, size: 18),
                      label: Text(_editPin),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Mandatory step: Continue only when a pin is set
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: hasPin ? _goNext : null,
                child: Text(_continue,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
