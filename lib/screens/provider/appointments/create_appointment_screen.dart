import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:frontend/services/providers/provider_staff_service.dart';

import '../../../services/api_service.dart';
import '../../../services/appointments/appointment_service.dart';
import '../../../models/appointment_models.dart';
import '../../../services/services/manage_services_service.dart'; // ProviderServiceItem

String _hhmmFromHms(String hms) => hms.length >= 5 ? hms.substring(0, 5) : hms;
int _minsFromDuration(Duration? d) => d == null ? 30 : d.inMinutes;

class CreateAppointmentScreen extends StatefulWidget {
  final String? providerId; // owner/receptionist mode
  final List<StaffMember>? workers; // provider view (pick staff)
  final String? fixedWorkerId; // worker self view

  const CreateAppointmentScreen({
    super.key,
    required this.providerId,
    required this.workers,
    required this.fixedWorkerId,
  });

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  static const MethodChannel _contactsCh = MethodChannel('app.contacts');

  final _form = GlobalKey<FormState>();
  final _appt = AppointmentService();
  final _manageSvc = ManageServicesService();
  final _dio = ApiService.client;

  String? _providerId;
  String? _workerId;

  List<ProviderServiceItem> _services = [];
  ProviderServiceItem? _selectedService;
  int _serviceDurationMin = 30;

  DateTime _day = DateTime.now();
  List<String> _freeRaw = [];
  String? _timeRaw;

  final _guestPhoneCtrl = TextEditingController();
  final _guestNameCtrl = TextEditingController();
  String? _pickedCustomerId;
  bool _walkIn = false;

  bool _loadingSlots = false;
  bool _loadingServices = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _providerId = widget.providerId;
    if (widget.fixedWorkerId != null) {
      _workerId = widget.fixedWorkerId;
    } else if (widget.workers != null && widget.workers!.isNotEmpty) {
      _workerId = widget.workers!.first.id;
    }
    _initLoad();
  }

  Future<void> _initLoad() async {
    if (_providerId == null && _workerId != null) {
      try {
        final r = await _dio.get('/workers/$_workerId');
        if (r.data is Map && (r.data as Map)['providerId'] != null) {
          _providerId = (r.data as Map)['providerId'].toString();
        }
      } catch (_) {}
    }
    await _loadServicesForWorker();
    await _loadSlots();
  }

  Future<void> _loadServicesForWorker() async {
    if (_providerId == null || _workerId == null) return;
    setState(() => _loadingServices = true);
    try {
      final all = await _manageSvc.listAllByProvider(_providerId!);
      _services = all
          .where((s) => s.isActive && s.workerIds.contains(_workerId!))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (_services.isNotEmpty) {
        _selectedService = _services.first;
        _serviceDurationMin = _minsFromDuration(_selectedService!.duration);
      }
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadSlots() async {
    if (_workerId == null || _serviceDurationMin <= 0) return;
    setState(() => _loadingSlots = true);
    try {
      _freeRaw = await _appt.getFreeSlots(
        workerId: _workerId!,
        date: _day,
        serviceDurationMinutes: _serviceDurationMin,
      );
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _pickDeviceContact() async {
    try {
      final res = await _contactsCh.invokeMethod<dynamic>('pick');
      if (res is Map) {
        final m = Map<String, dynamic>.from(res.cast<String, dynamic>());
        final name = (m['name'] ?? '').toString();
        final phone = (m['phone'] ?? '').toString();
        if (name.isNotEmpty) _guestNameCtrl.text = name;
        if (phone.isNotEmpty) _guestPhoneCtrl.text = phone;
        setState(() => _walkIn = false);
      }
    } catch (_) {
      // no native handler – just ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final workers = widget.workers;

    return Scaffold(
      appBar: AppBar(title: const Text('New appointment')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (workers != null)
              DropdownButtonFormField<String>(
                value: _workerId,
                decoration: const InputDecoration(labelText: 'Worker'),
                items: workers
                    .map((w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(w.displayName),
                        ))
                    .toList(),
                onChanged: (v) async {
                  setState(() {
                    _workerId = v;
                    _selectedService = null;
                    _services = [];
                  });
                  await _loadServicesForWorker();
                  await _loadSlots();
                },
              ),
            const SizedBox(height: 8),
            _loadingServices
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedService?.id,
                    decoration: const InputDecoration(labelText: 'Service'),
                    items: _services.map((s) {
                      final mins = _minsFromDuration(s.duration);
                      final priceText = s.price == null
                          ? ''
                          : (s.price! % 1 == 0
                              ? s.price!.toInt().toString()
                              : s.price!.toString());
                      final label = priceText.isEmpty
                          ? '${s.name} • ${mins}m'
                          : '${s.name} • ${mins}m • $priceText';
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) async {
                      final sel = _services.firstWhere((s) => s.id == v);
                      setState(() {
                        _selectedService = sel;
                        _serviceDurationMin = _minsFromDuration(sel.duration);
                      });
                      await _loadSlots();
                    },
                  ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(_day.toIso8601String().split('T').first),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _day,
                    firstDate: DateTime.now().subtract(const Duration(days: 0)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _day = picked);
                    await _loadSlots();
                  }
                },
              ),
            ),
            _loadingSlots
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _freeRaw
                        .map((raw) => ChoiceChip(
                              label: Text(_hhmmFromHms(raw)),
                              selected: _timeRaw == raw,
                              onSelected: (_) => setState(() => _timeRaw = raw),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 16),
            const Text('Client', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Walk-in'),
                  selected: _walkIn,
                  onSelected: (v) {
                    setState(() {
                      _walkIn = v;
                      if (v) {
                        _guestNameCtrl.text = 'Walk-in';
                        _guestPhoneCtrl.clear(); // will send synthetic phone
                      }
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.contacts_outlined, size: 18),
                  label: const Text('Pick from contacts'),
                  onPressed: _pickDeviceContact,
                ),
                ActionChip(
                  avatar: const Icon(Icons.people_outline, size: 18),
                  label: const Text('Pick from clients'),
                  onPressed: () async {
                    // Expect a route that returns {'name':..., 'phone':...}
                    final res = await Navigator.of(context)
                        .pushNamed<Map>('clients/pick');
                    if (res is Map) {
                      final name = (res['name'] ?? '').toString();
                      final phone = (res['phone'] ?? '').toString();
                      if (name.isNotEmpty) _guestNameCtrl.text = name;
                      if (phone.isNotEmpty) _guestPhoneCtrl.text = phone;
                      setState(() => _walkIn = false);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _guestPhoneCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Phone (optional)'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _guestNameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Name (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_workerId == null || _selectedService == null || _timeRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final startHHmm = _hhmmFromHms(_timeRaw!);

      String? guestPhone = _guestPhoneCtrl.text.trim().isEmpty
          ? null
          : _guestPhoneCtrl.text.trim();
      String? guestName = _guestNameCtrl.text.trim().isEmpty
          ? null
          : _guestNameCtrl.text.trim();

      // Backend requires guestId or guestPhone for staff bookings.
      if (_pickedCustomerId == null &&
          (guestPhone == null || guestPhone.isEmpty)) {
        if (_walkIn) {
          // synthetic phone to satisfy backend, unique-ish
          guestPhone = 'WALKIN-${DateTime.now().millisecondsSinceEpoch}';
          guestName ??= 'Walk-in';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Enter phone, pick a client, or mark Walk-in')),
          );
          setState(() => _saving = false);
          return;
        }
      }

      final cmd = NewAppointmentCmd(
        workerId: _workerId!,
        serviceId: _selectedService!.id,
        date: _day,
        startTime: startHHmm,
        customerId: _pickedCustomerId,
        guestPhone: guestPhone,
        guestName: guestName,
      );
      await _appt.book(cmd);
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
