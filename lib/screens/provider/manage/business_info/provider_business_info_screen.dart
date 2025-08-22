// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:geolocator/geolocator.dart';

// import '../../../../l10n/app_localizations.dart';
// import '../../../../services/api_service.dart';
// import '../../../../services/media/upload_service.dart';

// /// ===== DTOs & API =====

// class ProviderDetailsDto {
//   final String id;
//   final String name;
//   final String? description;
//   final String? category;
//   final String? email;
//   final String? phone;
//   final String? logoUrl;
//   final LocationSummaryDto? location;
//   final int? teamSize;

//   ProviderDetailsDto({
//     required this.id,
//     required this.name,
//     this.description,
//     this.category,
//     this.email,
//     this.phone,
//     this.logoUrl,
//     this.location,
//     this.teamSize,
//   });

//   factory ProviderDetailsDto.fromJson(Map<String, dynamic> j) {
//     return ProviderDetailsDto(
//       id: (j['id'] ?? '').toString(),
//       name: (j['name'] ?? '').toString(),
//       description: j['description']?.toString(),
//       category: j['category']?.toString(),
//       email: j['email']?.toString(),
//       phone: j['phoneNumber']?.toString(),
//       logoUrl: j['logoUrl']?.toString(),
//       teamSize: (j['teamSize'] is num) ? (j['teamSize'] as num).toInt() : null,
//       location: (j['location'] is Map)
//           ? LocationSummaryDto.fromJson(
//               Map<String, dynamic>.from(j['location']))
//           : null,
//     );
//   }
// }

// class LocationSummaryDto {
//   final String id;
//   final String? addressLine1;
//   final String? city;
//   final String? countryIso2;
//   LocationSummaryDto({
//     required this.id,
//     this.addressLine1,
//     this.city,
//     this.countryIso2,
//   });
//   factory LocationSummaryDto.fromJson(Map<String, dynamic> j) =>
//       LocationSummaryDto(
//         id: (j['id'] ?? '').toString(),
//         addressLine1: j['addressLine1']?.toString(),
//         city: j['city']?.toString(),
//         countryIso2: j['countryIso2']?.toString(),
//       );
// }

// class LocationRequestDto {
//   String? addressLine1;
//   String? addressLine2;
//   String? district;
//   String? city;
//   String? countryIso2;
//   String? postalCode;
//   double? latitude;
//   double? longitude;
//   String? provider; // external provider name (maps)
//   String? providerPlaceId;

//   Map<String, dynamic> toJson() => {
//         'addressLine1': addressLine1,
//         'addressLine2': addressLine2,
//         'district': district,
//         'city': city,
//         'countryIso2': countryIso2,
//         'postalCode': postalCode,
//         'latitude': latitude,
//         'longitude': longitude,
//         'provider': provider,
//         'providerPlaceId': providerPlaceId,
//       }..removeWhere((_, v) => v == null);
// }

// class ProviderUpdateReq {
//   String name;
//   String? description;
//   String? category;
//   int? teamSize;
//   String? email;
//   String? phoneNumber;

//   ProviderUpdateReq({
//     required this.name,
//     this.description,
//     this.category,
//     this.teamSize,
//     this.email,
//     this.phoneNumber,
//   });

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'description': description,
//         'category': category,
//         'teamSize': teamSize,
//         'email': email,
//         'phoneNumber': phoneNumber,
//       }..removeWhere((_, v) => v == null);
// }

// class ProviderOwnerApi {
//   final Dio _dio = ApiService.client;

//   Future<ProviderDetailsDto> fetchDetails(String providerId) async {
//     final r = await _dio.get('/providers/public/$providerId/details');
//     return ProviderDetailsDto.fromJson(
//         Map<String, dynamic>.from(r.data as Map));
//     // If your endpoint is /api/providers/public/... adjust the prefix accordingly
//   }

//   Future<void> updateProvider(String id, ProviderUpdateReq req) async {
//     await _dio.put('/providers/$id', data: req.toJson());
//   }

//   Future<void> updateLocation(String id, LocationRequestDto loc) async {
//     await _dio.put('/providers/$id/location', data: loc.toJson());
//   }

//   Future<void> setLogo(String id, String? url) async {
//     await _dio.put('/providers/$id/logo', data: {'url': url});
//   }
// }

// /// ===== Screen =====

// class ProviderBusinessInfoScreen extends StatefulWidget {
//   final String providerId;
//   const ProviderBusinessInfoScreen({super.key, required this.providerId});

//   @override
//   State<ProviderBusinessInfoScreen> createState() =>
//       _ProviderBusinessInfoScreenState();
// }

// class _ProviderBusinessInfoScreenState
//     extends State<ProviderBusinessInfoScreen> {
//   final _api = ProviderOwnerApi();
//   final _uploads = UploadService();

//   // form ctrls
//   final _name = TextEditingController();
//   final _email = TextEditingController();
//   final _phone = TextEditingController();
//   final _about = TextEditingController();
//   final _teamSize = TextEditingController();
//   String _category = 'CLINIC';

//   // location local model
//   final _loc = LocationRequestDto();
//   bool _locDirty = false;

//   // logo
//   String? _logoUrl;

//   // state
//   late Future<void> _bootstrap;
//   String _err = '';
//   bool _saving = false;

//   // categories (align to your backend enum)
//   static const List<Map<String, String>> _categories = [
//     {'id': 'BARBERSHOP', 'name': 'barbershop'},
//     {'id': 'DENTAL', 'name': 'dental'},
//     {'id': 'CLINIC', 'name': 'clinic'},
//     {'id': 'SPA', 'name': 'spa'},
//     {'id': 'GYM', 'name': 'gym'},
//     {'id': 'NAIL_SALON', 'name': 'nail salon'},
//     {'id': 'BEAUTY_CLINIC', 'name': 'beauty clinic'},
//     {'id': 'TATTOO_STUDIO', 'name': 'tattoo studio'},
//     {'id': 'MASSAGE_CENTER', 'name': 'massage center'},
//     {'id': 'PHYSIOTHERAPY_CLINIC', 'name': 'physiotherapy clinic'},
//     {'id': 'MAKEUP_STUDIO', 'name': 'makeup studio'},
//     {'id': 'OTHER', 'name': 'other'},
//   ];

//   final _formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//     _bootstrap = _load();
//   }

//   Future<void> _load() async {
//     _err = '';
//     try {
//       final dto = await _api.fetchDetails(widget.providerId);

//       _name.text = dto.name;
//       _about.text = dto.description ?? '';
//       _email.text = dto.email ?? '';
//       _phone.text = dto.phone ?? '';
//       _logoUrl = dto.logoUrl;
//       _category = dto.category ?? _category;
//       _teamSize.text = (dto.teamSize ?? '').toString();

//       // location -> editable model
//       _loc
//         ..addressLine1 = dto.location?.addressLine1
//         ..city = dto.location?.city
//         ..countryIso2 = dto.location?.countryIso2 ?? 'UZ';

//       if (mounted) setState(() {});
//     } catch (e) {
//       _err = e.toString();
//       if (mounted) setState(() {});
//     }
//   }

//   Future<void> _refresh() async {
//     final fut = _load();
//     if (!mounted) return;
//     setState(() => _bootstrap = fut);
//     await fut;
//   }

//   // ===== Logo =====

//   Future<void> _pickLogo(AppLocalizations t) async {
//     final img = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 90,
//       maxWidth: 1024,
//     );
//     if (img == null) return;

//     try {
//       // Upload -> get URL
//       final url = await _uploads.uploadProviderLogo(
//         providerId: widget.providerId,
//         filePath: img.path,
//       );
//       // Save URL
//       await _api.setLogo(widget.providerId, url);
//       if (!mounted) return;
//       setState(() => _logoUrl = url);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(_safe(t, t.image_updated, 'Image updated'))),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text(_safe(t, t.error_upload_image, 'Upload failed'))),
//       );
//     }
//   }

//   Future<void> _removeLogo(AppLocalizations t) async {
//     try {
//       await _api.setLogo(widget.providerId, null);
//       if (!mounted) return;
//       setState(() => _logoUrl = null);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(_safe(t, t.image_removed, 'Image removed'))),
//       );
//     } catch (_) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text(_safe(t, t.error_remove_image, 'Remove failed'))),
//       );
//     }
//   }

//   // ===== Location bottom sheet (structured + current location) =====

//   Future<void> _editLocation(AppLocalizations t) async {
//     final addr1 = TextEditingController(text: _loc.addressLine1 ?? '');
//     final addr2 = TextEditingController(text: _loc.addressLine2 ?? '');
//     final district = TextEditingController(text: _loc.district ?? '');
//     final city = TextEditingController(text: _loc.city ?? '');
//     final country = TextEditingController(text: _loc.countryIso2 ?? 'UZ');
//     final postal = TextEditingController(text: _loc.postalCode ?? '');
//     final latCtrl = TextEditingController(
//         text: _loc.latitude == null ? '' : _loc.latitude!.toStringAsFixed(6));
//     final lngCtrl = TextEditingController(
//         text: _loc.longitude == null ? '' : _loc.longitude!.toStringAsFixed(6));

//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       showDragHandle: true,
//       builder: (ctx) {
//         final insets = MediaQuery.of(ctx).viewInsets;
//         return SafeArea(
//           top: false,
//           child: Padding(
//             padding: EdgeInsets.fromLTRB(16, 12, 16, insets.bottom + 16),
//             child: StatefulBuilder(builder: (ctx, setSheet) {
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     _safe(t, t.location, 'Location'),
//                     style: const TextStyle(fontWeight: FontWeight.w700),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: addr1,
//                     decoration: InputDecoration(
//                       labelText: _safe(t, t.address_line1, 'Address line 1'),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: addr2,
//                     decoration: InputDecoration(
//                       labelText: _safe(t, t.address_line2, 'Address line 2'),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: district,
//                     decoration: InputDecoration(
//                       labelText: _safe(t, t.district, 'District'),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: TextField(
//                           controller: city,
//                           decoration: InputDecoration(
//                             labelText: _safe(t, t.city, 'City'),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: TextField(
//                           controller: country,
//                           textCapitalization: TextCapitalization.characters,
//                           decoration: InputDecoration(
//                             labelText: _safe(t, t.country_iso2, 'Country ISO2'),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: TextField(
//                           controller: postal,
//                           decoration: InputDecoration(
//                             labelText: _safe(t, t.postal_code, 'Postal code'),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: latCtrl,
//                           keyboardType: const TextInputType.numberWithOptions(
//                               decimal: true, signed: true),
//                           decoration: const InputDecoration(labelText: 'Lat'),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: TextField(
//                           controller: lngCtrl,
//                           keyboardType: const TextInputType.numberWithOptions(
//                               decimal: true, signed: true),
//                           decoration: const InputDecoration(labelText: 'Lng'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: TextButton.icon(
//                       icon: const Icon(CupertinoIcons.location),
//                       onPressed: () async {
//                         try {
//                           final perm = await Geolocator.checkPermission();
//                           if (perm == LocationPermission.denied ||
//                               perm == LocationPermission.deniedForever) {
//                             final asked = await Geolocator.requestPermission();
//                             if (asked == LocationPermission.denied ||
//                                 asked == LocationPermission.deniedForever) {
//                               return;
//                             }
//                           }
//                           final pos = await Geolocator.getCurrentPosition(
//                               desiredAccuracy: LocationAccuracy.high);
//                           latCtrl.text = pos.latitude.toStringAsFixed(6);
//                           lngCtrl.text = pos.longitude.toStringAsFixed(6);
//                           setSheet(() {});
//                         } catch (_) {
//                           if (!mounted) return;
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(_safe(
//                                   t,
//                                   t.location_permission_needed,
//                                   'Location permission required')),
//                             ),
//                           );
//                         }
//                       },
//                       label: Text(_safe(
//                           t, t.use_current_location, 'Use current location')),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () => Navigator.of(ctx).pop(),
//                           child: Text(_safe(t, t.action_cancel, 'Cancel')),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: FilledButton(
//                           onPressed: () {
//                             // commit to local model
//                             _loc
//                               ..addressLine1 = _nz(addr1.text)
//                               ..addressLine2 = _nz(addr2.text)
//                               ..district = _nz(district.text)
//                               ..city = _nz(city.text)
//                               ..countryIso2 = _nz(country.text)?.toUpperCase()
//                               ..postalCode = _nz(postal.text)
//                               ..latitude = double.tryParse(
//                                   latCtrl.text.replaceAll(',', '.'))
//                               ..longitude = double.tryParse(
//                                   lngCtrl.text.replaceAll(',', '.'));
//                             _locDirty = true;
//                             Navigator.of(ctx).pop();
//                           },
//                           child: Text(_safe(t, t.apply, 'Apply')),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               );
//             }),
//           ),
//         );
//       },
//     );
//   }

//   // ===== Save main info =====

//   Future<void> _save(AppLocalizations t) async {
//     if (_saving) return;
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _saving = true);
//     try {
//       final req = ProviderUpdateReq(
//         name: _name.text.trim(),
//         description: _about.text.trim().isEmpty ? null : _about.text.trim(),
//         category: _category,
//         teamSize: _teamSize.text.trim().isEmpty
//             ? null
//             : int.tryParse(_teamSize.text.trim()),
//         email: _email.text.trim().isEmpty ? null : _email.text.trim(),
//         phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
//       );

//       await _api.updateProvider(widget.providerId, req);

//       if (_locDirty) {
//         // minimal validation for lat/lng when one present
//         if ((_loc.latitude == null) != (_loc.longitude == null)) {
//           throw Exception('Both latitude and longitude are required.');
//         }
//         await _api.updateLocation(widget.providerId, _loc);
//         _locDirty = false;
//       }

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(_safe(t, t.saved, 'Saved'))),
//       );
//       Navigator.pop(context, true);
//     } on DioException catch (e) {
//       if (!mounted) return;
//       final code = e.response?.statusCode;
//       final msg = e.response?.data?.toString() ?? e.message ?? 'Error';
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Failed $code: $msg')));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Failed: $e')));
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   // ===== UI =====

//   @override
//   Widget build(BuildContext context) {
//     final t = AppLocalizations.of(context)!;

//     String? logo() {
//       final raw = (_logoUrl ?? '').trim();
//       if (raw.isEmpty) return null;
//       final n = ApiService.normalizeMediaUrl(raw);
//       final u = (n ?? raw).trim();
//       return u.isEmpty ? null : u;
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text(_safe(t, t.business_info, 'Business info'))),
//       body: FutureBuilder<void>(
//         future: _bootstrap,
//         builder: (context, snap) {
//           if (snap.connectionState == ConnectionState.waiting &&
//               (_name.text.isEmpty && _err.isEmpty)) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (_err.isNotEmpty) {
//             return _ErrorBox(text: _err, onRetry: _refresh, t: t);
//           }

//           final l = logo();

//           return Form(
//             key: _formKey,
//             child: ListView(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//               children: [
//                 // Logo card
//                 Card(
//                   elevation: 0,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 14, horizontal: 14),
//                     child: Row(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: Container(
//                             width: 72,
//                             height: 72,
//                             color: const Color(0xFFF2F4F7),
//                             child: (l == null)
//                                 ? const Icon(
//                                     Icons.store_mall_directory_outlined,
//                                     size: 36)
//                                 : Image.network(
//                                     l,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (_, __, ___) =>
//                                         const Icon(Icons.broken_image_outlined),
//                                   ),
//                           ),
//                         ),
//                         const SizedBox(width: 14),
//                         Expanded(
//                           child: Wrap(
//                             spacing: 8,
//                             runSpacing: 8,
//                             children: [
//                               FilledButton.icon(
//                                 onPressed: () => _pickLogo(t),
//                                 icon: const Icon(Icons.photo_library_outlined),
//                                 label: Text(
//                                     _safe(t, t.change_logo, 'Change logo')),
//                               ),
//                               OutlinedButton.icon(
//                                 onPressed:
//                                     l == null ? null : () => _removeLogo(t),
//                                 icon: const Icon(Icons.delete_outline),
//                                 label: Text(_safe(t, t.remove_logo, 'Remove')),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),

//                 // Main details
//                 _SectionHeader(
//                     text: _safe(t, t.main_details_required, 'Main details')),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: _name,
//                   decoration: InputDecoration(
//                       labelText: _safe(t, t.provider_name, 'Name')),
//                   validator: (v) => (v == null || v.trim().isEmpty)
//                       ? _safe(t, t.required, 'Required')
//                       : null,
//                 ),
//                 const SizedBox(height: 8),
//                 DropdownButtonFormField<String>(
//                   value: _category,
//                   decoration: InputDecoration(
//                       labelText: _safe(t, t.category, 'Category')),
//                   items: _categories
//                       .map((c) => DropdownMenuItem(
//                             value: c['id'],
//                             child: Text(c['name']!),
//                           ))
//                       .toList(),
//                   onChanged: (v) => setState(() => _category = v ?? _category),
//                 ),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: _teamSize,
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(
//                       labelText: _safe(t, t.team_size, 'Team size')),
//                 ),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: _about,
//                   minLines: 3,
//                   maxLines: 6,
//                   decoration:
//                       InputDecoration(labelText: _safe(t, t.about, 'About')),
//                 ),

//                 const SizedBox(height: 16),
//                 _SectionHeader(text: _safe(t, t.contact, 'Contact')),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: _email,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration:
//                       InputDecoration(labelText: _safe(t, t.email, 'Email')),
//                 ),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: _phone,
//                   keyboardType: TextInputType.phone,
//                   decoration:
//                       InputDecoration(labelText: _safe(t, t.phone, 'Phone')),
//                 ),

//                 const SizedBox(height: 16),
//                 _SectionHeader(text: _safe(t, t.location, 'Location')),
//                 const SizedBox(height: 8),
//                 Card(
//                   elevation: 0,
//                   child: ListTile(
//                     leading: const Icon(CupertinoIcons.location),
//                     title: Text(_locationTitle()),
//                     subtitle: Text(_locationSubtitle()),
//                     trailing: FilledButton(
//                       onPressed: () => _editLocation(t),
//                       child: Text(_safe(t, t.edit, 'Edit')),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 20),
//                 SizedBox(
//                   height: 48,
//                   child: FilledButton(
//                     onPressed: _saving ? null : () => _save(t),
//                     child: _saving
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2))
//                         : Text(_safe(t, t.action_save, 'Save')),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   String _locationTitle() {
//     final parts = [
//       _loc.addressLine1,
//       _loc.city,
//     ]
//         .where((e) => e != null && e!.trim().isNotEmpty)
//         .map((e) => e!.trim())
//         .toList();
//     if (parts.isEmpty) return 'No address yet';
//     return parts.join(', ');
//   }

//   String _locationSubtitle() {
//     final buf = StringBuffer();
//     if (_loc.countryIso2 != null && _loc.countryIso2!.isNotEmpty) {
//       buf.write((_loc.countryIso2!).toUpperCase());
//     }
//     if (_loc.postalCode != null && _loc.postalCode!.isNotEmpty) {
//       if (buf.isNotEmpty) buf.write(' • ');
//       buf.write(_loc.postalCode);
//     }
//     if (_loc.latitude != null && _loc.longitude != null) {
//       if (buf.isNotEmpty) buf.write(' • ');
//       buf.write(
//           '${_loc.latitude!.toStringAsFixed(5)}, ${_loc.longitude!.toStringAsFixed(5)}');
//     }
//     return buf.isEmpty ? '—' : buf.toString();
//   }

//   String _safe(AppLocalizations t, String? maybe, String fallback) =>
//       maybe ?? fallback;
//   String? _nz(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
// }

// class _SectionHeader extends StatelessWidget {
//   final String text;
//   const _SectionHeader({required this.text});
//   @override
//   Widget build(BuildContext context) => Text(
//         text,
//         style: const TextStyle(fontWeight: FontWeight.w700),
//       );
// }

// class _ErrorBox extends StatelessWidget {
//   final String text;
//   final Future<void> Function() onRetry;
//   final AppLocalizations t;
//   const _ErrorBox({required this.text, required this.onRetry, required this.t});
//   @override
//   Widget build(BuildContext context) => Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(text, textAlign: TextAlign.center),
//               const SizedBox(height: 12),
//               OutlinedButton(
//                 onPressed: () => onRetry(),
//                 child: Text(_safe(t, t.action_retry, 'Retry')),
//               ),
//             ],
//           ),
//         ),
//       );

//   static String _safe(AppLocalizations t, String? maybe, String fallback) =>
//       maybe ?? fallback;
// }
