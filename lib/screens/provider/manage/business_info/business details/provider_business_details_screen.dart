// lib/screens/provider/manage/business_info/business details/provider_business_details_screen.dart
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/api_service.dart';
import '../../../../../services/media/upload_service.dart';

class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);
}

class ProviderBusinessDetailsScreen extends StatefulWidget {
  final String providerId;
  const ProviderBusinessDetailsScreen({super.key, required this.providerId});

  @override
  State<ProviderBusinessDetailsScreen> createState() =>
      _ProviderBusinessDetailsScreenState();
}

class _ProviderBusinessDetailsScreenState
    extends State<ProviderBusinessDetailsScreen> {
  final Dio _dio = ApiService.client;
  final UploadService _uploads = UploadService();

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _email = TextEditingController();
  final _phoneField = TextEditingController(); // formatted with spaces

  _Country _country = _countries.first;
  String? _logoUrl;
  String? _category;

  bool _loading = true;
  bool _saving = false;

  List<_CategoryItem> _categories = const [];
  bool _catsBuilt = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = AppLocalizations.of(context)!;
    _categories = _categoriesFromArb(t);

    if (_categories.isNotEmpty &&
        (_category == null || !_categories.any((c) => c.id == _category))) {
      _category = _categories.first.id;
    }

    if (!_catsBuilt) {
      _catsBuilt = true;
      setState(() {}); // reflect localized labels
    }
  }

  Future<void> _bootstrap() async {
    try {
      await _loadDetails();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDetails() async {
    final r = await _dio.get('/providers/public/${widget.providerId}/details');
    final data = (r.data as Map).cast<String, dynamic>();

    _name.text = (data['name'] ?? '').toString();
    _desc.text = (data['description'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    final cat = (data['category'] ?? '').toString().trim();
    _category = cat.isEmpty ? _category : cat;

    final rawLogo = (data['logoUrl'] ?? '').toString().trim();
    _logoUrl = rawLogo.isEmpty ? null : rawLogo;

    final rawPhone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
    _applyIncomingPhone(rawPhone);
  }

  // ---------- ARB categories ----------
  List<_CategoryItem> _categoriesFromArb(AppLocalizations t) {
    _CategoryItem ci(String id, String? label, IconData icon) => _CategoryItem(
          id: id,
          name: (label?.trim().isNotEmpty ?? false) ? label! : id,
          icon: icon,
        );

    // Keep IDs in sync with backend Category enum
    return [
      ci('CLINIC', t.category_clinic, Icons.local_hospital_outlined),
      ci('BARBERSHOP', t.category_barbershop, Icons.content_cut),
      ci('BEAUTY_SALON', t.category_beauty_salon, Icons.brush_outlined),
      ci('SPA', t.category_spa, Icons.spa_outlined),
      ci('GYM', t.category_gym, Icons.fitness_center_outlined),
      ci('DENTAL', t.category_dental, Icons.medical_services_outlined),
      // ci('VETERINARY', t.category_veterinary, Icons.pets_outlined),
      // ci('CAR_SERVICE', t.category_car_service, Icons.car_repair_outlined),
      // ci('EDUCATION', t.category_education, Icons.school_outlined),
      ci('OTHER', t.category_other, Icons.apps_outlined),
    ];
  }

  void _applyIncomingPhone(String raw) {
    var s = raw.trim().replaceAll(' ', '');
    if (s.isEmpty) {
      _phoneField.text = '';
      return;
    }
    if (!s.startsWith('+')) {
      final guess = _countries.firstWhere(
        (c) => s.startsWith(c.dial.replaceFirst('+', '')),
        orElse: () => _countries.first,
      );
      s = '+${guess.dial.replaceFirst('+', '')}${s.substring(guess.dial.length - 1)}';
    }

    final c = _countries.firstWhere(
      (x) => s.startsWith(x.dial),
      orElse: () => _countries.first,
    );
    _country = c;

    final nsnDigits = s.replaceFirst(c.dial, '').replaceAll(RegExp(r'\D'), '');
    final truncated = nsnDigits.substring(0, min(nsnDigits.length, c.nsnMax));
    _phoneField.text = _formatDigits(truncated, c.groups);
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');
  String _fullPhoneForApi() =>
      '${_country.dial}${_digitsOnly(_phoneField.text)}';

  String _digitsRangeMsg(AppLocalizations t, int min, int max) {
    try {
      return t.phone_enter_digits_range(min, max);
    } catch (_) {
      return 'Enter $min–$max digits';
    }
  }

  String? _validateEmail(String? v, AppLocalizations t) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);
    return ok ? null : (t.invalid_email ?? 'Invalid email');
  }

  String? _validatePhone(String? _, AppLocalizations t) {
    final digits = _digitsOnly(_phoneField.text);
    if (digits.isEmpty) return null; // optional
    if (digits.length < _country.nsnMin || digits.length > _country.nsnMax) {
      return _digitsRangeMsg(t, _country.nsnMin, _country.nsnMax);
    }
    return null;
  }

  Future<void> _pickLogo() async {
    try {
      final res = await _uploads.pickAndUpload(
        scope: UploadScope.provider,
        ownerId: widget.providerId,
      );
      if (res == null) return;
      final url = ApiService.normalizeMediaUrl(res.url) ?? res.url;
      await _dio
          .put('/providers/${widget.providerId}/logo', data: {'url': url});
      if (!mounted) return;
      setState(() => _logoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.image_updated ??
                'Image updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.errorGeneric ?? 'Error'}: $e')),
      );
    }
  }

  Future<void> _removeLogo() async {
    try {
      await _dio
          .put('/providers/${widget.providerId}/logo', data: {'url': null});
      if (!mounted) return;
      setState(() => _logoUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.image_removed ??
                'Image removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.errorGeneric ?? 'Error'}: $e')),
      );
    }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (_saving) return;

    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _saving = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'category': _category,
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'phoneNumber':
            _digitsOnly(_phoneField.text).isEmpty ? null : _fullPhoneForApi(),
      }..removeWhere((_, v) => v == null);

      await _dio.put('/providers/${widget.providerId}', data: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.saved ?? 'Saved')));
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final txt = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $txt')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _email.dispose();
    _phoneField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _Brand.bg,
      appBar: AppBar(
        title: Text(t.business_details_title ?? 'Business details'),
        backgroundColor: Colors.white,
        foregroundColor: _Brand.ink,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Theme(
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
                    borderSide:
                        const BorderSide(color: _Brand.primary, width: 1.4),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // Header card with logo + actions
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.company_name_label ?? 'Business',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _Brand.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: const Color(0xFFF2F4F7),
                                    backgroundImage: (_logoUrl == null)
                                        ? null
                                        : NetworkImage(
                                            ApiService.normalizeMediaUrl(
                                                    _logoUrl!) ??
                                                _logoUrl!,
                                          ),
                                    child: (_logoUrl == null)
                                        ? const Icon(Icons.image_outlined,
                                            size: 28, color: Colors.black45)
                                        : null,
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Material(
                                      color: _Brand.primary,
                                      borderRadius: BorderRadius.circular(999),
                                      child: InkWell(
                                        onTap: _pickLogo,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                              Icons.photo_camera_outlined,
                                              color: Colors.white,
                                              size: 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _Brand.ink,
                                        side: const BorderSide(
                                            color: _Brand.border),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(
                                          Icons.photo_library_outlined),
                                      label:
                                          Text(t.change_logo ?? 'Change logo'),
                                      onPressed: _pickLogo,
                                    ),
                                    if (_logoUrl != null)
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFB42318),
                                          side: const BorderSide(
                                              color: _Brand.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(Icons.delete_outline),
                                        label: Text(t.remove_logo ?? 'Remove'),
                                        onPressed: _removeLogo,
                                      ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Main info
                    _SectionCard(
                      title: t.main_details_required ?? 'Main details',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            decoration: InputDecoration(
                              labelText: t.company_name_label ?? 'Name',
                              prefixIcon: const Icon(Icons.store_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? (t.required ?? 'Required')
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _desc,
                            minLines: 2,
                            maxLines: 6,
                            decoration: InputDecoration(
                              labelText: t.service_description ?? 'Description',
                              prefixIcon: const Icon(Icons.notes_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Category chips
                    _SectionCard(
                      title: t.select_category ?? 'Category',
                      child: _CategoryChips(
                        items: _categories,
                        value: _category,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Contacts
                    _SectionCard(
                      title: t.contact ?? 'Contact',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: t.email ?? 'Email',
                              prefixIcon:
                                  const Icon(Icons.alternate_email_outlined),
                            ),
                            validator: (v) => _validateEmail(v, t),
                          ),
                          const SizedBox(height: 10),
                          _PhoneField(
                            country: _country,
                            controller: _phoneField,
                            onCountryChanged: (c) {
                              final digits = _digitsOnly(_phoneField.text);
                              _country = c;
                              final truncated = digits.substring(
                                  0, min(digits.length, c.nsnMax));
                              _phoneField.text =
                                  _formatDigits(truncated, c.groups);
                              setState(() {});
                            },
                            validator: (v) => _validatePhone(v, t),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Save button
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _Brand.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(t.save ?? 'Save'),
                      ),
                    ),
                  ],
                ),
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
              Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _Brand.ink,
                ),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<_CategoryItem> items;
  final String? value;
  final ValueChanged<String> onChanged;

  const _CategoryChips({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((c) {
        final selected = c.id == value;
        return InkWell(
          onTap: () => onChanged(c.id),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  selected ? _Brand.accentSoft.withOpacity(.35) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? _Brand.primary : _Brand.border,
                width: selected ? 1.2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _Brand.primary.withOpacity(.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 18, color: _Brand.ink),
                const SizedBox(width: 6),
                Text(
                  c.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: _Brand.ink),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ====== helpers / models ======
class _CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  const _CategoryItem(
      {required this.id, required this.name, required this.icon});
}

class _Country {
  final String iso2;
  final String name;
  final String dial; // +998
  final int nsnMin;
  final int nsnMax;
  final List<int> groups; // how to space the NSN, e.g., [2,3,2,2]
  final String example; // shown as hint (formatted)

  const _Country(
    this.iso2,
    this.name,
    this.dial,
    this.nsnMin,
    this.nsnMax,
    this.groups,
    this.example,
  );
}

String _flagEmoji(String iso2) {
  final cc = iso2.toUpperCase();
  if (cc.length != 2) return '🏳️';
  const base = 0x1F1E6; // 'A'
  return String.fromCharCode(base + cc.codeUnitAt(0) - 65) +
      String.fromCharCode(base + cc.codeUnitAt(1) - 65);
}

/// Insert spaces according to groups.
String _formatDigits(String digits, List<int> groups) {
  final out = <String>[];
  var i = 0;
  for (final g in groups) {
    if (i >= digits.length) break;
    final end = min(i + g, digits.length);
    out.add(digits.substring(i, end));
    i = end;
  }
  if (i < digits.length) out.add(digits.substring(i));
  return out.join(' ');
}

// Central Asia + RU + TR (NSN = digits without country code)
const List<_Country> _countries = [
  _Country('UZ', 'Uzbekistan', '+998', 9, 9, [2, 3, 2, 2], '99 123 45 67'),
  _Country('KZ', 'Kazakhstan', '+7', 10, 10, [3, 3, 2, 2], '701 123 45 67'),
  _Country('KG', 'Kyrgyzstan', '+996', 9, 9, [3, 3, 3], '700 123 456'),
  _Country('TJ', 'Tajikistan', '+992', 9, 9, [3, 2, 2, 2], '900 12 34 56'),
  _Country('TM', 'Turkmenistan', '+993', 8, 8, [2, 3, 3], '6x xxx xxx'),
  _Country('RU', 'Russia', '+7', 10, 10, [3, 3, 2, 2], '900 123 45 67'),
  _Country('TR', 'Turkey', '+90', 10, 10, [3, 3, 2, 2], '500 123 45 67'),
];

class _PhoneField extends StatelessWidget {
  final _Country country;
  final TextEditingController controller; // formatted with spaces
  final FormFieldValidator<String>? validator;
  final ValueChanged<_Country> onCountryChanged;

  const _PhoneField({
    required this.country,
    required this.controller,
    required this.onCountryChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.phone ?? 'Phone',
          style: const TextStyle(
            color: _Brand.subtle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickCountry(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _Brand.border),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_flagEmoji(country.iso2),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(country.name, overflow: TextOverflow.ellipsis),
                    const SizedBox(width: 6),
                    Text(country.dial,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: country.example,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: validator,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
                ],
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  final limited =
                      digits.substring(0, min(digits.length, country.nsnMax));
                  final formatted = _formatDigits(limited, country.groups);
                  if (formatted != value) {
                    controller.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickCountry(BuildContext context) async {
    final c = await showModalBottomSheet<_Country>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _countries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final it = _countries[i];
            return ListTile(
              leading: Text(_flagEmoji(it.iso2),
                  style: const TextStyle(fontSize: 20)),
              title: Text(it.name),
              subtitle: Text(it.dial),
              onTap: () => Navigator.of(context).pop(it),
            );
          },
        ),
      ),
    );
    if (c != null) onCountryChanged(c);
  }
}
