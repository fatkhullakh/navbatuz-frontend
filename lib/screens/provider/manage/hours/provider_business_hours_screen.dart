import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';

/// ---------------- Brand ----------------
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const primarySoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const subtle = Color(0xFF7C8B9B);
  static const border = Color(0xFFE6ECF2);
  static const bg = Color(0xFFF6F8FC);
  static const okBg = Color(0xFFE7FBF1);
  static const okText = Color(0xFF0F9D58);
  static const muted = Color(0xFFF3F4F6);
}

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
        'startTime': _normalizeOut(start),
        'endTime': _normalizeOut(end),
      };

  static String _normalizeIn(String? v) {
    if (v == null || v.isEmpty) return '09:00';
    final p = v.split(':');
    final hh = (p.isNotEmpty ? p[0] : '00').padLeft(2, '0');
    final mm = (p.length > 1 ? p[1] : '00').padLeft(2, '0');
    return '$hh:$mm';
  }

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
    await _dio.put(
      '/providers/$providerId/business-hours',
      data: hours.map((e) => e.toJson()).toList(),
    );
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

      for (final r in _rows) {
        r.closed = true;
        r.start = '09:00';
        r.end = '18:00';
      }
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

  void _set247() {
    for (final d in _rows) {
      d.closed = false;
      d.start = '00:00';
      d.end = '23:59';
    }
    setState(() {});
  }

  // ---- Time wheel bottom sheet ----
  Future<(String, String)?> _showTimeRangeWheel({
    required String start,
    required String end,
    required AppLocalizations t,
  }) async {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.timeRange ?? 'Time range',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _Brand.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _Brand.border),
                    borderRadius: BorderRadius.circular(14),
                    color: _Brand.bg,
                  ),
                  child: SizedBox(
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
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _Brand.border),
                          foregroundColor: _Brand.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: Text(t.action_cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _Brand.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final sStr =
                              '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
                          final eStr =
                              '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
                          if (_toMinutes(sStr) >= _toMinutes(eStr)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(t.invalid ?? 'Invalid time range'),
                              ),
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
                const SizedBox(height: 6),
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

    final themed = Theme.of(context).copyWith(
      scaffoldBackgroundColor: _Brand.bg,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: _Brand.primary),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _Brand.primarySoft;
          }
          return _Brand.muted;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _Brand.primary;
          return _Brand.subtle;
        }),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.working_hours ?? 'Working hours'),
          backgroundColor: Colors.white,
          foregroundColor: _Brand.ink,
          elevation: 0.5,
        ),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                // Header summary card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _Brand.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _Brand.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.schedule, color: _Brand.ink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.working_hours_subtitle ??
                              'Set your weekly opening hours',
                          style: const TextStyle(color: _Brand.subtle),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick actions
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _Brand.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickActionChip(
                        icon: Icons.copy_all_rounded,
                        label: t.copy_monday_to_all ?? 'Copy Monday to all',
                        onTap: _copyMondayToAll,
                      ),
                      _QuickActionChip(
                        icon: Icons.calendar_view_week,
                        label: t.mon_fri ?? 'Mon–Fri (9–18)',
                        onTap: _monToFri,
                      ),
                      // _QuickActionChip(
                      //   icon: Icons.av_timer_outlined,
                      //   label: t.mon_fri ?? '24/7',
                      //   onTap: _set247,
                      // ),
                      _QuickActionChip(
                        icon: Icons.block,
                        label: t.close_all ?? 'Close all',
                        onTap: _closeAll,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Day rows
                ..._rows.map((r) {
                  final open = !r.closed;
                  final statusBg = open ? _Brand.okBg : _Brand.muted;
                  final statusFg = open ? _Brand.okText : Colors.black54;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side:
                          BorderSide(color: open ? _Brand.okBg : _Brand.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: statusBg,
                            child: Text(
                              _weekdayShort(r.day),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: statusFg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _weekdayFull(context, r.day),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: _Brand.ink,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        open
                                            ? (t.working_hours ?? 'Open')
                                            : (t.closed ?? 'Closed'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: statusFg,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // time chips
                                Row(
                                  children: [
                                    _TimeBadge(text: r.start),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 6),
                                      child: Text('—',
                                          style: TextStyle(
                                              color: _Brand.subtle,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    _TimeBadge(text: r.end),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: !r.closed,
                                onChanged: (v) {
                                  setState(() {
                                    r.closed = !v;
                                    if (v &&
                                        (r.start.isEmpty || r.end.isEmpty)) {
                                      r.start = '09:00';
                                      r.end = '18:00';
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              IconButton.filledTonal(
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
                                icon: const Icon(CupertinoIcons.time, size: 18),
                                tooltip: t.select_time ?? 'Select time',
                                style: IconButton.styleFrom(
                                  disabledBackgroundColor: _Brand.muted,
                                  foregroundColor: _Brand.ink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Brand.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    _saving ? null : () => _save(AppLocalizations.of(context)!),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.action_save ?? 'Save'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ------- Bits -------
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _Brand.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _Brand.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _Brand.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final String text;
  const _TimeBadge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Brand.muted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Brand.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: _Brand.ink,
        ),
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
        Text(widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _Brand.ink,
            )),
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
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _Brand.border),
                  foregroundColor: _Brand.ink,
                ),
                onPressed: () => onRetry(),
                child: Text(t.action_retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
}
