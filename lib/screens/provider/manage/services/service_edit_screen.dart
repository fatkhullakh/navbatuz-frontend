import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/media/upload_service.dart';
import '../../../../services/services/provider_public_service.dart';

/* ================= Brand ================= */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const primarySoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const surface = Color(0xFFF6F8FC);
}

/* ============== Currency helpers (UZS now) ============== */

String _currencySuffixFor(Locale loc, AppLocalizations t) {
  final lang = (loc.languageCode).toLowerCase();
  switch (lang) {
    case 'uz':
      return t.currency_sum ?? "so'm";
    case 'ru':
      return t.currency_sum ?? 'сум';
    default:
      return t.currency_sum ?? 'sum';
  }
}

/// group digits with non-breaking spaces: 120 000
String _groupDigits(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleaned.isEmpty) return '';
  final sb = StringBuffer();
  final n = cleaned.length;
  for (var i = 0; i < n; i++) {
    sb.write(cleaned[i]);
    final left = n - i - 1;
    if (left > 0 && left % 3 == 0) sb.write('\u202F'); // narrow no-break space
  }
  return sb.toString();
}

num? _parseGroupedToNum(String s) {
  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

class ThousandsSpaceInputFormatter extends TextInputFormatter {
  const ThousandsSpaceInputFormatter();
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final grouped = _groupDigits(newValue.text);
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }
}

/* ================= DTO & API ================= */

class _ServiceDto {
  String? id;
  String name;
  String? description;
  String category;
  num? price;
  String? durationIso;
  bool isActive;
  bool deleted;
  String providerId;
  List<String> workerIds;
  String? imageUrl;

  _ServiceDto({
    this.id,
    required this.name,
    required this.category,
    required this.providerId,
    this.description,
    this.price,
    this.durationIso,
    this.isActive = true,
    this.deleted = false,
    this.workerIds = const [],
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'duration': durationIso,
        'isActive': isActive,
        'deleted': deleted,
        'providerId': providerId,
        'workerIds': workerIds,
        'imageUrl': imageUrl,
      }..removeWhere((_, v) => v == null);

  static _ServiceDto fromJson(Map<String, dynamic> j) => _ServiceDto(
        id: j['id']?.toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        category: j['category']?.toString() ?? 'CLINIC',
        price: (j['price'] is num)
            ? j['price'] as num
            : (j['price'] == null ? null : num.tryParse(j['price'].toString())),
        durationIso: j['duration']?.toString(),
        isActive: (j['isActive'] as bool?) ?? true,
        deleted: (j['deleted'] as bool?) ?? false,
        providerId: j['providerId']?.toString() ?? '',
        workerIds: ((j['workerIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        imageUrl: (j['imageUrl'] ?? j['logoUrl'])?.toString(),
      );
}

class _ServiceApi {
  final Dio _dio = ApiService.client;

  Future<_ServiceDto> getById(String id) async {
    final r = await _dio.get('/services/public/$id');
    return _ServiceDto.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<_ServiceDto> create(_ServiceDto dto) async {
    final r = await _dio.post('/services', data: dto.toJson());
    return _ServiceDto.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<void> update(_ServiceDto dto) async {
    if (dto.id == null) throw Exception('Missing service id');
    await _dio.put('/services/${dto.id}', data: dto.toJson());
  }

  Future<void> delete(String id) async {
    await _dio.delete('/services/$id');
  }

  Future<void> setImage(String id, String? url) async {
    await _dio.put('/services/$id/image', data: {'url': url});
  }
}

/* ================= Screen ================= */

class ProviderServiceEditScreen extends StatefulWidget {
  final String providerId;
  final String? serviceId;

  const ProviderServiceEditScreen({
    super.key,
    required this.providerId,
    this.serviceId,
  });

  @override
  State<ProviderServiceEditScreen> createState() =>
      _ProviderServiceEditScreenState();
}

class _ProviderServiceEditScreenState extends State<ProviderServiceEditScreen> {
  final _api = _ServiceApi();
  final _uploads = UploadService();
  final _provSvc = ProviderPublicService();

  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();

  String _category = 'CLINIC';
  int? _durationMin;
  bool _active = true;
  bool _deleted = false;
  String? _imageUrl;

  late Future<void> _bootstrap;
  _ServiceDto? _dto;
  List<WorkerLite> _allWorkers = [];
  final Set<String> _selectedWorkerIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bootstrap = _load();
  }

  Future<void> _load() async {
    final pd = await _provSvc.getDetails(widget.providerId);
    _allWorkers = pd.workers;

    if (widget.serviceId != null) {
      final s = await _api.getById(widget.serviceId!);
      _dto = s;
      _name.text = s.name;
      _price.text = s.price == null ? '' : _groupDigits('${s.price!.toInt()}');
      _desc.text = s.description ?? '';
      _category = s.category;
      _active = s.isActive;
      _deleted = s.deleted;
      _imageUrl = s.imageUrl;
      _durationMin = _parseIsoToMinutes(s.durationIso);
      _selectedWorkerIds
        ..clear()
        ..addAll(s.workerIds);
    } else {
      _dto = _ServiceDto(
        name: '',
        category: _category,
        providerId: widget.providerId,
        isActive: true,
        deleted: false,
        workerIds: const [],
      );
      _selectedWorkerIds.clear();
      _imageUrl = null;
      _active = true;
      _deleted = false;
      _durationMin = null;
    }
    if (mounted) setState(() {});
  }

  int? _parseIsoToMinutes(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final s = iso.toUpperCase();
    if (!s.startsWith('PT')) return null;
    int h = 0, m = 0;
    final hIdx = s.indexOf('H');
    final mIdx = s.indexOf('M');
    if (hIdx != -1) h = int.tryParse(s.substring(2, hIdx)) ?? 0;
    if (mIdx != -1) {
      final start = (hIdx == -1) ? 2 : hIdx + 1;
      m = int.tryParse(s.substring(start, mIdx)) ?? 0;
    }
    return h * 60 + m;
  }

  String? _minutesToIso(int? minutes) {
    if (minutes == null || minutes <= 0) return null;
    final h = minutes ~/ 60, m = minutes % 60;
    if (h > 0 && m > 0) return 'PT${h}H${m}M';
    if (h > 0) return 'PT${h}H';
    return 'PT${m}M';
  }

  String _prettyDuration(int? minutes, AppLocalizations t) {
    if (minutes == null || minutes <= 0) return t.not_set ?? 'Not set';
    final h = minutes ~/ 60, m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<void> _pickDuration(AppLocalizations t) async {
    final options = <int>[15, 30, 45, 60, 75, 90, 105, 120];
    final sel = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text(
                t.service_duration ?? 'Duration',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _Brand.ink,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options
                    .map((m) => ChoiceChip(
                          selected: _durationMin == m,
                          onSelected: (_) => Navigator.of(context).pop(m),
                          label: Text(_prettyDuration(m, t)),
                          selectedColor: _Brand.primarySoft,
                          labelStyle: TextStyle(
                              color: _durationMin == m
                                  ? _Brand.ink
                                  : Colors.black87),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (sel != null && mounted) setState(() => _durationMin = sel);
  }

  Future<void> _save(AppLocalizations t) async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.required ?? 'Required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dto = _dto ??
          _ServiceDto(
            providerId: widget.providerId,
            category: _category,
            name: _name.text.trim(),
          );

      dto.name = _name.text.trim();
      dto.description = _desc.text.trim().isEmpty ? null : _desc.text.trim();
      dto.category = _category;
      dto.price = _parseGroupedToNum(_price.text.trim());
      dto.durationIso = _minutesToIso(_durationMin);
      dto.isActive = _active;
      dto.deleted = _deleted;
      dto.providerId = widget.providerId;
      dto.workerIds = _selectedWorkerIds.toList();
      dto.imageUrl = _imageUrl;

      if (dto.id == null) {
        final created = await _api.create(dto);
        _dto = created;
      } else {
        await _api.update(dto);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage(AppLocalizations t) async {
    final img = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 90, maxWidth: 1600);
    if (img == null) return;

    try {
      if ((_dto?.id ?? '').isEmpty) {
        final url = await _uploads.uploadServiceDraft(
          providerId: widget.providerId,
          filePath: img.path,
        );
        setState(() => _imageUrl = url);
      } else {
        final url = await _uploads.uploadServiceImage(
          serviceId: _dto!.id!,
          filePath: img.path,
        );
        await _api.setImage(_dto!.id!, url);
        setState(() => _imageUrl = url);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.image_updated ?? 'Image updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.error_upload_image ?? 'Upload failed')),
      );
    }
  }

  Future<void> _removeImage(AppLocalizations t) async {
    try {
      if (_dto?.id == null) {
        setState(() => _imageUrl = null);
      } else {
        await _api.setImage(_dto!.id!, null);
        setState(() => _imageUrl = null);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.image_removed ?? 'Image removed')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.error_remove_image ?? 'Remove failed')),
      );
    }
  }

  Future<void> _confirmDelete(AppLocalizations t) async {
    if (_dto?.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(t.confirm_delete_title ?? 'Delete service?'),
        content: Text(t.confirm_delete_msg ?? 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(t.action_cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD92D20)),
            child: Text(t.action_delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.delete(_dto!.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = widget.serviceId != null;
    final currencyWord = _currencySuffixFor(Localizations.localeOf(context), t);

    String? coverUrl() {
      final raw = (_imageUrl ?? '').trim();
      if (raw.isEmpty) return null;
      final n = ApiService.normalizeMediaUrl(raw);
      final u = (n ?? raw).trim();
      return u.isEmpty ? null : u;
    }

    InputBorder _fieldBorder([Color? c]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c ?? _Brand.border),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _name.text.isEmpty
              ? (isEdit ? '-' : (t.service_create ?? 'Create service'))
              : _name.text,
        ),
        actions: [
          if (isEdit && (_dto?.id != null))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: t.action_delete ?? 'Delete',
              onPressed: () => _confirmDelete(t),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _bootstrap,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Failed: ${snap.error}'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _bootstrap = _load();
                    });
                  },
                  child: Text(t.action_retry ?? 'Retry'),
                ),
              ]),
            );
          }

          final url = coverUrl();

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
            children: [
              _SectionCard(
                title: t.main_details_required ?? 'Main details',
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: t.service_name ?? 'Name',
                        filled: true,
                        fillColor: _Brand.surface,
                        border: _fieldBorder(),
                        enabledBorder: _fieldBorder(),
                        focusedBorder: _fieldBorder(_Brand.primary),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\s\u00A0\u202F]')),
                              const ThousandsSpaceInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText:
                                  '${t.price ?? 'Price'} ($currencyWord)',
                              hintText: '120 000',
                              filled: true,
                              fillColor: _Brand.surface,
                              border: _fieldBorder(),
                              enabledBorder: _fieldBorder(),
                              focusedBorder: _fieldBorder(_Brand.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDuration(t),
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: t.service_duration ?? 'Duration',
                                filled: true,
                                fillColor: _Brand.surface,
                                border: _fieldBorder(),
                                enabledBorder: _fieldBorder(),
                                focusedBorder: _fieldBorder(_Brand.primary),
                              ),
                              child: Text(_prettyDuration(_durationMin, t)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _desc,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: t.service_description ?? 'Description',
                        filled: true,
                        fillColor: _Brand.surface,
                        border: _fieldBorder(),
                        enabledBorder: _fieldBorder(),
                        focusedBorder: _fieldBorder(_Brand.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: t.photos ?? 'Photos',
                child: Row(
                  children: [
                    if (url != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: _Brand.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _Brand.border),
                                ),
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(t),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(.55),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (url != null) const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _pickImage(t),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: _Brand.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _Brand.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined,
                                color: _Brand.ink),
                            const SizedBox(height: 4),
                            Text(
                              t.add_photo ?? 'Add photo',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _Brand.subtle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_allWorkers.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: t.staff_members ?? 'Staff members',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allWorkers.map((w) {
                      final selected = _selectedWorkerIds.contains(w.id);
                      return FilterChip(
                        selected: selected,
                        label: Text(w.name),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedWorkerIds.add(w.id);
                            } else {
                              _selectedWorkerIds.remove(w.id);
                            }
                          });
                        },
                        selectedColor: _Brand.primarySoft,
                        side: const BorderSide(color: _Brand.border),
                        labelStyle: TextStyle(
                          color: selected ? _Brand.ink : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _SectionCard(
                title: t.active ?? 'Active',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _active
                          ? (t.status_active ?? 'Active')
                          : (t.status_inactive ?? 'Inactive'),
                      style: TextStyle(
                        color: _active
                            ? const Color(0xFF12B76A)
                            : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Switch(
                      value: _active,
                      activeColor: Colors.white,
                      activeTrackColor: _Brand.primary,
                      onChanged: (v) => setState(() => _active = v),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _Brand.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  _saving ? null : () => _save(AppLocalizations.of(context)!),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                AppLocalizations.of(context)!.action_save ?? 'Save',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= Small UI helpers ================= */

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _Brand.border),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _Brand.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
