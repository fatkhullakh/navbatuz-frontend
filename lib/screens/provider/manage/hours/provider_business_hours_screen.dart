import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';

/// ---------------- DTOs & API ----------------

class BusinessHourDto {
  final String day; // MONDAY..SUNDAY
  final String start; // "HH:mm"
  final String end; // "HH:mm"

  BusinessHourDto({required this.day, required this.start, required this.end});

  factory BusinessHourDto.fromJson(Map<String, dynamic> j) => BusinessHourDto(
        day: (j['day'] ?? '').toString(),
        start: _normalizeIn(j['startTime']?.toString()),
        end: _normalizeIn(j['endTime']?.toString()),
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        // backend LocalTime friendly
        'startTime': _normalizeOut(start),
        'endTime': _normalizeOut(end),
      };

  /// Accepts "HH:mm[:ss[.SSS]]" -> "HH:mm"
  static String _normalizeIn(String? v) {
    if (v == null || v.isEmpty) return '09:00';
    final p = v.split(':');
    final hh = (p.isNotEmpty ? p[0] : '00').padLeft(2, '0');
    final mm = (p.length > 1 ? p[1] : '00').padLeft(2, '0');
    return '$hh:$mm';
  }

  /// "HH:mm" -> "HH:mm:00"
  static String _normalizeOut(String v) {
    final p = v.split(':');
    final hh = (p.isNotEmpty ? p[0] : '00').padLeft(2, '0');
    final mm = (p.length > 1 ? p[1] : '00').padLeft(2, '0');
    return '$hh:$mm:00';
  }
}

class ProviderBusinessHoursApi {
  final Dio _dio = ApiService.client;

  Future<List<BusinessHourDto>> fetch(String providerId) async {
    final r = await _dio.get('/providers/public/$providerId/business-hours');
    final list = (r.data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((m) => BusinessHourDto.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> save(String providerId, List<BusinessHourDto> hours) async {
    await _dio.put('/providers/$providerId/business-hours',
        data: hours.map((e) => e.toJson()).toList());
  }
}

/// ---------------- UI ----------------

class ProviderBusinessHoursScreen extends StatefulWidget {
  final String providerId;
  const ProviderBusinessHoursScreen({super.key, required this.providerId});

  @override
  State<ProviderBusinessHoursScreen> createState() =>
      _ProviderBusinessHoursScreenState();
}

class _ProviderBusinessHoursScreenState
    extends State<ProviderBusinessHoursScreen> {
  final _api = ProviderBusinessHoursApi();

  // minute step for wheels
  static const int kMinuteStep = 15;

  final List<_DayRow> _rows = const [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ].map(_DayRow.new).toList();

  late Future<void> _future;
  bool _saving = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    _err = '';
    try {
      final server = await _api.fetch(widget.providerId);
      // default state
      for (final r in _rows) {
        r.closed = true;
        r.start = '09:00';
        r.end = '18:00';
      }
      // apply server
      for (final dto in server) {
        final row = _rows.firstWhere(
          (x) => x.day == dto.day,
          orElse: () => _rows.first,
        );
        row
          ..closed = false
          ..start = dto.start
          ..end = dto.end;
      }
      if (mounted) setState(() {});
    } catch (e) {
      _err = e.toString();
      if (mounted) setState(() {});
    }
  }

  Future<void> _refresh() async {
    final fut = _load();
    if (!mounted) return;
    setState(() => _future = fut);
    await fut;
  }

  String _weekdayFull(BuildContext context, String day) {
    const map = {
      'MONDAY': DateTime.monday,
      'TUESDAY': DateTime.tuesday,
      'WEDNESDAY': DateTime.wednesday,
      'THURSDAY': DateTime.thursday,
      'FRIDAY': DateTime.friday,
      'SATURDAY': DateTime.saturday,
      'SUNDAY': DateTime.sunday,
    };
    final wd = map[day] ?? DateTime.monday;
    final now = DateTime.now();
    final ref = now.add(Duration(days: (wd - now.weekday) % 7));
    final fmt =
        DateFormat.EEEE(Localizations.localeOf(context).toLanguageTag());
    final s = fmt.format(ref);
    return s.isEmpty ? day : s[0].toUpperCase() + s.substring(1);
  }

  String _weekdayShort(String day) {
    switch (day) {
      case 'MONDAY':
        return 'Mo';
      case 'TUESDAY':
        return 'Tu';
      case 'WEDNESDAY':
        return 'We';
      case 'THURSDAY':
        return 'Th';
      case 'FRIDAY':
        return 'Fr';
      case 'SATURDAY':
        return 'Sa';
      case 'SUNDAY':
        return 'Su';
      default:
        return '—';
    }
  }

  int _dayIndex(String serverDay) {
    switch (serverDay.toUpperCase()) {
      case 'MONDAY':
        return 1;
      case 'TUESDAY':
        return 2;
      case 'WEDNESDAY':
        return 3;
      case 'THURSDAY':
        return 4;
      case 'FRIDAY':
        return 5;
      case 'SATURDAY':
        return 6;
      case 'SUNDAY':
        return 7;
      default:
        return 1;
    }
  }

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  Future<void> _save(AppLocalizations t) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final list = _rows
          .where((r) => !r.closed)
          .map((r) => BusinessHourDto(day: r.day, start: r.start, end: r.end))
          .toList();

      for (final r in list) {
        if (_toMinutes(r.start) >= _toMinutes(r.end)) {
          throw Exception(t.invalid ?? 'Invalid time range');
        }
      }

      await _api.save(widget.providerId, list);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.saved ?? 'Saved')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- Quick actions ----
  void _copyMondayToAll() {
    final mon = _rows.firstWhere((r) => r.day == 'MONDAY');
    for (final r in _rows) {
      r.closed = mon.closed;
      r.start = mon.start;
      r.end = mon.end;
    }
    setState(() {});
  }

  void _closeAll() {
    for (final r in _rows) {
      r.closed = true;
    }
    setState(() {});
  }

  // void _monToFri() {
  //   final mon = _rows.firstWhere((r) => r.day == 'MONDAY');
  //   for (final r in _rows) {
  //     if (r.day == 'SATURDAY' || r.day == 'SUNDAY') continue;
  //     r.closed = mon.closed;
  //     r.start = mon.start;
  //     r.end = mon.end;
  //   }
  //   setState(() {});
  // }

  void _monToFri() {
    for (final d in _rows) {
      final idx = _dayIndex(d.day);
      if (idx >= 1 && idx <= 5) {
        d.closed = false;
        d.start = '09:00';
        d.end = '18:00';
      } else {
        d.closed = true;
      }
    }
    setState(() {});
  }

  // ---- Time wheel bottom sheet (24h) ----
  Future<(String, String)?> _showTimeRangeWheel({
    required String start,
    required String end,
    required AppLocalizations t,
  }) async {
    // convert "HH:mm" -> DateTime today
    DateTime toDate(String v) {
      final p = v.split(':');
      final h = int.tryParse(p[0]) ?? 0;
      final m = int.tryParse(p[1]) ?? 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, h, m);
    }

    DateTime s = toDate(start);
    DateTime e = toDate(end);

    return await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              left: 12,
              right: 12,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.timeRange ?? 'Time range',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // wheels
                SizedBox(
                  height: 220,
                  child: Row(
                    children: [
                      Expanded(
                        child: _CupertinoTimeWheel(
                          label: t.start ?? 'Start',
                          initial: s,
                          minuteInterval: kMinuteStep,
                          onChanged: (dt) => s = dt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CupertinoTimeWheel(
                          label: t.end ?? 'End',
                          initial: e,
                          minuteInterval: kMinuteStep,
                          onChanged: (dt) => e = dt,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // presets
                // Wrap(
                //   spacing: 8,
                //   runSpacing: 8,
                //   children: [
                //     ActionChip(
                //       label: const Text('09:00–18:00'),
                //       onPressed: () {
                //         final now = DateTime.now();
                //         s = DateTime(now.year, now.month, now.day, 9, 0);
                //         e = DateTime(now.year, now.month, now.day, 18, 0);
                //         Navigator.of(ctx).pop(('09:00', '18:00'));
                //       },
                //     ),
                //     ActionChip(
                //       label: const Text('10:00–20:00'),
                //       onPressed: () {
                //         final now = DateTime.now();
                //         s = DateTime(now.year, now.month, now.day, 10, 0);
                //         e = DateTime(now.year, now.month, now.day, 20, 0);
                //         Navigator.of(ctx).pop(('10:00', '20:00'));
                //       },
                //     ),
                //   ],
                // ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: Text(t.action_cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final sStr =
                              '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
                          final eStr =
                              '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
                          if (_toMinutes(sStr) >= _toMinutes(eStr)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(t.invalid ?? 'Invalid time range')),
                            );
                            return;
                          }
                          Navigator.of(ctx).pop((sStr, eStr));
                        },
                        child: Text(t.action_save ?? 'Apply'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.working_hours ?? 'Working hours')),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_err.isNotEmpty) {
            return _ErrorBox(text: _err, onRetry: _refresh, t: t);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              // Quick actions row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.copy_all_rounded, size: 18),
                    label: Text(t.copy_monday_to_all ?? 'Copy Monday to all'),
                    onPressed: _copyMondayToAll,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_view_week, size: 18),
                    label: Text(t.mon_fri ?? 'Mon–Fri'),
                    onPressed: _monToFri,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.block, size: 18),
                    label: Text(t.close_all ?? 'Close all'),
                    onPressed: _closeAll,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ..._rows.map((r) {
                final open = !r.closed;
                final subtitle =
                    open ? '${r.start} – ${r.end}' : (t.closed ?? 'Closed');

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: open
                          ? const Color(0xFFD6F5E5)
                          : const Color(0xFFF0F2F5),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: open
                          ? const Color(0xFFE7FBF1)
                          : const Color(0xFFF3F4F6),
                      child: Text(
                        _weekdayShort(r.day),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              open ? const Color(0xFF0F9D58) : Colors.black54,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _weekdayFull(context, r.day),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: open
                                ? const Color(0xFFE7FBF1)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            open
                                ? (t.working_hours ?? 'Open')
                                : (t.closed ?? 'Closed'),
                            style: TextStyle(
                              fontSize: 12,
                              color: open
                                  ? const Color(0xFF0F9D58)
                                  : Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: open ? Colors.black87 : Colors.black54,
                          fontWeight:
                              open ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: !r.closed,
                          onChanged: (v) => setState(() => r.closed = !v),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.time),
                          tooltip: t.select_time ?? 'Select time',
                          onPressed: r.closed
                              ? null
                              : () async {
                                  final res = await _showTimeRangeWheel(
                                    start: r.start,
                                    end: r.end,
                                    t: t,
                                  );
                                  if (res == null) return;
                                  setState(() {
                                    r.start = res.$1;
                                    r.end = res.$2;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : () => _save(t),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.action_save ?? 'Save'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Reusable 24-hour cupertino time wheel with a title.
class _CupertinoTimeWheel extends StatefulWidget {
  final String label;
  final DateTime initial;
  final int minuteInterval;
  final ValueChanged<DateTime> onChanged;
  const _CupertinoTimeWheel({
    required this.label,
    required this.initial,
    required this.minuteInterval,
    required this.onChanged,
  });

  @override
  State<_CupertinoTimeWheel> createState() => _CupertinoTimeWheelState();
}

class _CupertinoTimeWheelState extends State<_CupertinoTimeWheel> {
  late DateTime _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Expanded(
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.light),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: _value,
              use24hFormat: true,
              minuteInterval: widget.minuteInterval,
              onDateTimeChanged: (dt) {
                _value = dt;
                widget.onChanged(dt);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRow {
  final String day; // MONDAY..SUNDAY
  bool closed;
  String start; // "HH:mm"
  String end; // "HH:mm"
  _DayRow(this.day)
      : closed = true,
        start = '09:00',
        end = '18:00';
}

class _ErrorBox extends StatelessWidget {
  final String text;
  final Future<void> Function() onRetry;
  final AppLocalizations t;
  const _ErrorBox({required this.text, required this.onRetry, required this.t});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => onRetry(),
                child: Text(t.action_retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
}
