// lib/screens/provider/business/provider_business_details_screen.dart
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/api_service.dart';
import '../../../../../services/media/upload_service.dart';

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

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait([_loadDetails(), _loadCategories()]);
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
    _category = (data['category'] ?? '').toString();

    final rawLogo = (data['logoUrl'] ?? '').toString().trim();
    _logoUrl = rawLogo.isEmpty ? null : rawLogo;

    // phone comes as "phone" or "phoneNumber"
    final rawPhone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
    _applyIncomingPhone(rawPhone);

    if (mounted) setState(() {});
  }

  void _applyIncomingPhone(String raw) {
    var s = raw.trim().replaceAll(' ', '');
    if (s.isEmpty) {
      _phoneField.text = '';
      return;
    }
    if (!s.startsWith('+')) {
      // try to infer country by leading digits
      final guess = _countries.firstWhere(
        (c) => s.startsWith(c.dial.replaceFirst('+', '')),
        orElse: () => _countries.first,
      );
      s = '+${guess.dial.replaceFirst('+', '')}${s.substring(guess.dial.length - 1)}';
    }

    // match country
    final c = _countries.firstWhere(
      (x) => s.startsWith(x.dial),
      orElse: () => _countries.first,
    );
    _country = c;

    final nsnDigits = s.replaceFirst(c.dial, '').replaceAll(RegExp(r'\D'), '');
    final truncated = nsnDigits.substring(0, min(nsnDigits.length, c.nsnMax));
    _phoneField.text = _formatDigits(truncated, c.groups);
  }

  Future<void> _loadCategories() async {
    final r = await _dio.get('/providers');
    final list = (r.data as List?) ?? [];
    _categories = list.whereType<Map>().map((m) {
      final mm = m.cast<String, dynamic>();
      return _CategoryItem(
        id: (mm['id'] ?? '').toString(),
        name: (mm['name'] ?? '').toString(),
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  String _fullPhoneForApi() =>
      '${_country.dial}${_digitsOnly(_phoneField.text)}';

  String _digitsRangeMsg(AppLocalizations t, int min, int max) {
    // Use the generated method with placeholders:
    // ARB: "phone_enter_digits_range": "Enter {min}–{max} digits"
    try {
      return t.phone_enter_digits_range(min, max);
    } catch (_) {
      // Fallback if the key name differs
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

  final _formKey = GlobalKey<FormState>();

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
      appBar:
          AppBar(title: Text(t.business_details_title ?? 'Business details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(0xFFF2F4F7),
                          backgroundImage: (_logoUrl == null)
                              ? null
                              : NetworkImage(
                                  ApiService.normalizeMediaUrl(_logoUrl!) ??
                                      _logoUrl!,
                                ),
                          child: (_logoUrl == null)
                              ? const Icon(Icons.image_outlined,
                                  size: 28, color: Colors.black45)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.photo_camera_outlined),
                              onPressed: _pickLogo,
                              label: Text(t.change_logo ?? 'Change logo'),
                            ),
                            if (_logoUrl != null)
                              TextButton(
                                onPressed: _removeLogo,
                                child: Text(t.remove_logo ?? 'Remove'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                        labelText: t.company_name_label ?? 'Name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (t.required ?? 'Required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _desc,
                    minLines: 2,
                    maxLines: 6,
                    decoration: InputDecoration(
                        labelText: t.service_description ?? 'Description'),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                        labelText: t.select_category ?? 'Category'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: (_category != null &&
                                _categories.any((c) => c.id == _category))
                            ? _category
                            : null,
                        items: _categories
                            .map((c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v),
                        hint: Text(t.select_category ?? 'Select category'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: t.email ?? 'Email'),
                    validator: (v) => _validateEmail(v, t),
                  ),
                  const SizedBox(height: 12),

                  // PHONE FIELD (nicer UI)
                  _PhoneField(
                    country: _country,
                    controller: _phoneField,
                    onCountryChanged: (c) {
                      // keep digits and reformat with new country mask
                      final digits = _digitsOnly(_phoneField.text);
                      _country = c;
                      final truncated =
                          digits.substring(0, min(digits.length, c.nsnMax));
                      _phoneField.text = _formatDigits(truncated, c.groups);
                      setState(() {});
                    },
                    validator: (v) => _validatePhone(v, t),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving
                          ? (t.saving ?? 'Saving…')
                          : (t.save ?? 'Save')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ====== helpers ======
class _CategoryItem {
  final String id;
  final String name;
  const _CategoryItem({required this.id, required this.name});
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
  // leftover (if user typed more than pattern): append as is
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
        Text(t.phone ?? 'Phone',
            style: Theme.of(context).inputDecorationTheme.labelStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            // Country chip opens a bottom sheet
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pickCountry(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(10),
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
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Digits field with masking
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: country.example,
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
