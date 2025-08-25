import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../../../services/providers/provider_staff_service.dart';

class CreateBreakScreen extends StatefulWidget {
  final String? providerId;
  final List<StaffMember>? workers; // for provider view
  final String? fixedWorkerId; // for worker self view
  final DateTime? date;

  const CreateBreakScreen({
    super.key,
    required this.providerId,
    required this.workers,
    required this.fixedWorkerId,
    this.date,
  });

  @override
  State<CreateBreakScreen> createState() => _CreateBreakScreenState();
}

class _CreateBreakScreenState extends State<CreateBreakScreen> {
  final _dio = ApiService.client;
  final _form = GlobalKey<FormState>();

  String? _workerId;
  DateTime _day = DateTime.now();
  String? _startHHmm;
  String? _endHHmm;

  List<Map<String, dynamic>> _existing = [];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _day = widget.date ?? DateTime.now();
    _workerId = widget.fixedWorkerId ?? (widget.workers?.firstOrNull?.id);
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (_workerId == null) return;
    setState(() => _loading = true);
    try {
      final d = _day.toIso8601String().split('T').first;
      final r = await _dio.get(
        '/workers/public/availability/break/$_workerId',
        queryParameters: {'from': d, 'to': d},
      );
      _existing = ((r.data as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
          .where((m) => (m['date'] ?? m['day'] ?? '').toString().startsWith(d))
          .toList();
    } catch (_) {
      _existing = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteBreak(dynamic id) async {
    if (_workerId == null || id == null) return;
    try {
      await _dio.delete('/workers/availability/break/$_workerId/$id');
      await _loadExisting();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Break deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (_workerId == null || _startHHmm == null || _endHHmm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose worker, start and end time')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'date': _day.toIso8601String().split('T').first,
        'startTime': _startHHmm,
        'endTime': _endHHmm,
      };
      await _dio.post('/workers/availability/break/$_workerId', data: body);
      await _loadExisting();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Break saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _pick5mTime(String? initial) async {
    int h = 9, m = 0;
    if (initial != null && initial.contains(':')) {
      final p = initial.split(':');
      h = int.tryParse(p[0]) ?? 9;
      m = int.tryParse(p[1]) ?? 0;
    }
    return showDialog<String>(
      context: context,
      builder: (_) => _TimePicker5mDialog(initH: h, initM: m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workers = widget.workers;

    return Scaffold(
      appBar: AppBar(title: const Text('Add / Manage breaks')),
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
                  setState(() => _workerId = v);
                  await _loadExisting();
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
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _day = picked);
                    await _loadExisting();
                  }
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start'),
                    subtitle: Text(_startHHmm ?? '—'),
                    onTap: () async {
                      final v = await _pick5mTime(_startHHmm);
                      if (v != null) setState(() => _startHHmm = v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End'),
                    subtitle: Text(_endHHmm ?? '—'),
                    onTap: () async {
                      final v = await _pick5mTime(_endHHmm);
                      if (v != null) setState(() => _endHHmm = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save break'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Existing breaks',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              )),
            if (!_loading && _existing.isEmpty)
              const Text('No breaks for this day.'),
            ..._existing.map((m) {
              final id = m['id'];
              final st = (m['startTime'] ?? m['from'] ?? '').toString();
              final et = (m['endTime'] ?? m['to'] ?? '').toString();
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.free_breakfast_outlined),
                  title: Text('${st.substring(0, 5)} – ${et.substring(0, 5)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFD92D20)),
                    onPressed: () => _deleteBreak(id),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ======= 5-minute wheel picker =======
class _TimePicker5mDialog extends StatefulWidget {
  final int initH, initM;
  const _TimePicker5mDialog({required this.initH, required this.initM});

  @override
  State<_TimePicker5mDialog> createState() => _TimePicker5mDialogState();
}

class _TimePicker5mDialogState extends State<_TimePicker5mDialog> {
  late FixedExtentScrollController _hCtl;
  late FixedExtentScrollController _mCtl;

  final List<int> _hours = List.generate(24, (i) => i);
  final List<int> _mins = List.generate(12, (i) => i * 5);

  @override
  void initState() {
    super.initState();
    _hCtl = FixedExtentScrollController(initialItem: widget.initH.clamp(0, 23));
    int initMIndex = (_mins.indexOf(widget.initM) == -1)
        ? (_mins.indexWhere((v) => v >= widget.initM))
        : _mins.indexOf(widget.initM);
    if (initMIndex < 0) initMIndex = 0;
    _mCtl = FixedExtentScrollController(initialItem: initMIndex);
  }

  @override
  void dispose() {
    _hCtl.dispose();
    _mCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick time (5-min)'),
      content: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _hCtl,
                physics: const FixedExtentScrollPhysics(),
                itemExtent: 36,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: _hours.length,
                  builder: (_, i) => Center(
                    child: Text(_hours[i].toString().padLeft(2, '0')),
                  ),
                ),
              ),
            ),
            const Text(':', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _mCtl,
                physics: const FixedExtentScrollPhysics(),
                itemExtent: 36,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: _mins.length,
                  builder: (_, i) => Center(
                    child: Text(_mins[i].toString().padLeft(2, '0')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final h = _hours[_hCtl.selectedItem].toString().padLeft(2, '0');
            final m = _mins[_mCtl.selectedItem].toString().padLeft(2, '0');
            Navigator.pop(context, '$h:$m');
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
