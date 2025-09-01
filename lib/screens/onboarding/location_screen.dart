import 'package:flutter/material.dart';
import 'package:frontend/screens/provider/manage/business_info/location/provider_location_picker_screen.dart';
import '../../models/onboarding_data.dart';
import 'role_screen.dart';

class LocationScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const LocationScreen({super.key, required this.onboardingData});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  double? _lat;
  double? _lng;

  String get _lang {
    final picked = (widget.onboardingData.languageCode ?? '').toLowerCase();
    if (picked == 'ru' || picked == 'uz' || picked == 'en') return picked;
    // fallback to current app locale if not set in model
    final ctx = Localizations.localeOf(context).languageCode.toLowerCase();
    if (ctx == 'ru' || ctx == 'uz') return ctx;
    return 'en';
  }

  // ---- localized strings (based on onboardingData.languageCode)
  String get _stepLabel => switch (_lang) {
        'ru' => 'Шаг 4 из 5',
        'uz' => '4-qadam / 5',
        _ => 'Step 4 of 5',
      };
  String get _title => switch (_lang) {
        'ru' => 'Разрешить доступ к вашей геолокации?',
        'uz' => 'Joylashuvingizga ruxsat berasizmi?',
        _ => 'Allow access to your location?',
      };
  String get _subtitle => switch (_lang) {
        'ru' =>
          'Мы используем геопозицию, чтобы показывать ближайшие сервисы. Это поможет получать более точные рекомендации.',
        'uz' =>
          'Yaqin atrofdagi xizmatlarni ko‘rsatish uchun geolokatsiyadan foydalanamiz. Bu aniqroq tavsiyalar olishga yordam beradi.',
        _ =>
          'We use your location to show nearby providers and better recommendations.',
      };
  String get _sharePrimary => switch (_lang) {
        'ru' => 'Поделиться геолокацией',
        'uz' => 'Joylashuvni ulashish',
        _ => 'Share my location',
      };
  String get _pickOnMap => switch (_lang) {
        'ru' => 'Указать на карте',
        'uz' => 'Xaritadan ko‘rsatish',
        _ => 'Pick on map',
      };
  String get _skip => switch (_lang) {
        'ru' => 'Пропустить',
        'uz' => 'O‘tkazib yuborish',
        _ => 'Skip',
      };
  String get _continue => switch (_lang) {
        'ru' => 'Продолжить',
        'uz' => 'Davom etish',
        _ => 'Continue',
      };
  String get _savedSnack => switch (_lang) {
        'ru' => 'Местоположение сохранено',
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
        'uz' => 'Pinni o‘zgartirish',
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
      // ..locationShared = true;

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_savedSnack)));
      }
    }
  }

  void _goNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoleSelectionScreen(onboardingData: widget.onboardingData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = _lat != null && _lng != null;

    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: _StepAppBar(stepLabel: _stepLabel, progress: 0.8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _H1(_title),
            const SizedBox(height: 8),
            _Sub(_subtitle),

            const SizedBox(height: 24),
            const _Illustration(),
            const SizedBox(height: 20),

            // Primary CTA: Share my location (appealing)
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _pickOnMapFlow, // picker handles permission & GPS
                icon: const Icon(Icons.my_location),
                label: Text(
                  _sharePrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Secondary: Pick on map
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: _Brand.border),
                ),
                onPressed: _pickOnMapFlow,
                icon: const Icon(Icons.location_on_outlined),
                label: Text(_pickOnMap),
              ),
            ),

            // Selected coordinates pill (if any)
            if (hasPin) ...[
              const SizedBox(height: 14),
              _CoordPill(
                label: selectedCoords(_lat!, _lng!),
                editLabel: _editPin,
                onEdit: _pickOnMapFlow,
              ),
            ],

            const Spacer(),

            // Continue button appears ONLY after a location is set
            if (hasPin)
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _Brand.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _goNext,
                  child: Text(
                    _continue,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

            // Tiny, low-emphasis Skip link (discourage skipping)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.6,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _Brand.subtle,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _goNext,
                    child: Text(_skip),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- UI Helpers ------------------------------ */

class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

class _Illustration extends StatelessWidget {
  const _Illustration({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: _Brand.accentSoft,
        border: Border.all(color: _Brand.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.map, size: 56, color: _Brand.primary),
      ),
    );
  }
}

class _CoordPill extends StatelessWidget {
  final String label;
  final String editLabel;
  final VoidCallback onEdit;
  const _CoordPill({
    super.key,
    required this.label,
    required this.editLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _Brand.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: _Brand.subtle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _Brand.ink,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_location_alt, size: 18),
            label: Text(editLabel),
          ),
        ],
      ),
    );
  }
}

class _StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String stepLabel;
  final double progress;
  const _StepAppBar(
      {required this.stepLabel, required this.progress, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(stepLabel,
          style: const TextStyle(color: _Brand.subtle, fontSize: 16)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: _Brand.border,
          valueColor: const AlwaysStoppedAnimation<Color>(_Brand.primary),
          minHeight: 4,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class _H1 extends StatelessWidget {
  final String text;
  const _H1(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: _Brand.ink,
        ),
      );
}

class _Sub extends StatelessWidget {
  final String text;
  const _Sub(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14, color: _Brand.subtle));
}
