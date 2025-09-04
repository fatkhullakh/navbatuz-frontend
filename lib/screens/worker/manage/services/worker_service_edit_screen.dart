import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/media/upload_service.dart';

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
            : num.tryParse(j['price']?.toString() ?? ''),
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

class WorkerServiceEditScreen extends StatefulWidget {
  final String providerId; // IMPORTANT: real provider id
  final String workerId; // self
  final String? serviceId;

  const WorkerServiceEditScreen({
    super.key,
    required this.providerId,
    required this.workerId,
    this.serviceId,
  });

  @override
  State<WorkerServiceEditScreen> createState() =>
      _WorkerServiceEditScreenState();
}

class _WorkerServiceEditScreenState extends State<WorkerServiceEditScreen> {
  final _api = _ServiceApi();
  final _uploads = UploadService();

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bootstrap = _load();
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

  Future<void> _load() async {
    if (widget.serviceId != null) {
      final s = await _api.getById(widget.serviceId!);
      _dto = s;
      _name.text = s.name;
      _price.text = (s.price == null) ? '' : s.price.toString();
      _desc.text = s.description ?? '';
      _category = s.category;
      _active = s.isActive;
      _deleted = s.deleted;
      _imageUrl = s.imageUrl;
      _durationMin = _parseIsoToMinutes(s.durationIso);
    } else {
      _dto = _ServiceDto(
        name: '',
        category: _category,
        providerId: widget.providerId,
        isActive: true,
        deleted: false,
        workerIds: [widget.workerId], // <-- pre-bind self
      );
      _imageUrl = null;
      _active = true;
      _deleted = false;
      _durationMin = null;
    }
    if (mounted) setState(() {});
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text(t.service_duration ?? 'Duration',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final m in options)
              ListTile(
                  title: Text(_prettyDuration(m, t)),
                  onTap: () => Navigator.of(context).pop(m)),
            const SizedBox(height: 8),
          ],
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
      dto.price =
          _price.text.trim().isEmpty ? null : num.tryParse(_price.text.trim());
      dto.durationIso = _minutesToIso(_durationMin);
      dto.isActive = _active;
      dto.deleted = _deleted;
      dto.providerId = widget.providerId; // <-- ensure correct provider id
      dto.workerIds = dto.id == null
          ? [widget.workerId]
          : (dto.workerIds.isEmpty ? [widget.workerId] : dto.workerIds);
      dto.imageUrl = _imageUrl;

      if (dto.id == null) {
        await _api.create(dto);
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
        // pre-create upload (draft under provider)
        final url = await _uploads.uploadServiceDraft(
          providerId: widget.providerId, // <-- provider id
          filePath: img.path,
        );
        setState(() => _imageUrl = url);
      } else {
        final url = await _uploads.uploadServiceImage(
          serviceId: _dto!.id!,
          filePath: img.path,
        );
        await _api.setImage(
            _dto!.id!, url); // <-- requires backend auth update below
        setState(() => _imageUrl = url);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.image_updated ?? 'Image updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.error_upload_image ?? 'Upload failed')));
    }
  }

  Future<void> _removeImage(AppLocalizations t) async {
    try {
      if (_dto?.id == null) {
        setState(() => _imageUrl = null);
      } else {
        await _api.setImage(
            _dto!.id!, null); // <-- requires backend auth update below
        setState(() => _imageUrl = null);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.image_removed ?? 'Image removed')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.error_remove_image ?? 'Remove failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = widget.serviceId != null;

    String? coverUrl() {
      final raw = (_imageUrl ?? '').trim();
      if (raw.isEmpty) return null;
      final n = ApiService.normalizeMediaUrl(raw);
      final u = (n ?? raw).trim();
      return u.isEmpty ? null : u;
    }

    final url = coverUrl();
    return Scaffold(
      appBar: AppBar(
        title: Text(_name.text.isEmpty
            ? (isEdit ? '-' : (t.service_create ?? 'Create service'))
            : _name.text),
        actions: [
          if (isEdit && (_dto?.id != null))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: t.action_delete ?? 'Delete',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text(t.confirm_delete_title ?? 'Delete service?'),
                    content: Text(t.confirm_delete_msg ??
                        'This action cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: Text(t.action_cancel ?? 'Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: Text(t.action_delete ?? 'Delete')),
                    ],
                  ),
                );
                if (ok == true) {
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
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _save(t),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.action_save ?? 'Save'),
            ),
          ),
        ),
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
                  onPressed: () => setState(() => _bootstrap = _load()),
                  child: Text(t.action_retry ?? 'Retry'),
                ),
              ]),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              Text(t.main_details_required ?? 'Main details',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration:
                    InputDecoration(labelText: t.service_name ?? 'Name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: t.price ?? 'Price'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDuration(t),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                            labelText: t.service_duration ?? 'Duration'),
                        child: Text(_prettyDuration(_durationMin, t)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _desc,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                    labelText: t.service_description ?? 'Description'),
              ),
              const SizedBox(height: 12),
              Text(t.photos ?? 'Photos',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (url != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F7),
                                borderRadius: BorderRadius.circular(12),
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
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle),
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
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6ECF2)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined),
                          SizedBox(height: 4),
                          Text('Add photo', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.active ?? 'Active'),
                  Switch(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
