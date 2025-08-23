import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';

class ProviderWorkerAvailabilityScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  const ProviderWorkerAvailabilityScreen({
    super.key,
    required this.workerId,
    required this.workerName,
  });

  @override
  State<ProviderWorkerAvailabilityScreen> createState() =>
      _ProviderWorkerAvailabilityScreenState();
}

class _ProviderWorkerAvailabilityScreenState
    extends State<ProviderWorkerAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  final Dio _dio = ApiService.client;
  late final TabController _tabs = TabController(length: 3, vsync: this);

  // ---------- helpers ----------
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

  String _fmt(TimeOfDay? t) => t == null
      ? '—'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseLocalTime(String s) {
    final p = s.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p.elementAt(1)) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _durationIso(int minutes) => 'PT${minutes}M';
  int _durationToMinutes(String? iso) {
    if (iso == null || iso.isEmpty) return 0;
    final h = RegExp(r'(\d+)H').firstMatch(iso)?.group(1);
    final m = RegExp(r'(\d+)M').firstMatch(iso)?.group(1);
    return (int.tryParse(h ?? '0') ?? 0) * 60 + (int.tryParse(m ?? '0') ?? 0);
  }

  // ---------- WEEK (planned) ----------
  final List<_DayModel> _week = [
    _DayModel('MONDAY'),
    _DayModel('TUESDAY'),
    _DayModel('WEDNESDAY'),
    _DayModel('THURSDAY'),
    _DayModel('FRIDAY'),
    _DayModel('SATURDAY'),
    _DayModel('SUNDAY'),
  ].map((e) => _DayModel(e.day)).toList();

  bool _loadingWeek = false;
  bool _savingWeek = false;

  Future<void> _fetchWeek() async {
    setState(() => _loadingWeek = true);
    try {
      final r = await _dio
          .get('/workers/public/availability/planned/${widget.workerId}');
      final list = (r.data as List? ?? [])
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();

      for (final d in _week) {
        d.working = false;
        d.start = null;
        d.end = null;
        d.bufferMin = 0;
      }
      for (final m in list) {
        final day = m['day']?.toString() ?? '';
        final target =
            _week.firstWhere((e) => e.day == day, orElse: () => _week.first);
        target.working = true;
        target.start = _parseLocalTime(m['startTime'].toString());
        target.end = _parseLocalTime(m['endTime'].toString());
        target.bufferMin =
            _durationToMinutes(m['bufferBetweenAppointments']?.toString());
      }
      setState(() {});
    } finally {
      if (mounted) setState(() => _loadingWeek = false);
    }
  }

  Future<void> _saveWeek() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _savingWeek = true);
    try {
      final body = _week
          .where((d) => d.working && d.start != null && d.end != null)
          .map((d) {
        return {
          'day': d.day,
          'startTime': _fmt(d.start),
          'endTime': _fmt(d.end),
          'bufferBetweenAppointments': _durationIso(d.bufferMin),
        };
      }).toList();

      await _dio.post('/workers/availability/planned/${widget.workerId}',
          data: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.saved ?? 'Saved')));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } finally {
      if (mounted) setState(() => _savingWeek = false);
    }
  }

  void _copyMondayToAll({required bool onlyWeekdays}) {
    final t = AppLocalizations.of(context)!;
    final mon = _week.firstWhere((d) => d.day == 'MONDAY');
    if (!mon.working || mon.start == null || mon.end == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.not_set ?? 'Not set'),
      ));
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

  // ---------- EXCEPTIONS (actual) ----------
  DateTime _exDate = DateTime.now();
  bool _loadingEx = false;
  int? _exId;
  TimeOfDay? _exStart;
  TimeOfDay? _exEnd;
  int _exBufferMin = 0;

  Future<void> _fetchExceptionForDay() async {
    setState(() => _loadingEx = true);
    try {
      final d = DateUtils.dateOnly(_exDate);
      final date = _ymd(d);
      final r = await _dio.get(
          '/workers/public/availability/actual/${widget.workerId}',
          queryParameters: {'from': date, 'to': date});
      final list = (r.data as List? ?? []);
      if (list.isEmpty) {
        _exId = null;
        _exStart = null;
        _exEnd = null;
        _exBufferMin = 0;
      } else {
        final m = (list.first as Map).cast<String, dynamic>();
        _exId = (m['id'] as num?)?.toInt();
        _exStart = _parseLocalTime(m['startTime'].toString());
        _exEnd = _parseLocalTime(m['endTime'].toString());
        _exBufferMin =
            _durationToMinutes(m['bufferBetweenAppointments']?.toString());
      }
      setState(() {});
    } finally {
      if (mounted) setState(() => _loadingEx = false);
    }
  }

  Future<void> _saveException() async {
    final t = AppLocalizations.of(context)!;
    if (_exStart == null || _exEnd == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.not_set ?? 'Not set')));
      return;
    }
    setState(() => _loadingEx = true);
    try {
      final d = DateUtils.dateOnly(_exDate);
      final date = _ymd(d);
      final body = {
        'date': date,
        'startTime': _fmt(_exStart),
        'endTime': _fmt(_exEnd),
        'bufferBetweenAppointments': _durationIso(_exBufferMin),
      };
      await _dio.post('/workers/availability/actual/${widget.workerId}',
          data: body);
      await _fetchExceptionForDay();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.saved ?? 'Saved')));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } finally {
      if (mounted) setState(() => _loadingEx = false);
    }
  }

  Future<void> _deleteException() async {
    final t = AppLocalizations.of(context)!;
    if (_exId == null) return;
    setState(() => _loadingEx = true);
    try {
      await _dio
          .delete('/workers/availability/actual/${widget.workerId}/$_exId');
      await _fetchExceptionForDay();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.deleted ?? 'Deleted')));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } finally {
      if (mounted) setState(() => _loadingEx = false);
    }
  }

  // ---------- BREAKS ----------
  DateTime _brDate = DateTime.now();
  bool _loadingBr = false;
  List<_BreakItem> _breaks = [];
  TimeOfDay? _newBrStart;
  TimeOfDay? _newBrEnd;

  Future<void> _fetchBreaksForDay() async {
    setState(() => _loadingBr = true);
    try {
      final d = DateUtils.dateOnly(_brDate);
      final date = _ymd(d);
      final r = await _dio.get(
          '/workers/public/availability/break/${widget.workerId}',
          queryParameters: {'from': date, 'to': date});
      final list = (r.data as List? ?? []);
      _breaks = list.map((e) {
        final m = (e as Map).cast<String, dynamic>();
        return _BreakItem(
          id: (m['id'] as num?)?.toInt(),
          start: _parseLocalTime(m['startTime'].toString()),
          end: _parseLocalTime(m['endTime'].toString()),
        );
      }).toList();
      setState(() {});
    } finally {
      if (mounted) setState(() => _loadingBr = false);
    }
  }

  Future<void> _addBreak() async {
    final t = AppLocalizations.of(context)!;
    if (_newBrStart == null || _newBrEnd == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.not_set ?? 'Not set')));
      return;
    }
    setState(() => _loadingBr = true);
    try {
      final d = DateUtils.dateOnly(_brDate);
      final date = _ymd(d);
      final body = {
        'date': date,
        'startTime': _fmt(_newBrStart),
        'endTime': _fmt(_newBrEnd),
      };
      await _dio.post('/workers/availability/break/${widget.workerId}',
          data: body);
      _newBrStart = null;
      _newBrEnd = null;
      await _fetchBreaksForDay();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.break_added ?? 'Break added')));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } finally {
      if (mounted) setState(() => _loadingBr = false);
    }
  }

  Future<void> _deleteBreak(int id) async {
    setState(() => _loadingBr = true);
    try {
      await _dio.delete('/workers/availability/break/${widget.workerId}/$id');
      await _fetchBreaksForDay();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message ?? e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('HTTP $code: $body')));
    } finally {
      if (mounted) setState(() => _loadingBr = false);
    }
  }

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();
    _fetchWeek();
    _fetchExceptionForDay();
    _fetchBreaksForDay();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.working_hours ?? 'Working hours'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: t.tab_week ?? 'Week'),
            Tab(text: t.tab_exceptions ?? 'Exceptions'),
            Tab(text: t.tab_breaks ?? 'Breaks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildWeekTab(),
          _buildExceptionsTab(),
          _buildBreaksTab(),
        ],
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: _savingWeek ? null : _saveWeek,
              icon: const Icon(Icons.save_outlined),
              label: Text(_savingWeek
                  ? (t.saving ?? 'Saving…')
                  : (t.action_save ?? 'Save')),
            )
          : null,
    );
  }

  // ---------- UI: WEEK ----------
  Widget _buildWeekTab() {
    final t = AppLocalizations.of(context)!;
    if (_loadingWeek) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // copy helpers
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
                              final next = await _pickTime24(d.start ??
                                  const TimeOfDay(hour: 9, minute: 0));
                              if (next != null) setState(() => d.start = next);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeField(
                            label: t.end ?? 'End',
                            value: _fmt(d.end),
                            onTap: () async {
                              final next = await _pickTime24(d.end ??
                                  const TimeOfDay(hour: 18, minute: 0));
                              if (next != null) setState(() => d.end = next);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _BufferDropdown(
                      label: t.buffer_min_short ?? 'Buffer (min)',
                      value: d.bufferMin,
                      onChanged: (v) => setState(() => d.bufferMin = v),
                    ),
                  ],
                ],
              ),
            ),
          )
      ],
    );
  }

  // ---------- UI: EXCEPTIONS ----------
  Widget _buildExceptionsTab() {
    final t = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Text(_ymd(_exDate),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: _exDate,
                );
                if (picked != null) {
                  setState(() => _exDate = picked);
                  _fetchExceptionForDay();
                }
              },
            ),
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchExceptionForDay),
          ],
        ),
        const SizedBox(height: 8),
        Text(t.tab_exceptions ?? 'Exceptions',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: t.start ?? 'Start',
                value: _fmt(_exStart),
                onTap: () async {
                  final t0 = await _pickTime24(
                      _exStart ?? const TimeOfDay(hour: 9, minute: 0));
                  if (t0 != null) setState(() => _exStart = t0);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: t.end ?? 'End',
                value: _fmt(_exEnd),
                onTap: () async {
                  final t1 = await _pickTime24(
                      _exEnd ?? const TimeOfDay(hour: 18, minute: 0));
                  if (t1 != null) setState(() => _exEnd = t1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BufferDropdown(
          label: t.buffer_min_short ?? 'Buffer (min)',
          value: _exBufferMin,
          onChanged: (v) => setState(() => _exBufferMin = v),
        ),
        const Divider(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _loadingEx ? null : _saveException,
            icon: const Icon(Icons.save_outlined),
            label: Text(_loadingEx
                ? (t.saving ?? 'Saving…')
                : (t.action_save ?? 'Save')),
          ),
        ),
        const SizedBox(height: 8),
        if (_exId != null)
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              onPressed: _loadingEx ? null : _deleteException,
              label: Text(t.delete_exception ?? 'Delete this exception'),
            ),
          ),
      ],
    );
  }

  // ---------- UI: BREAKS ----------
  Widget _buildBreaksTab() {
    final t = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Text(_ymd(_brDate),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: _brDate,
                );
                if (picked != null) {
                  setState(() => _brDate = picked);
                  _fetchBreaksForDay();
                }
              },
            ),
            IconButton(
                icon: const Icon(Icons.refresh), onPressed: _fetchBreaksForDay),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingBr)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(),
          ))
        else if (_breaks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(t.no_breaks_day ?? 'No breaks for this day.'),
          )
        else
          ..._breaks.map((b) => Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text('${_fmt(b.start)} — ${_fmt(b.end)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: b.id == null ? null : () => _deleteBreak(b.id!),
                  ),
                ),
              )),
        const Divider(height: 24),
        Text(t.add_break ?? 'Add break',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: t.start ?? 'Start',
                value: _fmt(_newBrStart),
                onTap: () async {
                  final t0 = await _pickTime24(
                      _newBrStart ?? const TimeOfDay(hour: 13, minute: 0));
                  if (t0 != null) setState(() => _newBrStart = t0);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: t.end ?? 'End',
                value: _fmt(_newBrEnd),
                onTap: () async {
                  final t1 = await _pickTime24(
                      _newBrEnd ?? const TimeOfDay(hour: 14, minute: 0));
                  if (t1 != null) setState(() => _newBrEnd = t1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _loadingBr ? null : _addBreak,
            icon: const Icon(Icons.add),
            label: Text(_loadingBr
                ? (t.saving ?? 'Saving…')
                : (t.add_break ?? 'Add break')),
          ),
        ),
      ],
    );
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

class _DayModel {
  final String day;
  bool working = false;
  TimeOfDay? start;
  TimeOfDay? end;
  int bufferMin = 0;
  _DayModel(this.day);
}

class _BreakItem {
  final int? id;
  final TimeOfDay start;
  final TimeOfDay end;
  _BreakItem({required this.id, required this.start, required this.end});
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
