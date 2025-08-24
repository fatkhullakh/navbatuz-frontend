// lib/screens/staff/appointments/staff_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../services/appointments/appointment_service.dart';
import '../../../models/appointment_models.dart';
import '../../../services/providers/provider_staff_service.dart';
import '../../../services/providers/provider_services_service.dart';

class StaffAppointmentsScreen extends StatefulWidget {
  final String? providerId; // for owner/receptionist view
  final String? workerId; // for worker self-view
  const StaffAppointmentsScreen({super.key, this.providerId, this.workerId})
      : assert((providerId != null) ^ (workerId != null),
            'Pass exactly one of providerId or workerId');

  @override
  State<StaffAppointmentsScreen> createState() =>
      _StaffAppointmentsScreenState();
}

class _StaffAppointmentsScreenState extends State<StaffAppointmentsScreen> {
  final _appt = AppointmentService();
  final _dio = ApiService.client;
  final _staffSvc = ProviderStaffService();
  final _svcSvc = ProviderServicesService();

  DateTime _selectedDay = DateTime.now();
  bool _loading = true;
  String? _error;

  // workers available to view (id -> name)
  List<StaffMember> _workers = [];
  // which workers are “selected” (for owner view – multiple columns)
  final Set<String> _selectedWorkerIds = {};

  // cache: workerId -> that day's appointments
  final Map<String, List<Appointment>> _agenda = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.workerId != null) {
        // worker self view
        _selectedWorkerIds
          ..clear()
          ..add(widget.workerId!);
        await _loadWorkerDay(widget.workerId!);
      } else {
        // owner/receptionist: load provider workers, preselect first two
        final ws = await _staffSvc.getProviderStaff(widget.providerId!);
        _workers = ws.where((w) => w.isActive).toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        _selectedWorkerIds
          ..clear()
          ..addAll(_workers.take(2).map((w) => w.id));
        for (final id in _selectedWorkerIds) {
          await _loadWorkerDay(id);
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data?.toString() ?? e.message ?? e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadWorkerDay(String workerId) async {
    final list = await _appt.getWorkerDay(workerId, _selectedDay);
    _agenda[workerId] = list;
    if (mounted) setState(() {});
  }

  // Week strip helpers
  List<DateTime> get _weekDays {
    final monday =
        _selectedDay.subtract(Duration(days: (_selectedDay.weekday + 6) % 7));
    return List.generate(
        7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.appointments_title ?? 'Appointments')),
      body: Column(
        children: [
          // Week strip
          SizedBox(
            height: 68,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: _weekDays.map((d) {
                final isSel = d.year == _selectedDay.year &&
                    d.month == _selectedDay.month &&
                    d.day == _selectedDay.day;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text([
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ][d.weekday - 1]),
                        const SizedBox(height: 2),
                        Text(d.day.toString()),
                      ],
                    ),
                    selected: isSel,
                    onSelected: (_) async {
                      setState(() => _selectedDay = d);
                      // reload all selected workers
                      for (final id in _selectedWorkerIds) {
                        await _loadWorkerDay(id);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Worker chips (provider view)
          if (widget.providerId != null)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: _workers.map((w) {
                  final sel = _selectedWorkerIds.contains(w.id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      avatar: const Icon(Icons.person_outline, size: 18),
                      label: Text(w.displayName),
                      selected: sel,
                      onSelected: (v) async {
                        setState(() {
                          if (v)
                            _selectedWorkerIds.add(w.id);
                          else
                            _selectedWorkerIds.remove(w.id);
                        });
                        if (v) await _loadWorkerDay(w.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null
                    ? Center(child: Text(_error!))
                    : _buildAgenda(context)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreatePressed,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAgenda(BuildContext context) {
    final ids = widget.workerId != null
        ? [widget.workerId!]
        : _selectedWorkerIds.toList();
    if (ids.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_workers_selected ??
              'No workers selected'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: ids.length,
      itemBuilder: (_, i) {
        final id = ids[i];
        final member = _workers.firstWhere((w) => w.id == id,
            orElse: () => StaffMember.stub(id));
        final items = (_agenda[id] ?? const [])
          ..sort((a, b) => a.start.compareTo(b.start));
        return _WorkerAgendaSection(
          workerName: member.displayName,
          appointments: items,
          onCancel: (a) async {
            await _appt.cancel(a.id);
            await _loadWorkerDay(id);
          },
          onComplete: (a) async {
            await _appt.complete(a.id);
            await _loadWorkerDay(id);
          },
          onReschedule: (a) => _openReschedule(a, workerId: id),
        );
      },
    );
  }

  Future<void> _onCreatePressed() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NewAppointmentSheet(
        providerId: widget.providerId,
        workers: widget.providerId != null ? _workers : null,
        fixedWorkerId: widget.workerId,
      ),
    );
    if (created == true) {
      // reload
      final ids = widget.workerId != null
          ? [widget.workerId!]
          : _selectedWorkerIds.toList();
      for (final id in ids) {
        await _loadWorkerDay(id);
      }
    }
  }

  Future<void> _openReschedule(Appointment a,
      {required String workerId}) async {
    final t = AppLocalizations.of(context)!;

    // Quick picker: just time list from free-slots for same worker/service/date
    final durationMin = _guessDurationFromEnd(a.start, a.end);
    final free = await _appt.getFreeSlots(
        workerId: workerId, date: a.date, serviceDurationMinutes: durationMin);

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(t.reschedule ?? 'Reschedule'),
        children: [
          if (free.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t.no_free_slots ?? 'No free slots'),
            )
          else
            ...free.map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, s),
                  child: Text(s),
                ))
        ],
      ),
    );
    if (selected == null) return;
    await _appt.reschedule(
        appointmentId: a.id, newDate: a.date, newStartTime: selected);
    await _loadWorkerDay(workerId);
  }

  int _guessDurationFromEnd(String start, String end) {
    final sh = int.parse(start.split(':')[0]);
    final sm = int.parse(start.split(':')[1]);
    final eh = int.parse(end.split(':')[0]);
    final em = int.parse(end.split(':')[1]);
    return (eh * 60 + em) - (sh * 60 + sm);
  }
}

class _WorkerAgendaSection extends StatelessWidget {
  final String workerName;
  final List<Appointment> appointments;
  final Future<void> Function(Appointment) onCancel;
  final Future<void> Function(Appointment) onComplete;
  final Future<void> Function(Appointment) onReschedule;

  const _WorkerAgendaSection({
    required this.workerName,
    required this.appointments,
    required this.onCancel,
    required this.onComplete,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workerName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (appointments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(t.no_appointments ?? 'No appointments'),
              ),
            ...appointments.map((a) => _ApptTile(
                  a: a,
                  onCancel: () => onCancel(a),
                  onComplete: () => onComplete(a),
                  onReschedule: () => onReschedule(a),
                )),
          ],
        ),
      ),
    );
  }
}

class _ApptTile extends StatelessWidget {
  final Appointment a;
  final VoidCallback onCancel, onComplete, onReschedule;

  const _ApptTile({
    required this.a,
    required this.onCancel,
    required this.onComplete,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = {
      AppointmentStatus.BOOKED: const Color(0xFF12B76A),
      AppointmentStatus.RESCHEDULED: const Color(0xFF7F56D9),
      AppointmentStatus.CANCELLED: const Color(0xFFD92D20),
      AppointmentStatus.COMPLETED: const Color(0xFF155EEF),
    }[a.status]!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor.withOpacity(.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: statusColor.withOpacity(.12),
          child: Icon(Icons.event, color: statusColor, size: 18),
        ),
        title: Text('${a.start}–${a.end}'),
        subtitle: Text(
          // We don’t have full customer name in this DTO; show guest mask or “Customer”
          a.guestMask != null ? 'Guest ${a.guestMask}' : 'Customer',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'reschedule':
                onReschedule();
                break;
              case 'complete':
                onComplete();
                break;
              case 'cancel':
                onCancel();
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
            const PopupMenuItem(value: 'complete', child: Text('Complete')),
            const PopupMenuItem(
                value: 'cancel',
                child:
                    Text('Cancel', style: TextStyle(color: Color(0xFFD92D20)))),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for quick booking
class _NewAppointmentSheet extends StatefulWidget {
  final String? providerId;
  final List<StaffMember>? workers; // for provider view
  final String? fixedWorkerId; // for worker self view

  const _NewAppointmentSheet({
    required this.providerId,
    required this.workers,
    required this.fixedWorkerId,
  });

  @override
  State<_NewAppointmentSheet> createState() => _NewAppointmentSheetState();
}

class _NewAppointmentSheetState extends State<_NewAppointmentSheet> {
  final _form = GlobalKey<FormState>();
  final _appt = AppointmentService();
  final _servicesSvc = ProviderServicesService();

  String? _workerId;
  String? _serviceId;
  int _serviceDurationMin = 30;
  DateTime _day = DateTime.now();
  List<String> _free = [];
  String? _time; // "HH:mm"
  // booking for guest
  final _guestPhoneCtrl = TextEditingController();
  final _guestNameCtrl = TextEditingController();

  bool _loadingSlots = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _workerId = widget.fixedWorkerId ?? (widget.workers?.firstOrNull?.id);
    if (_workerId != null) _loadDefaultServiceDuration();
  }

  Future<void> _loadDefaultServiceDuration() async {
    // Quick grab the worker’s services to know duration options
    if (_workerId == null) return;
    try {
      final services = await _servicesSvc.getAllByWorker(_workerId!);
      if (services.isNotEmpty) {
        _serviceId = services.first.id;
        _serviceDurationMin = services.first.durationMinutes;
        if (mounted) setState(() {});
        await _loadSlots();
      }
    } catch (_) {}
  }

  Future<void> _loadSlots() async {
    if (_workerId == null || _serviceDurationMin <= 0) return;
    setState(() => _loadingSlots = true);
    try {
      _free = await _appt.getFreeSlots(
          workerId: _workerId!,
          date: _day,
          serviceDurationMinutes: _serviceDurationMin);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final workers = widget.workers;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999)))),
                Text(t.new_appointment ?? 'New appointment',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                if (workers != null)
                  DropdownButtonFormField<String>(
                    value: _workerId,
                    decoration:
                        InputDecoration(labelText: t.worker ?? 'Worker'),
                    items: workers
                        .map((w) => DropdownMenuItem(
                            value: w.id, child: Text(w.displayName)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _workerId = v);
                      _loadDefaultServiceDuration();
                    },
                  ),

                const SizedBox(height: 8),

                // Service picker (minimal – using worker services)
                FutureBuilder<List<ProviderServiceItem>>(
                  future: _workerId == null
                      ? null
                      : _servicesSvc.getAllByWorker(_workerId!),
                  builder: (_, snap) {
                    final list = snap.data ?? const <ProviderServiceItem>[];
                    final items = list
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} • ${s.durationMinutes}m'),
                            ))
                        .toList();
                    return DropdownButtonFormField<String>(
                      value: list.any((s) => s.id == _serviceId)
                          ? _serviceId
                          : (list.isEmpty ? null : list.first.id),
                      decoration: const InputDecoration(labelText: 'Service'),
                      items: items,
                      onChanged: (v) {
                        final sel = list.firstWhere((s) => s.id == v);
                        setState(() {
                          _serviceId = sel.id;
                          _serviceDurationMin = sel.durationMinutes;
                        });
                        _loadSlots();
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.date ?? 'Date'),
                  subtitle: Text(_day.toIso8601String().split('T').first),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _day,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 0)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _day = picked);
                        await _loadSlots();
                      }
                    },
                  ),
                ),

                // Free slots
                _loadingSlots
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator()))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _free
                            .map((s) => ChoiceChip(
                                  label: Text(s),
                                  selected: _time == s,
                                  onSelected: (_) => setState(() => _time = s),
                                ))
                            .toList(),
                      ),

                const SizedBox(height: 12),

                Text(t.guest_details ?? 'Guest details',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _guestPhoneCtrl,
                  decoration: InputDecoration(labelText: t.phone ?? 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (t.required_field ?? 'Required')
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _guestNameCtrl,
                  decoration:
                      InputDecoration(labelText: t.first_name ?? 'Name'),
                ),

                const SizedBox(height: 16),

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
                        : Text(t.create ?? 'Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    if (_workerId == null || _serviceId == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(t.fill_all_fields ?? 'Please fill all required fields')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final cmd = NewAppointmentCmd(
        workerId: _workerId!,
        serviceId: _serviceId!,
        date: _day,
        startTime: _time!,
        guestPhone: _guestPhoneCtrl.text.trim(),
        guestName: _guestNameCtrl.text.trim().isEmpty
            ? null
            : _guestNameCtrl.text.trim(),
      );
      await AppointmentService().book(cmd);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
