import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';

class ProviderWorkerInviteScreen extends StatefulWidget {
  final String providerId;
  const ProviderWorkerInviteScreen({super.key, required this.providerId});

  @override
  State<ProviderWorkerInviteScreen> createState() =>
      _ProviderWorkerInviteScreenState();
}

class _ProviderWorkerInviteScreenState
    extends State<ProviderWorkerInviteScreen> {
  final Dio _dio = ApiService.client;

  // stepper
  int _step = 0;

  // personal / contact
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _gender; // backend enum: MALE/FEMALE/OTHER
  String? _workerType; // backend enum
  DateTime? _dob; // optional

  // services
  bool _loadingServices = false;
  final List<_ServiceItem> _services = [];
  final Set<String> _selectedServiceIds = {};

  // planned week (applied once when owner opens the Week step)
  final List<_DayModel> _week = [
    _DayModel('MONDAY'),
    _DayModel('TUESDAY'),
    _DayModel('WEDNESDAY'),
    _DayModel('THURSDAY'),
    _DayModel('FRIDAY'),
    _DayModel('SATURDAY'),
    _DayModel('SUNDAY'),
  ];
  bool _weekDefaultsApplied = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    setState(() => _loadingServices = true);
    try {
      final r = await _dio.get('/services/provider/all/${widget.providerId}');
      final list = (r.data as List? ?? [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

      _services
        ..clear()
        ..addAll(list.map((m) => _ServiceItem(
              id: m['id']?.toString() ?? '',
              name: (m['name'] ?? '').toString(),
              active: (m['isActive'] as bool?) ?? true,
            )));
      setState(() {});
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  // ---------- time + date helpers ----------
  Future<TimeOfDay?> _pickTime24(TimeOfDay initial) async {
    final t = AppLocalizations.of(context)!;
    TimeOfDay? selected;
    DateTime temp = DateTime(0, 1, 1, initial.hour, initial.minute);

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(t.select_time ?? 'Select time',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                minuteInterval: 5, // <-- 5-min steps
                initialDateTime: temp,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: () {
                    selected = TimeOfDay(hour: temp.hour, minute: temp.minute);
                    Navigator.pop(ctx);
                  },
                  child: Text(t.action_done ?? 'Done'),
                ),
              ),
            )
          ],
        ),
      ),
    );
    return selected;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 100, 1, 1);
    final last = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _fmt(TimeOfDay? t) =>
      t == null ? '—' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime? d) =>
      d == null ? '—' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _durationIso(int minutes) => 'PT${minutes}M';

  // ---------- copy helpers ----------
  void _copyMondayToAll({required bool onlyWeekdays}) {
    final t = AppLocalizations.of(context)!;
    final mon = _week.firstWhere((d) => d.day == 'MONDAY');
    if (!mon.working || mon.start == null || mon.end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.not_set ?? 'Not set')),
      );
      return;
    }
    for (final d in _week) {
      if (d.day == 'MONDAY') continue;
      if (onlyWeekdays && (d.day == 'SATURDAY' || d.day == 'SUNDAY')) continue;
      d.working = true;
      d.start = mon.start;
      d.end = mon.end;
      d.bufferMin = mon.bufferMin;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(onlyWeekdays
          ? (t.copied_mon_fri ?? 'Copied Monday to Mon–Fri')
          : (t.copied_mon_all ?? 'Copied Monday to all days')),
    ));
  }

  // ---------- defaults for week (applied once on entering Week step) ----------
  void _applyWeekDefaultsIfNeeded() {
    if (_weekDefaultsApplied) return;
    // Mon–Fri 10:00–20:00, buffer 0
    for (final d in _week) {
      final isWeekday = !{'SATURDAY', 'SUNDAY'}.contains(d.day);
      d.working = isWeekday;
      d.start = isWeekday ? const TimeOfDay(hour: 10, minute: 0) : null;
      d.end = isWeekday ? const TimeOfDay(hour: 20, minute: 0) : null;
      d.bufferMin = 0;
    }
    _weekDefaultsApplied = true;
  }

  // ---------- submit ----------
  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      setState(() => _step = 0);
      return;
    }
    if (_workerType == null || _workerType!.isEmpty) {
      setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.required ?? 'Required')));
      return;
    }

    setState(() => _saving = true);
    try {
      // 1) Create user with required defaults: language RU, country UZ
      final tempPassword = _generatePassword();
      final registerBody = {
        'name': _nameCtrl.text.trim(),
        'surname': _surnameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'gender': _gender,                 // may be null
        'language': 'RU',                  // <-- default to Russian
        'country': 'UZ',                   // <-- default to UZ
        'dateOfBirth': _dob == null ? null : _fmtDate(_dob),
        'role': 'WORKER',
        'password': tempPassword,          // OK if backend ignores and generates itself
      };

      final regRes = await _dio.post('/auth/register', data: registerBody);
      final userId = _extractId(regRes.data);
      if (userId == null) {
        throw Exception('User id not returned from /auth/register');
      }

      // 2) Create worker
      final workerRes = await _dio.post('/workers', data: {
        'user': userId,
        'provider': widget.providerId,
        'workerType': _workerType,
      });
      final workerId =
          _extractId(workerRes.data) ?? workerRes.data['id']?.toString();
      if (workerId == null) {
        throw Exception('Worker id not returned from /workers');
      }

      // 3) Assign services
      if (_selectedServiceIds.isNotEmpty) {
        await Future.wait(_selectedServiceIds
            .map((sid) => _dio.put('/services/$sid/add-worker/$workerId')));
      }

      // 4) Save planned availability
      final planned = _week
          .where((d) => d.working && d.start != null && d.end != null)
          .map((d) => {
                'day': d.day,
                'startTime': _fmt(d.start),
                'endTime': _fmt(d.end),
                'bufferBetweenAppointments': _durationIso(d.bufferMin),
              })
          .toList();
      if (planned.isNotEmpty) {
        await _dio.post('/workers/availability/planned/$workerId',
            data: planned);
      }

      // 5) Best-effort invite email
      try {
        await _dio.post('/auth/forgot-password',
            data: {'email': _emailCtrl.text.trim()});
      } catch (_) {
        // ignore if not configured
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(t.invite_sent_title ?? 'Invitation sent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.login_email ?? 'Login (email)'}: ${_emailCtrl.text.trim()}'),
              const SizedBox(height: 6),
              Text('${t.temp_password ?? 'Temporary password'}: $tempPassword'),
              const SizedBox(height: 8),
              Text(
                t.invite_note_change_password ??
                    'They will be asked to change the password on first login.',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.action_done ?? 'Done'),
            ),
          ],
        ),
      );

      Navigator.pop(context, true);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body =
          e.response?.data?.toString() ?? e.message ?? e.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _generatePassword() {
    const alphabet =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#\$%';
    final rnd = Random.secure();
    return List.generate(12, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
  }

  String? _extractId(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map) {
        if (data['id'] != null) return data['id'].toString();
        if (data['userId'] != null) return data['userId'].toString();
        if (data['data'] is Map && (data['data']['id'] != null)) {
          return data['data']['id'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final steps = [
      Step(
        title: Text(t.step_personal ?? 'Personal & contact'),
        isActive: _step >= 0,
        content: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: t.provider_name ?? 'Name',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (t.required ?? 'Required')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _surnameCtrl,
                      decoration: InputDecoration(
                        labelText: t.surname ?? 'Surname',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (t.required ?? 'Required')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: t.email ?? 'Email',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return t.required ?? 'Required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(s)) {
                          return t.invalid ?? 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: t.phone ?? 'Phone',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EnumDropdown(
                      value: _gender,
                      label: t.gender ?? 'Gender',
                      items: const ['MALE', 'FEMALE', 'OTHER'],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EnumDropdown(
                      value: _workerType,
                      label: t.worker_type ?? 'Worker type',
                      items: const [
                        'DOCTOR',
                        'BARBER',
                        'THERAPIST',
                        'TRAINER',
                        'MASTER'
                      ],
                      onChanged: (v) => setState(() => _workerType = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDob,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: t.date_of_birth ?? 'Date of birth (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.event_outlined),
                  ),
                  child: Text(_fmtDate(_dob)),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  // defaults shown, not editable here
                  '${t.language ?? 'Language'}: RU • ${t.country ?? 'Country'}: UZ',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
      Step(
        title: Text(t.services ?? 'Services'),
        isActive: _step >= 1,
        content: _loadingServices
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                children: [
                  if (_services.isEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(t.provider_no_services ?? 'No services.'),
                    )
                  else
                    ..._services.map(
                      (s) => CheckboxListTile(
                        value: _selectedServiceIds.contains(s.id),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedServiceIds.add(s.id);
                            } else {
                              _selectedServiceIds.remove(s.id);
                            }
                          });
                        },
                        title: Text(s.name.isEmpty ? '—' : s.name),
                        subtitle: s.active
                            ? Text(t.active ?? 'Active')
                            : Text(t.closed ?? 'Inactive'),
                      ),
                    ),
                ],
              ),
      ),
      Step(
        title: Text(t.tab_week ?? 'Week'),
        isActive: _step >= 2,
        content: Builder(
          builder: (context) {
            _applyWeekDefaultsIfNeeded(); // apply defaults once
            return Column(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.content_copy),
                      onPressed: () => _copyMondayToAll(onlyWeekdays: false),
                      label: Text(t.copy_mon_all ?? 'Copy Mon → All'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.content_copy),
                      onPressed: () => _copyMondayToAll(onlyWeekdays: true),
                      label: Text(t.copy_mon_fri ?? 'Copy Mon → Fri'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final d in _week)
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_dayLabel(d.day, t)),
                            value: d.working,
                            onChanged: (v) => setState(() => d.working = v),
                          ),
                          if (d.working) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _TimeField(
                                    label: t.start ?? 'Start',
                                    value: _fmt(d.start),
                                    onTap: () async {
                                      final next = await _pickTime24(
                                          d.start ??
                                              const TimeOfDay(
                                                  hour: 10, minute: 0));
                                      if (next != null) {
                                        setState(() => d.start = next);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _TimeField(
                                    label: t.end ?? 'End',
                                    value: _fmt(d.end),
                                    onTap: () async {
                                      final next = await _pickTime24(
                                          d.end ??
                                              const TimeOfDay(
                                                  hour: 20, minute: 0));
                                      if (next != null) {
                                        setState(() => d.end = next);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _BufferDropdown(
                              label:
                                  t.buffer_min_short ?? 'Buffer (min)',
                              value: d.bufferMin,
                              onChanged: (v) =>
                                  setState(() => d.bufferMin = v),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      Step(
        title: Text(t.reviewTitle ?? 'Review and confirm'),
        isActive: _step >= 3,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(t.provider_name ?? 'Name',
                '${_nameCtrl.text} ${_surnameCtrl.text}'),
            _kv(t.email ?? 'Email', _emailCtrl.text),
            _kv(t.phone ?? 'Phone',
                _phoneCtrl.text.isEmpty ? '—' : _phoneCtrl.text),
            _kv(t.gender ?? 'Gender', _gender ?? '—'),
            _kv(t.worker_type ?? 'Worker type', _workerType ?? '—'),
            _kv(t.date_of_birth ?? 'Date of birth', _fmtDate(_dob)),
            _kv('${t.language ?? 'Language'} / ${t.country ?? 'Country'}',
                'RU / UZ'),
            const Divider(),
            Text(t.services ?? 'Services',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_selectedServiceIds.isEmpty)
              Text(t.provider_no_services ?? 'No services.')
            else
              ..._services
                  .where((s) => _selectedServiceIds.contains(s.id))
                  .map((s) => Text('• ${s.name}')),
            const Divider(),
            Text(t.tab_week ?? 'Week',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ..._week.map((d) => Text(
                '${_dayLabel(d.day, t)}: ${d.working ? '${_fmt(d.start)}–${_fmt(d.end)}  (${t.buffer_min_short ?? 'Buffer (min)'} ${d.bufferMin})' : (t.closed ?? 'Closed')}')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: Text(_saving
                    ? (t.saving ?? 'Saving…')
                    : (t.action_invite ?? 'Create & send invite')),
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar:
          AppBar(title: Text(t.invite_worker_title ?? 'Add & Invite worker')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0) {
            if (_formKey.currentState!.validate()) {
              setState(() => _step = min(_step + 1, steps.length - 1));
            }
          } else {
            setState(() => _step = min(_step + 1, steps.length - 1));
          }
        },
        onStepCancel: () {
          setState(() => _step = max(0, _step - 1));
        },
        controlsBuilder: (ctx, d) => Row(
          children: [
            if (_step < steps.length - 1)
              FilledButton(
                onPressed: d.onStepContinue,
                child: Text(t.continueLabel ?? 'Continue'),
              ),
            if (_step < steps.length - 1) const SizedBox(width: 12),
            if (_step > 0)
              OutlinedButton(
                onPressed: d.onStepCancel,
                child: Text(t.common_back ?? 'Back'),
              ),
          ],
        ),
        steps: steps,
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
                child: Text(k, style: const TextStyle(color: Colors.black54))),
            Expanded(child: Text(v, textAlign: TextAlign.right)),
          ],
        ),
      );

  String _dayLabel(String day, AppLocalizations t) {
    switch (day) {
      case 'MONDAY':
        return t.dayMonday ?? 'Monday';
      case 'TUESDAY':
        return t.dayTuesday ?? 'Tuesday';
      case 'WEDNESDAY':
        return t.dayWednesday ?? 'Wednesday';
      case 'THURSDAY':
        return t.dayThursday ?? 'Thursday';
      case 'FRIDAY':
        return t.dayFriday ?? 'Friday';
      case 'SATURDAY':
        return t.daySaturday ?? 'Saturday';
      case 'SUNDAY':
        return t.daySunday ?? 'Sunday';
      default:
        return day;
    }
  }
}

class _EnumDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _EnumDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration:
          InputDecoration(border: const OutlineInputBorder(), labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : null,
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String id;
  final String name;
  final bool active;
  _ServiceItem({required this.id, required this.name, required this.active});
}

class _DayModel {
  final String day;
  bool working = false;
  TimeOfDay? start;
  TimeOfDay? end;
  int bufferMin = 0;
  _DayModel(this.day);
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeField(
      {required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(value),
      ),
    );
  }
}

class _BufferDropdown extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _BufferDropdown(
      {required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    const options = [0, 5, 10, 15, 20, 30];
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: options.contains(value) ? value : 0,
          items: options
              .map((m) => DropdownMenuItem<int>(
                    value: m,
                    child: Text(m.toString()),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
