import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/provider_service.dart';
import '../../../../services/provider_services_service.dart';
import '../../../../services/provider_public_service.dart';

class ServiceEditScreen extends StatefulWidget {
  final String providerId;
  final ProviderService? existing; // null => create

  const ServiceEditScreen({
    super.key,
    required this.providerId,
    this.existing,
  });

  @override
  State<ServiceEditScreen> createState() => _ServiceEditScreenState();
}

class _ServiceEditScreenState extends State<ServiceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ProviderServicesService();
  final _providers = ProviderPublicService();

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _category = 'CLINIC'; // default
  bool _active = true;

  int _hours = 0;
  int _minutes = 30;

  List<WorkerLite> _providerWorkers = const [];
  final Set<String> _selectedWorkerIds = {};

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // provider workers
      final d = await _providers.getDetails(widget.providerId);
      _providerWorkers = d.workers;

      // fill form if editing
      final s = widget.existing;
      if (s != null) {
        _name.text = s.name;
        _description.text = s.description ?? '';
        _price.text = s.price?.toString() ?? '';
        _category = s.category;
        _active = s.isActive;
        _selectedWorkerIds.addAll(s.workerIds);
        final dur = s.duration ?? const Duration(minutes: 30);
        _hours = dur.inHours;
        _minutes = dur.inMinutes % 60;
      }
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Duration get _duration => Duration(hours: _hours, minutes: _minutes);

  Future<void> _save(AppLocalizations t) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorkerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_tx(t, 'pick_workers', 'Pick at least 1 worker'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        final payload = CreateServicePayload(
          name: _name.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          category: _category,
          price: _price.text.trim().isEmpty
              ? null
              : int.tryParse(_price.text.trim()),
          duration: _duration,
          providerId: widget.providerId,
          workerIds: _selectedWorkerIds.toList(),
        );
        await _svc.create(payload);
      } else {
        final s = widget.existing!;
        final updated = ProviderService(
          id: s.id,
          name: _name.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          category: _category,
          price: _price.text.trim().isEmpty
              ? null
              : int.tryParse(_price.text.trim()),
          duration: _duration,
          isActive: _active,
          providerId: widget.providerId,
          workerIds: _selectedWorkerIds.toList(),
          logoUrl: s.logoUrl,
        );
        await _svc.update(s.id, updated);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final priceFmt = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? _tx(t, 'create_service', 'Create service')
            : _tx(t, 'edit_service', 'Edit service')),
      ),
      body: (_error != null)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to load: $_error'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _bootstrap,
                    child: Text(t.provider_retry),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: _tx(t, 'field_name', 'Name'),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _tx(t, 'val_req', 'Required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: _tx(t, 'field_description', 'Description'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: _tx(t, 'field_category', 'Category'),
                    ),
                    items: _categoryItems(t)
                        .map((e) =>
                            DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),

                  const SizedBox(height: 12),

                  // Price
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _tx(t, 'field_price', 'Price (UZS)'),
                      hintText: priceFmt.format(80000),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Duration
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _hours.toString(),
                          key: ValueKey('hours-$_hours'),
                          decoration: InputDecoration(
                            labelText: _tx(t, 'field_hours', 'Hours'),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final n = int.tryParse(v) ?? 0;
                            setState(() => _hours = n.clamp(0, 10));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _minutes.toString(),
                          key: ValueKey('minutes-$_minutes'),
                          decoration: InputDecoration(
                            labelText: _tx(t, 'field_minutes', 'Minutes'),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final n = int.tryParse(v) ?? 0;
                            setState(() => _minutes = n.clamp(0, 59));
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Active switch (edit only)
                  if (widget.existing != null)
                    SwitchListTile(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      title: Text(_tx(t, 'field_active', 'Active')),
                    ),

                  const SizedBox(height: 8),
                  Text(_tx(t, 'field_workers', 'Workers'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),

                  if (_providerWorkers.isEmpty)
                    Text(_tx(t, 'no_workers', 'No workers found for provider.'))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _providerWorkers.map((w) {
                        final selected = _selectedWorkerIds.contains(w.id);
                        return FilterChip(
                          label: Text(w.name),
                          selected: selected,
                          onSelected: (s) {
                            setState(() {
                              if (s) {
                                _selectedWorkerIds.add(w.id);
                              } else {
                                _selectedWorkerIds.remove(w.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : () => _save(t),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_tx(t, 'action_save', 'Save')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// (value, localized label) using your ARB keys
  List<(String, String)> _categoryItems(AppLocalizations t) => [
        ('BARBERSHOP', t.cat_barbershop),
        ('DENTAL', t.cat_dental),
        ('CLINIC', t.cat_clinic),
        ('SPA', t.cat_spa),
        ('GYM', t.cat_gym),
        ('NAIL_SALON', t.cat_nail_salon),
        ('BEAUTY_CLINIC', t.cat_beauty_clinic),
        ('TATTOO_STUDIO', t.cat_tattoo_studio),
        ('MASSAGE_CENTER', t.cat_massage_center),
        ('PHYSIOTHERAPY_CLINIC', t.cat_physiotherapy_clinic),
        ('MAKEUP_STUDIO', t.cat_makeup_studio),
      ];

  String _tx(AppLocalizations t, String _key, String fallback) => fallback;
}
