// CreateAppointmentScreen.dart
// (Only change vs last version is the robust providerId resolution inside the
// Pick client onPressed and a tiny helper comment in _initLoad; endpoints untouched.)

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../services/appointments/appointment_service.dart';
import '../../../models/appointment_models.dart';

import '../../../services/providers/provider_staff_service.dart';
import '../../../services/services/manage_services_service.dart';
import '../../clients/pick_client_screen.dart';
import '../../../core/phone_utils.dart';

// ── helpers ───────────────────────────────────────────────────────────────────
String _hhmmFromHms(String hms) => hms.length >= 5 ? hms.substring(0, 5) : hms;
int _minsFromDuration(Duration? d) => d == null ? 30 : d.inMinutes;

const String WALKIN_NAME = 'Walk-in';
String walkInPhoneE164(String? _) => '+000000000000';

// ── Stormy Morning colors (darker tones) ─────────────────────────────────────
const _stormDark = Color(0xFF384959);
const _stormMuted = Color(0xFF6A89A7);
const _stormLight = Color(0xFFBDDDFC);

// ── local UI DTO ─────────────────────────────────────────────────────────────
class _UiService {
  final String id;
  final String name;
  final int durationMin;
  final num? price;
  final String providerId;
  const _UiService({
    required this.id,
    required this.name,
    required this.durationMin,
    required this.providerId,
    this.price,
  });
}

class CreateAppointmentScreen extends StatefulWidget {
  final String? providerId; // owner/receptionist mode
  final List<StaffMember>? workers; // owner/receptionist mode
  final String? fixedWorkerId; // worker-self mode

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
  final _staffSvc = ProviderStaffService();
  final _dio = ApiService.client;

  String? _providerId;
  String? _workerId;

  String _workerDisplayName = '—';
  String? _workerAvatar;

  List<_UiService> _services = [];
  _UiService? _selectedService;
  int _serviceDurationMin = 30;

  DateTime _day = DateTime.now();
  List<String> _freeRaw = [];
  String? _timeRaw;

  final _guestPhoneCtrl = TextEditingController();
  final _guestNameCtrl = TextEditingController();
  String? _pickedCustomerId;
  String? _pickedGuestId;
  bool _walkIn = false;

  bool _loadingSlots = false;
  bool _loadingServices = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _providerId = widget.providerId;
    if ((widget.fixedWorkerId ?? '').isNotEmpty) {
      _workerId = widget.fixedWorkerId;
    } else if (widget.workers != null && widget.workers!.isNotEmpty) {
      _workerId = widget.workers!.first.id;
    }
    _initLoad();
  }

  @override
  void dispose() {
    _guestPhoneCtrl.dispose();
    _guestNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    if (_workerId != null) {
      try {
        final w = await _staffSvc.getWorker(_workerId!);
        _workerDisplayName = w.displayName;
        _workerAvatar = ApiService.normalizeMediaUrl(w.avatarUrl);
        // Note: We don’t rely on worker.providerId here because model may not expose it.
      } catch (_) {}
    }
    await _loadServicesForWorker();
    await _loadSlots();
  }

  Future<void> _loadServicesForWorker() async {
    if (_workerId == null) return;

    setState(() => _loadingServices = true);
    try {
      List<_UiService> items = [];

      if (_providerId == null) {
        final byWorker = await _manageSvc.listAllByWorker(_workerId!);
        items = byWorker
            .where((s) => s.isActive)
            .map((s) => _UiService(
                  id: s.id,
                  name: s.name,
                  durationMin: _minsFromDuration(s.duration),
                  price: s.price,
                  providerId: s.providerId,
                ))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        if (items.isNotEmpty) {
          _providerId = items.first.providerId; // resolve for client picker
        }
      } else {
        final all = await _manageSvc.listAllByProvider(_providerId!);
        items = all
            .where((s) => s.isActive && s.workerIds.contains(_workerId!))
            .map((s) => _UiService(
                  id: s.id,
                  name: s.name,
                  durationMin: _minsFromDuration(s.duration),
                  price: s.price,
                  providerId: s.providerId,
                ))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      }

      _services = items;
      if (_services.isNotEmpty) {
        _selectedService = _services.first;
        _serviceDurationMin = _selectedService!.durationMin;
      } else {
        _selectedService = null;
        _serviceDurationMin = 30;
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
      if (_timeRaw == null || !_freeRaw.contains(_timeRaw)) {
        _timeRaw = _freeRaw.isEmpty ? null : _freeRaw.first;
      }
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  void _applyWalkInDefaults(bool on) {
    _walkIn = on;
    _pickedCustomerId = null;
    _pickedGuestId = null;
    if (_walkIn) {
      _guestNameCtrl.text = WALKIN_NAME;
      _guestPhoneCtrl.text = walkInPhoneE164(_providerId);
    }
    setState(() {});
  }

  Future<void> _pickDeviceContact() async {
    final t = AppLocalizations.of(context)!;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.contacts_not_supported)),
      );
      return;
    }
    try {
      final res = await _contactsCh.invokeMethod<dynamic>('pick');
      if (res is Map) {
        final m = Map<String, dynamic>.from(res.cast<String, dynamic>());
        final name = (m['name'] ?? '').toString();
        final phone = (m['phone'] ?? '').toString();

        if (name.isNotEmpty) _guestNameCtrl.text = name;
        if (phone.isNotEmpty) {
          _guestPhoneCtrl.text =
              normalizePhoneE164(phone, defaultCountry: 'UZ');
        }

        setState(() {
          _walkIn = false;
          _pickedCustomerId = null;
          _pickedGuestId = null;
        });
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.contacts_permission_denied)),
      );
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final workers = widget.workers;
    final workerSelfMode = workers == null;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _stormDark.withOpacity(.18)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(t.new_appointment),
        backgroundColor: Colors.white,
        foregroundColor: _stormDark,
        elevation: 0,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // STAFF
            _sectionLabel(context, t.worker),
            const SizedBox(height: 8),
            if (workerSelfMode)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _stormDark.withOpacity(.08)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        (_workerAvatar != null && _workerAvatar!.isNotEmpty)
                            ? NetworkImage(_workerAvatar!)
                            : null,
                    backgroundColor: _stormDark.withOpacity(.06),
                    child: (_workerAvatar == null || _workerAvatar!.isEmpty)
                        ? const Icon(Icons.person, color: _stormDark)
                        : null,
                  ),
                  title: Text(
                    _workerDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _stormDark),
                  ),
                  subtitle: Text(t.worker,
                      style: TextStyle(color: _stormDark.withOpacity(.6))),
                  trailing:
                      const Icon(Icons.lock, size: 18, color: _stormMuted),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _workerId,
                decoration: InputDecoration(
                  labelText: t.worker,
                  filled: true,
                  fillColor: Colors.white,
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide:
                        const BorderSide(color: _stormMuted, width: 1.2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: workers
                    .map((w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(w.displayName,
                              overflow: TextOverflow.ellipsis),
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

            const SizedBox(height: 16),

            // SERVICE
            _sectionLabel(context, t.common_service),
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
                    decoration: InputDecoration(
                      labelText: t.common_service,
                      filled: true,
                      fillColor: Colors.white,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide:
                            const BorderSide(color: _stormMuted, width: 1.2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    items: _services.map((s) {
                      final priceText = s.price == null
                          ? ''
                          : (s.price! % 1 == 0
                              ? s.price!.toInt().toString()
                              : s.price!.toString());
                      final label = priceText.isEmpty
                          ? '${s.name} • ${s.durationMin}m'
                          : '${s.name} • ${s.durationMin}m • $priceText';
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) async {
                      final sel = _services.firstWhere((s) => s.id == v);
                      setState(() {
                        _selectedService = sel;
                        _serviceDurationMin = sel.durationMin;
                      });
                      await _loadSlots();
                    },
                    validator: (v) =>
                        v == null ? t.choose_service_validation : null,
                  ),
            if (!_loadingServices && _services.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t.no_services_assigned,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

            const SizedBox(height: 16),

            // DATE & TIME
            _sectionLabel(context, t.date),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: _stormDark.withOpacity(.08)),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined,
                    color: _stormDark),
                title: Text(_day.toIso8601String().split('T').first,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _stormDark)),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _day,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _day = picked);
                          await _loadSlots();
                        }
                      },
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: Text(t.select_date),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() => _day = DateTime.now());
                        await _loadSlots();
                      },
                      child: Text(t.today),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(t.select_time,
                style: TextStyle(color: _stormDark.withOpacity(.7))),
            const SizedBox(height: 8),

            _loadingSlots
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : (_freeRaw.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '—',
                          style: TextStyle(color: _stormDark.withOpacity(.5)),
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _freeRaw.map((raw) {
                          final selected = _timeRaw == raw;
                          return ChoiceChip(
                            label: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Text(
                                _hhmmFromHms(raw),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : _stormDark,
                                ),
                              ),
                            ),
                            selected: selected,
                            selectedColor: _stormDark,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: selected
                                  ? _stormDark
                                  : _stormDark.withOpacity(.18),
                            ),
                            onSelected: (_) => setState(() => _timeRaw = raw),
                          );
                        }).toList(),
                      )),

            const SizedBox(height: 18),

            // CLIENT
            _sectionLabel(context, t.guest_details),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(t.walk_in),
                  selected: _walkIn,
                  onSelected: (v) => _applyWalkInDefaults(v),
                  selectedColor: _stormDark,
                  labelStyle: TextStyle(
                    color: _walkIn ? Colors.white : _stormDark,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: _walkIn ? _stormDark : _stormDark.withOpacity(.18),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.people_outline,
                      size: 18, color: _stormDark),
                  label: Text(t.pick_client,
                      style: const TextStyle(color: _stormDark)),
                  onPressed: () async {
                    // ⇣ Robust provider resolution: if null, try once after services load
                    var provForPicker =
                        _providerId ?? _selectedService?.providerId;
                    if (provForPicker == null || provForPicker.isEmpty) {
                      await _loadServicesForWorker(); // may set _providerId
                      provForPicker =
                          _providerId ?? _selectedService?.providerId;
                    }
                    if (provForPicker == null || provForPicker.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.no_provider_for_clients)),
                      );
                      return;
                    }
                    final res =
                        await Navigator.of(context).push<Map<String, String?>>(
                      MaterialPageRoute(
                        builder: (_) =>
                            PickClientScreen(providerId: provForPicker!),
                      ),
                    );
                    if (res != null) {
                      _pickedCustomerId = res['customerId'];
                      _pickedGuestId = res['guestId'];
                      _guestNameCtrl.text = res['name'] ?? '';
                      if (_pickedCustomerId != null || _pickedGuestId != null) {
                        _guestPhoneCtrl.clear();
                      }
                      setState(() => _walkIn = false);
                    }
                  },
                  backgroundColor: _stormLight.withOpacity(.35),
                  shape: StadiumBorder(
                    side: BorderSide(color: _stormDark.withOpacity(.15)),
                  ),
                ),
                if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                  ActionChip(
                    avatar: const Icon(Icons.contacts_outlined,
                        size: 18, color: _stormDark),
                    label: Text(t.pick_from_contacts,
                        style: const TextStyle(color: _stormDark)),
                    onPressed: _pickDeviceContact,
                    backgroundColor: _stormLight.withOpacity(.35),
                    shape: StadiumBorder(
                      side: BorderSide(color: _stormDark.withOpacity(.15)),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _guestPhoneCtrl,
                    decoration: InputDecoration(
                      labelText: t.phone,
                      filled: true,
                      fillColor: Colors.white,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide:
                            const BorderSide(color: _stormMuted, width: 1.2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.phone,
                    onEditingComplete: () {
                      final norm = normalizePhoneE164(_guestPhoneCtrl.text,
                          defaultCountry: 'UZ');
                      _guestPhoneCtrl.text = norm;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _guestNameCtrl,
                    decoration: InputDecoration(
                      labelText: t.person_name,
                      filled: true,
                      fillColor: Colors.white,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide:
                            const BorderSide(color: _stormMuted, width: 1.2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _stormDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(t.create,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── save (endpoints unchanged) ──────────────────────────────────────────────
  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;

    if (_workerId == null || _selectedService == null || _timeRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fill_all_fields)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final startHHmm = _hhmmFromHms(_timeRaw!);
      final hasLink = (_pickedCustomerId != null) || (_pickedGuestId != null);

      String phone = _guestPhoneCtrl.text.trim();
      String name = _guestNameCtrl.text.trim();

      if (!hasLink) {
        phone = normalizePhoneE164(phone, defaultCountry: 'UZ');
        if (phone.isEmpty) phone = walkInPhoneE164(_providerId);
        if (name.isEmpty) name = WALKIN_NAME;
      }

      final cmd = NewAppointmentCmd(
        workerId: _workerId!,
        serviceId: _selectedService!.id,
        date: _day,
        startTime: startHHmm,
        customerId: _pickedCustomerId,
        guestId: _pickedGuestId,
        guestPhone: hasLink ? null : phone,
        guestName: hasLink ? null : name,
      );

      await _appt.book(cmd);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── small helpers ──────────────────────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: .2,
          fontWeight: FontWeight.w800,
          color: _stormMuted,
        ),
      );
}
