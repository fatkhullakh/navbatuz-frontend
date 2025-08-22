import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/services/provider_services_service.dart';
import '../../../../services/media/upload_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/providers/provider_owner_services_service.dart';

class ServiceFormScreen extends StatefulWidget {
  final String providerId;
  final OwnerServiceItem? existing;
  const ServiceFormScreen({
    super.key,
    required this.providerId,
    this.existing,
  });

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _svc = ProviderOwnerServicesService();
  final _uploads = UploadService();
  final _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();

  Duration? _duration;
  bool _active = true;
  String? _imageUrl; // cover
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _price.text = (e.price ?? 0).toString();
      _desc.text = e.description ?? '';
      _duration = e.duration;
      _active = e.isActive ?? true;
      _imageUrl = e.imageUrl ?? e.logoUrl;
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 90, maxWidth: 1600);
    if (picked == null) return;

    try {
      // 1) Upload file and get public URL
      final url = await _uploads.uploadServiceCover(
        providerId: widget.providerId,
        serviceId: widget.existing?.id,
        filePath: picked.path,
      );
      // 2) Tell backend to set the image URL
      final id = widget.existing?.id;
      if (id == null) {
        // No ID yet → store locally; the URL will be sent on create
        setState(() => _imageUrl = url);
      } else {
        await _svc.setImage(id, url);
        setState(() => _imageUrl = url);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Image updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _removeImage() async {
    try {
      final id = widget.existing?.id;
      if (id == null) {
        setState(() => _imageUrl = null);
      } else {
        await _svc.setImage(
            id, ''); // backend stores empty string → treat as “no image”
        setState(() => _imageUrl = null);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Image removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to remove image: $e')));
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null) return _t(AppLocalizations.of(context)!.not_set, 'Not set');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<void> _chooseDuration() async {
    // simple minute picker (15-min steps)
    final t = AppLocalizations.of(context)!;
    final options = <int>[15, 20, 25, 30, 35, 40, 45, 60, 75, 90, 105, 120];
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: Text(_t(t.service_duration, 'Service duration'),
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            for (final m in options)
              ListTile(
                title: Text('$m min'),
                onTap: () => Navigator.pop(context, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() => _duration = Duration(minutes: selected));
    }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final price = num.tryParse(_price.text.replaceAll(',', '.')) ?? 0;
      if (widget.existing == null) {
        // CREATE
        await _svc.create(
          providerId: widget.providerId,
          name: _name.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          category:
              null, // you said not to show category on list; keep as-is or add on form later
          price: price,
          duration: _duration,
          isActive: _active,
          imageUrl: _imageUrl,
          workerIds: const [],
        );
      } else {
        // UPDATE
        await _svc.update(
          id: widget.existing!.id!,
          providerId: widget.providerId,
          name: _name.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          category: widget.existing!.category, // keep original for now
          price: price,
          duration: _duration,
          isActive: _active,
          imageUrl: _imageUrl,
          workerIds: widget.existing!.workerIds ?? const [],
        );
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = widget.existing == null
        ? _t(t.service_create, 'Create service')
        : widget.existing!.name;

    final locale = Localizations.localeOf(context).toLanguageTag();
    final money =
        NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_t(t.action_save, 'SAVE')),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_t(t.action_save, 'SAVE')),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          // REQUIRED
          Text(_t(t.main_details_required, 'Main details (required)'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          TextFormField(
            controller: _name,
            decoration:
                InputDecoration(labelText: _t(t.service_name, 'Service name')),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? _t(t.required, 'Required')
                : null,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _t(t.price, 'Price'),
                    suffixText: money.currencySymbol.isEmpty
                        ? ''
                        : money.currencySymbol,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _chooseDuration,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _t(t.service_duration, 'Service duration'),
                    ),
                    child: Text(_formatDuration(_duration)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _desc,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: _t(t.service_description, 'Service Description'),
            ),
          ),

          const SizedBox(height: 16),

          // IMAGE
          Text(_t(t.photos, 'Photos'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if ((_imageUrl ?? '').isNotEmpty)
                  _ImageTile(
                    url: ApiService.normalizeMediaUrl(_imageUrl),
                    onRemove: _removeImage,
                  ),
                _AddPhotoTile(onTap: _pickImage),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // MORE
          SwitchListTile(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: Text(_t(t.active, 'Active')),
          ),
        ],
      ),
    );
  }

  String _t(String? s, String f) => s ?? f;
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined),
              SizedBox(height: 6),
              Text('Add photo', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String? url;
  final VoidCallback onRemove;
  const _ImageTile({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 100,
          margin: const EdgeInsets.only(right: 10),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF2F4F7),
          ),
          child: (url == null)
              ? const Icon(Icons.image_outlined)
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
                ),
        ),
        Positioned(
          right: 16,
          top: 6,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
