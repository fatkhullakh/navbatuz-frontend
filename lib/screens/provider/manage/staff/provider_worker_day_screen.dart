import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';

class ProviderWorkerDayScreen extends StatefulWidget {
  final String workerId;
  final String day; // MONDAY..SUNDAY
  const ProviderWorkerDayScreen(
      {super.key, required this.workerId, required this.day});

  @override
  State<ProviderWorkerDayScreen> createState() =>
      _ProviderWorkerDayScreenState();
}

class _ProviderWorkerDayScreenState extends State<ProviderWorkerDayScreen> {
  final _dio = ApiService.client;
  bool _loading = true;
  bool _saving = false;
  bool _working = false;
  String? _start; // HH:mm
  String? _end;

  DateTime _breakDate = DateTime.now();
  bool _loadingBreaks = true;
  final List<_Break> _breaks = [];

  @override
  void initState() {
    super.initState();
    _loadPlanned();
    _loadBreaks();
  }

  String _hhmm(String hhmmss) {
    final p = hhmmss.split(':');
    return p.length >= 2
        ? '${p[0].padLeft(2, '0')}:${p[1].padLeft(2, '0')}'
        : hhmmss;
  }

  Future<void> _loadPlanned() async {
    setState(() {
      _loading = true;
    });
    try {
      final r = await _dio
          .get('/workers/public/availability/planned/${widget.workerId}');
      final list = (r.data as List?) ?? [];
      final mine = list
          .whereType<Map>()
          .firstWhere(
            (m) => (m['day']?.toString() ?? '') == widget.day,
            orElse: () => const {},
          )
          .cast<String, dynamic>();
      if (mine.isNotEmpty) {
        _working = true;
        _start = _hhmm((mine['startTime'] ?? '').toString());
        _end = _hhmm((mine['endTime'] ?? '').toString());
      } else {
        _working = false;
        _start = null;
        _end = null;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePlanned() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Load all, replace just this day, and send FULL list to avoid deleting others
      final r = await _dio
          .get('/workers/public/availability/planned/${widget.workerId}');
      final list = (r.data as List?) ?? [];

      // Build map by day
      final byDay = <String, Map<String, dynamic>>{};
      for (final it in list.whereType<Map>()) {
        final m = it.cast<String, dynamic>();
        byDay[m['day'].toString()] = {
          'day': m['day'],
          'startTime': m['startTime'],
          'endTime': m['endTime'],
          'bufferBetweenAppointments': m['bufferBetweenAppointments'] ?? 'PT0M',
        };
      }

      if (_working && _start != null && _end != null) {
        byDay[widget.day] = {
          'day': widget.day,
          'startTime': '$_start:00',
          'endTime': '$_end:00',
          'bufferBetweenAppointments': 'PT0M',
        };
      } else {
        byDay.remove(widget.day);
      }

      await _dio.post('/workers/availability/planned/${widget.workerId}',
          data: byDay.values.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.saved ?? 'Saved')));
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadBreaks() async {
    setState(() => _loadingBreaks = true);
    try {
      final d = _fmtDate(_breakDate);
      final r = await _dio.get(
          '/workers/public/availability/break/${widget.workerId}',
          queryParameters: {'from': d, 'to': d});
      final list = (r.data as List?) ?? [];
      _breaks
        ..clear()
        ..addAll(list.whereType<Map>().map((m0) {
          final m = m0.cast<String, dynamic>();
          return _Break(
            date: DateTime.parse(m['date']),
            start: _hhmm((m['startTime'] ?? '').toString()),
            end: _hhmm((m['endTime'] ?? '').toString()),
          );
        }));
    } finally {
      if (mounted) setState(() => _loadingBreaks = false);
    }
  }

  Future<void> _addBreak() async {
    final start = await _pickTime(
        context, AppLocalizations.of(context)!.start ?? 'Start', '12:00');
    if (start == null) return;
    final end = await _pickTime(
        context, AppLocalizations.of(context)!.end ?? 'End', '13:00');
    if (end == null) return;
    final payload = [
      {
        'date': _fmtDate(_breakDate),
        'startTime': '$start:00',
        'endTime': '$end:00',
      }
    ];
    await _dio.post('/workers/availability/break/${widget.workerId}',
        data: payload);
    await _loadBreaks();
  }

  Future<void> _removeBreak(int index) async {
    // API deletes by sending list for a date (overwrites). Remove from local then submit.
    final d = _fmtDate(_breakDate);
    final remain = List<_Break>.from(_breaks)..removeAt(index);
    final payload = remain
        .map((b) => {
              'date': d,
              'startTime': '${b.start}:00',
              'endTime': '${b.end}:00',
            })
        .toList();
    await _dio.post('/workers/availability/break/${widget.workerId}',
        data: payload);
    await _loadBreaks();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_localizeDay(context, widget.day)}'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _savePlanned,
            child: Text(t.action_save ?? 'Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                SwitchListTile(
                  value: _working,
                  onChanged: (v) => setState(() => _working = v),
                  title: Text(t.working_this_day ?? 'Working this day'),
                ),
                if (_working) ...[
                  _TimeRow(
                    label: t.start ?? 'Start',
                    value: _start,
                    onTap: () async {
                      final v = await _pickTime(
                          context, t.start ?? 'Start', _start ?? '09:00');
                      if (v != null) setState(() => _start = v);
                    },
                  ),
                  const SizedBox(height: 6),
                  _TimeRow(
                    label: t.end ?? 'End',
                    value: _end,
                    onTap: () async {
                      final v = await _pickTime(
                          context, t.end ?? 'End', _end ?? '18:00');
                      if (v != null) setState(() => _end = v);
                    },
                  ),
                ],
                const SizedBox(height: 18),
                Text(t.breaks_title ?? 'Breaks',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _breakDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _breakDate = picked);
                            await _loadBreaks();
                          }
                        },
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                            '${t.select_date ?? 'Select date'}: ${_fmtDate(_breakDate)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _addBreak,
                      icon: const Icon(Icons.add),
                      label: Text(t.add_break ?? 'Add break'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loadingBreaks)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator()))
                else
                  ..._breaks.asMap().entries.map((e) => Card(
                        elevation: 0,
                        child: ListTile(
                          leading: const Icon(Icons.pause_circle_outline),
                          title: Text('${e.value.start} – ${e.value.end}'),
                          subtitle: Text(_fmtDate(e.value.date)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeBreak(e.key),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }

  String _localizeDay(BuildContext context, String d) {
    final t = AppLocalizations.of(context)!;
    switch (d) {
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
        return d;
    }
  }

  Future<String?> _pickTime(
      BuildContext context, String title, String initial) async {
    int h = int.tryParse(initial.split(':').first) ?? 9;
    int m = int.tryParse(initial.split(':').elementAt(1)) ?? 0;
    return await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context,
                            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'),
                        child: Text(AppLocalizations.of(context)!.action_done ??
                            'Done'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 40,
                          scrollController:
                              FixedExtentScrollController(initialItem: h),
                          onSelectedItemChanged: (i) => h = i,
                          children: List.generate(
                              24,
                              (i) => Center(
                                  child: Text(i.toString().padLeft(2, '0')))),
                        ),
                      ),
                      const Text(':', style: TextStyle(fontSize: 22)),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 40,
                          scrollController:
                              FixedExtentScrollController(initialItem: m),
                          onSelectedItemChanged: (i) => m = i,
                          children: List.generate(
                              60,
                              (i) => Center(
                                  child: Text(i.toString().padLeft(2, '0')))),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Break {
  final DateTime date;
  final String start;
  final String end;
  _Break({required this.date, required this.start, required this.end});
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _TimeRow(
      {required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(label),
      subtitle:
          Text(value ?? (AppLocalizations.of(context)!.not_set ?? 'Not set')),
      trailing: const Icon(Icons.edit_outlined),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.white,
    );
  }
}
