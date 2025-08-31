import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../services/api_service.dart';
import '../../../services/providers/provider_staff_service.dart';

// l10n
import '../../../l10n/app_localizations.dart';

/// Stormy Morning palette
const _kDark = Color(0xFF384959);
const _kSteel = Color(0xFF6A89A7);
const _kSky = Color(0xFF88BDF2);
const _kIce = Color(0xFFBDDDFC);

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
    _workerId = widget.fixedWorkerId ??
        ((widget.workers != null && widget.workers!.isNotEmpty)
            ? widget.workers!.first.id
            : null);
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
          .where((m) => (m['date'] ?? m['day'] ?? '').toString().startsWith(d))
          .toList();
    } catch (_) {
      _existing = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteBreak(dynamic id) async {
    final l10n = AppLocalizations.of(context)!;
    if (_workerId == null || id == null) return;
    try {
      await _dio.delete('/workers/availability/break/$_workerId/$id');
      await _loadExisting();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.breakDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.breakDeleteFailed('$e'))),
      );
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_workerId == null || _startHHmm == null || _endHHmm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.breakRequiredFields)),
      );
      return;
    }
    // start < end
    final s = _toMinutes(_startHHmm!);
    final e = _toMinutes(_endHHmm!);
    if (e <= s) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.breakEndAfterStart)),
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
      setState(() {
        _startHHmm = null;
        _endHHmm = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.breakSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.breakSaveFailed('$e'))),
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
    final l10n = AppLocalizations.of(context)!;
    final workers = widget.workers;
    final isProviderView = workers != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.breaksTitle),
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (isProviderView)
              _SectionCard(
                child: DropdownButtonFormField<String>(
                  value: _workerId,
                  decoration: InputDecoration(
                    labelText: l10n.workerLabel,
                    floatingLabelStyle: const TextStyle(
                        color: _kDark, fontWeight: FontWeight.w600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: _kIce.withOpacity(.45),
                  ),
                  items: workers!
                      .map((w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.displayName,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    setState(() => _workerId = v);
                    await _loadExisting();
                  },
                ),
              ),
            _SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.dateLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: _kDark)),
                      subtitle: Text(
                        _day.toIso8601String().split('T').first,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.today),
                    label: Text(l10n.todayButton),
                    onPressed: () async {
                      setState(() => _day = DateTime.now());
                      await _loadExisting();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _kSky.withOpacity(.25),
                      foregroundColor: _kDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
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
                    style: IconButton.styleFrom(
                      backgroundColor: _kDark,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.calendar_today),
                  ),
                ],
              ),
            ),
            _SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: l10n.timeStartLabel,
                      value: _startHHmm,
                      onTap: () async {
                        final v = await _pick5mTime(_startHHmm);
                        if (v != null) setState(() => _startHHmm = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
                      label: l10n.timeEndLabel,
                      value: _endHHmm,
                      onTap: () async {
                        final v = await _pick5mTime(_endHHmm);
                        if (v != null) setState(() => _endHHmm = v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.free_breakfast),
                label: Text(_saving ? l10n.savingEllipsis : l10n.saveBreakBtn),
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.list_alt, size: 18, color: _kDark),
                const SizedBox(width: 6),
                Text(l10n.existingBreaksTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _kDark)),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!_loading && _existing.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kIce.withOpacity(.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(l10n.noBreaksForDay,
                    style: const TextStyle(color: _kDark)),
              ),
            ..._existing.map((m) {
              final id = m['id'];
              final st = (m['startTime'] ?? m['from'] ?? '').toString();
              final et = (m['endTime'] ?? m['to'] ?? '').toString();
              final s = st.length >= 5 ? st.substring(0, 5) : st;
              final e = et.length >= 5 ? et.substring(0, 5) : et;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _kSteel.withOpacity(.35)),
                ),
                color: _kIce.withOpacity(.35),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _kSky.withOpacity(.3),
                    foregroundColor: _kDark,
                    child: const Icon(Icons.free_breakfast_outlined),
                  ),
                  title: Text('$s – $e',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    tooltip: AppLocalizations.of(context)!.deleteAction,
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

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }
}

/* ---------- Small UI helpers ---------- */

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kIce.withOpacity(.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSteel.withOpacity(.35)),
      ),
      child: child,
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _TimeTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kSteel.withOpacity(.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: _kDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _kDark,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value ?? '—', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

/* ---------- 5-minute wheel picker ---------- */

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
    int initMIndex = (!_mins.contains(widget.initM))
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.pickTime5mTitle),
      content: SizedBox(
        height: 220,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _kIce.withOpacity(.45),
            borderRadius: BorderRadius.circular(12),
          ),
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
                      child: Text(
                        _hours[i].toString().padLeft(2, '0'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              const Text(':', style: TextStyle(fontSize: 18, color: _kDark)),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _mCtl,
                  physics: const FixedExtentScrollPhysics(),
                  itemExtent: 36,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _mins.length,
                    builder: (_, i) => Center(
                      child: Text(
                        _mins[i].toString().padLeft(2, '0'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              Text(l10n.commonCancel, style: const TextStyle(color: _kSteel)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kDark),
          onPressed: () {
            final h = _hours[_hCtl.selectedItem].toString().padLeft(2, '0');
            final m = _mins[_mCtl.selectedItem].toString().padLeft(2, '0');
            Navigator.pop(context, '$h:$m');
          },
          child: Text(l10n.commonOk),
        ),
      ],
    );
  }
}
