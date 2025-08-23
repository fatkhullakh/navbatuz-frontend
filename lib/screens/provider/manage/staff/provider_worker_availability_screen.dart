import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import 'provider_worker_day_screen.dart';

class ProviderWorkerAvailabilityScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  const ProviderWorkerAvailabilityScreen(
      {super.key, required this.workerId, required this.workerName});

  @override
  State<ProviderWorkerAvailabilityScreen> createState() =>
      _ProviderWorkerAvailabilityScreenState();
}

class _ProviderWorkerAvailabilityScreenState
    extends State<ProviderWorkerAvailabilityScreen> {
  final _dio = ApiService.client;
  bool _loading = true;

  final _byDay = <String, _Row>{
    'MONDAY': _Row('MONDAY'),
    'TUESDAY': _Row('TUESDAY'),
    'WEDNESDAY': _Row('WEDNESDAY'),
    'THURSDAY': _Row('THURSDAY'),
    'FRIDAY': _Row('FRIDAY'),
    'SATURDAY': _Row('SATURDAY'),
    'SUNDAY': _Row('SUNDAY'),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _dio
          .get('/workers/public/availability/planned/${widget.workerId}');
      final list = (r.data as List?) ?? [];
      for (final k in _byDay.keys) {
        _byDay[k] = _Row(k);
      }
      for (final it in list.whereType<Map>()) {
        final m = it.cast<String, dynamic>();
        final d = (m['day'] ?? '').toString();
        final row = _byDay[d];
        if (row != null) {
          row.working = true;
          row.start = _hhmm((m['startTime'] ?? '').toString());
          row.end = _hhmm((m['endTime'] ?? '').toString());
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _hhmm(String hhmmss) {
    final p = hhmmss.split(':');
    return p.length >= 2
        ? '${p[0].padLeft(2, '0')}:${p[1].padLeft(2, '0')}'
        : hhmmss;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${t.working_hours ?? 'Working hours'} – ${widget.workerName}'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: _byDay.values.map((row) {
                final subtitle = row.working
                    ? ((row.start != null && row.end != null)
                        ? '${row.start} – ${row.end}'
                        : (t.not_set ?? 'Not set'))
                    : (t.closed ?? 'Closed');
                return Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(_localizeDay(context, row.day)),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderWorkerDayScreen(
                                workerId: widget.workerId, day: row.day),
                          ));
                      if (changed == true) _load();
                    },
                  ),
                );
              }).toList(),
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
}

class _Row {
  final String day;
  bool working = false;
  String? start;
  String? end;
  _Row(this.day);
}
