import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class ProviderBusinessHoursScreen extends StatefulWidget {
  final String providerId;
  const ProviderBusinessHoursScreen({super.key, required this.providerId});

  @override
  State<ProviderBusinessHoursScreen> createState() =>
      _ProviderBusinessHoursScreenState();
}

class _ProviderBusinessHoursScreenState
    extends State<ProviderBusinessHoursScreen> {
  // Simple mock state per weekday
  final _days = <_DayRow>[
    _DayRow('MONDAY'),
    _DayRow('TUESDAY'),
    _DayRow('WEDNESDAY'),
    _DayRow('THURSDAY'),
    _DayRow('FRIDAY'),
    _DayRow('SATURDAY'),
    _DayRow('SUNDAY'),
  ];
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_safe(t, null, 'Working hours'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          ..._days.map((d) => Card(
                elevation: 0,
                child: ListTile(
                  title: Text(_localizeDay(context, d.day)),
                  subtitle: d.closed
                      ? Text(_safe(t, null, 'Closed'))
                      : Text('${d.start ?? '--:--'} – ${d.end ?? '--:--'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: !d.closed,
                        onChanged: (on) => setState(() => d.closed = !on),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: d.closed
                            ? null
                            : () async {
                                final range =
                                    await _pickRange(context, d.start, d.end);
                                if (range == null) return;
                                setState(() {
                                  d.start = range.$1;
                                  d.end = range.$2;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        // TODO: persist hours to backend
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_safe(t, null, 'Saved'))));
                        Navigator.pop(context);
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(
                  _saving ? _safe(t, null, 'Saving…') : _safe(t, null, 'Save')),
            ),
          ),
        ],
      ),
    );
  }

  String _localizeDay(BuildContext context, String serverDay) {
    const map = {
      'MONDAY': 1,
      'TUESDAY': 2,
      'WEDNESDAY': 3,
      'THURSDAY': 4,
      'FRIDAY': 5,
      'SATURDAY': 6,
      'SUNDAY': 7,
    };
    final wd = map[serverDay.toUpperCase()] ?? 1;
    final now = DateTime.now();
    final ref = now.add(Duration(days: (wd - now.weekday) % 7));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final name = MaterialLocalizations.of(context)
        .formatFullDate(ref)
        .split(',') // crude but locale-friendly
        .first;
    return name[0].toUpperCase() + name.substring(1);
  }

  Future<(String, String)?> _pickRange(
      BuildContext context, String? s, String? e) async {
    final start = await showTimePicker(
      context: context,
      initialTime: _parse(s) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null) return null;
    final end = await showTimePicker(
      context: context,
      initialTime: _parse(e) ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (end == null) return null;
    return (_fmt(start), _fmt(end));
  }

  TimeOfDay? _parse(String? hhmm) {
    if (hhmm == null) return null;
    final p = hhmm.split(':');
    if (p.length < 2) return null;
    return TimeOfDay(
        hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _safe(AppLocalizations t, String? maybe, String fallback) =>
      maybe ?? fallback;
}

class _DayRow {
  final String day; // MONDAY...
  bool closed = false;
  String? start;
  String? end;
  _DayRow(this.day);
}
