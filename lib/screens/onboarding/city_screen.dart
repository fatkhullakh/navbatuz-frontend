// // lib/screens/onboarding/city_selection_screen.dart
// import 'package:flutter/material.dart';
// import '../../models/onboarding_data.dart';
// import 'onboarding_ui.dart';
// import 'location_screen.dart';

// class CitySelectionScreen extends StatefulWidget {
//   final OnboardingData onboardingData;
//   const CitySelectionScreen({super.key, required this.onboardingData});

//   @override
//   State<CitySelectionScreen> createState() => _CitySelectionScreenState();
// }

// class _CitySelectionScreenState extends State<CitySelectionScreen> {
//   String? _cityId;
//   String? _districtId;

//   String get lang => widget.onboardingData.languageCode ?? 'en';
//   String get country => widget.onboardingData.countryIso2 ?? 'UZ';

//   // ---- Minimal, extensible geo dataset with stable IDs (DB-safe) ----
//   static const _geo = {/* … same data you posted … */};

//   List<Map<String, dynamic>> get _cities {
//     final arr = (_geo[country]?['cities'] as List?) ?? const [];
//     return arr.cast<Map<String, dynamic>>();
//   }

//   List<Map<String, dynamic>> get _districts {
//     final city = _cities.firstWhere(
//       (c) => c['id'] == _cityId,
//       orElse: () => <String, dynamic>{'districts': []},
//     );
//     return (city['districts'] as List?)?.cast<Map<String, dynamic>>() ??
//         const [];
//   }

//   String _label(Map m) {
//     final key = lang == 'ru' ? 'ru' : (lang == 'uz' ? 'uz' : 'en');
//     return (m[key] ?? m['en']) as String;
//   }

//   void _next() {
//     final city = _cities.firstWhere((c) => c['id'] == _cityId);
//     final enCity = (city['en'] as String?) ?? '';
//     final district = _districts
//         .where((d) => d['id'] == _districtId)
//         .cast<Map<String, dynamic>?>()
//         .firstOrNull;

//     widget.onboardingData
//       ..cityCode = _cityId
//       ..cityNameEn = enCity
//       ..districtCode = district?['id'] as String?
//       ..districtNameEn = (district?['en'] as String?);

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => LocationScreen(onboardingData: widget.onboardingData),
//       ),
//     );
//   }

//   InputDecoration _dec(String label) => InputDecoration(
//         labelText: label,
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Brand.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Brand.primary, width: 1.5),
//         ),
//       );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Brand.surfaceSoft,
//       appBar: StepAppBar(
//         stepLabel: tr(lang, 'Step 3 of 5', 'Шаг 3 из 5', '3-bosqich / 5'),
//         progress: 0.6,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             H1(tr(lang, 'Choose your city', 'Выберите город',
//                 'Shaharni tanlang')),
//             const SizedBox(height: 8),
//             Sub(tr(
//               lang,
//               'We’ll show nearby providers.',
//               'Покажем ближайшие сервисы.',
//               'Yaqin xizmatlarni ko‘rsatamiz.',
//             )),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: _cityId,
//               isExpanded: true,
//               decoration: _dec(tr(lang, 'City *', 'Город *', 'Shahar *')),
//               items: _cities
//                   .map((c) => DropdownMenuItem(
//                         value: c['id'] as String,
//                         child: Text(_label(c)),
//                       ))
//                   .toList(),
//               onChanged: (v) => setState(() {
//                 _cityId = v;
//                 _districtId = null;
//               }),
//             ),
//             const SizedBox(height: 14),
//             DropdownButtonFormField<String>(
//               value: _districtId,
//               isExpanded: true,
//               decoration: _dec(tr(lang, 'District (optional)',
//                   'Район (необязательно)', 'Tuman (ixtiyoriy)')),
//               items: _districts
//                   .map((d) => DropdownMenuItem(
//                         value: d['id'] as String,
//                         child: Text(_label(d)),
//                       ))
//                   .toList(),
//               onChanged: (v) => setState(() => _districtId = v),
//             ),
//             const SizedBox(height: 28),
//             SizedBox(
//               height: 50,
//               child: FilledButton(
//                 style: FilledButton.styleFrom(
//                   backgroundColor: Brand.primary,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14)),
//                 ),
//                 onPressed: _cityId == null ? null : _next,
//                 child: Text(tr(lang, 'Continue', 'Продолжить', 'Davom etish')),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// extension<T> on Iterable<T> {
//   T? get firstOrNull => isEmpty ? null : first;
// }
