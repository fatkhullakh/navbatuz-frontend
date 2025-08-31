// lib/screens/provider/appointments/staff_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../services/appointments/appointment_service.dart';
import '../../../models/appointment_models.dart';
import '../../../services/providers/provider_staff_service.dart';
import 'create_appointment_screen.dart';
import 'create_break_screen.dart';
import 'staff_appointment_details_screen.dart';

// ---- Stormy morning palette
const kStormMuted = Color(0xFF6A89A7); // slate blue-gray
const kStormSoft = Color(0xFFBDDDFC); // pale blue
const kStormPrim = Color(0xFF88BDF2); // sky blue
const kStormDark = Color(0xFF384959); // deep slate

// ========== Local model for breaks ==========
class _BreakSlot {
  final DateTime date;
  final String start; // "HH:mm"
  final String end; // "HH:mm"
  final String? id;

  _BreakSlot(
      {required this.date, required this.start, required this.end, this.id});

  static String _toHHmm(String s) {
    if (s.isEmpty) return s;
    final p = s.split(':');
    if (p.length >= 2) return '${p[0].padLeft(2, '0')}:${p[1].padLeft(2, '0')}';
    return s;
  }

  factory _BreakSlot.fromJson(Map<String, dynamic> m) {
    final dStr = (m['date'] ?? m['day'] ?? m['onDate'] ?? '').toString();
    final st = (m['startTime'] ?? m['from'] ?? m['start'] ?? '').toString();
    final et = (m['endTime'] ?? m['to'] ?? m['end'] ?? '').toString();
    final d = DateTime.parse(dStr);
    return _BreakSlot(
      date: d,
      start: _toHHmm(st),
      end: _toHHmm(et),
      id: m['id']?.toString(),
    );
  }
}

// ========== Grid painter (lines) ==========
class _GridPainter extends CustomPainter {
  final double gutter;
  final double hourHeight;
  final int startHour, endHour;
  const _GridPainter(
      this.gutter, this.hourHeight, this.startHour, this.endHour);

  @override
  void paint(Canvas canvas, Size size) {
    final hourPaint = Paint()
      ..color = kStormDark.withOpacity(.15)
      ..strokeWidth = 1;
    final qPaint = Paint()
      ..color = kStormDark.withOpacity(.07)
      ..strokeWidth = 1;

    final w = size.width - gutter;
    if (w <= 0) return;

    for (int h = startHour; h < endHour; h++) {
      final y0 = (h - startHour) * hourHeight;
      canvas.drawLine(Offset(gutter, y0), Offset(gutter + w, y0), hourPaint);
      final y15 = y0 + hourHeight * .25;
      final y30 = y0 + hourHeight * .50;
      final y45 = y0 + hourHeight * .75;
      canvas.drawLine(Offset(gutter, y15), Offset(gutter + w, y15), qPaint);
      canvas.drawLine(Offset(gutter, y30), Offset(gutter + w, y30), qPaint);
      canvas.drawLine(Offset(gutter, y45), Offset(gutter + w, y45), qPaint);
    }
    final yEnd = (endHour - startHour) * hourHeight;
    canvas.drawLine(Offset(gutter, yEnd), Offset(gutter + w, yEnd), hourPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========== Screen ==========
enum StaffViewMode { list, calendar }

class StaffAppointmentsScreen extends StatefulWidget {
  final String? providerId; // owner/receptionist view
  final String? workerId; // worker self-view
  const StaffAppointmentsScreen({super.key, this.providerId, this.workerId})
      : assert((providerId != null) ^ (workerId != null),
            'Pass exactly one of providerId or workerId');

  @override
  State<StaffAppointmentsScreen> createState() =>
      _StaffAppointmentsScreenState();
}

class _StaffAppointmentsScreenState extends State<StaffAppointmentsScreen> {
  final _appt = AppointmentService();
  final _staffSvc = ProviderStaffService();
  final _dio = ApiService.client;

  StaffViewMode _mode = StaffViewMode.calendar;

  // Calendar metrics
  static const int _dayStartHour = 0;
  static const int _dayEndHour = 24;
  static const double _hourHeight = 136;
  static const double _gutterWidth = 64;
  static const double _columnWidth = 260;

  /// Negative = move text UP; positive = move text DOWN.
  static const double _HOUR_LABEL_NUDGE = -9.5;

  DateTime _selectedDay = DateTime.now();
  List<StaffMember> _workers = [];
  final Set<String> _selectedWorkerIds = {};

  final Map<String, List<Appointment>> _agenda = {};
  final Map<String, List<_BreakSlot>> _breaks = {};
  final Map<String, String> _serviceNameCache = {};

  bool _loading = true;
  String? _error;

  // date strip (±365d)
  late final DateTime _stripStart;
  static const int _stripTotalDays = 730;
  final ScrollController _stripCtl = ScrollController();

  // scroll sync
  final ScrollController _calVScrollCtl = ScrollController();
  final ScrollController _calHScrollCtl = ScrollController();
  final ScrollController _chipHScrollCtl = ScrollController();

  @override
  void initState() {
    super.initState();
    _stripStart = DateTime.now().subtract(const Duration(days: 365));

    // keep worker header horizontally in sync with calendar scroll
    _calHScrollCtl.addListener(() {
      if (_chipHScrollCtl.hasClients) {
        final off = _calHScrollCtl.offset
            .clamp(0.0, _chipHScrollCtl.position.maxScrollExtent);
        _chipHScrollCtl.jumpTo(off);
      }
    });

    _bootstrap().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollDateStripToSelected();
        if (_mode == StaffViewMode.calendar) {
          if (_isSameDay(_selectedDay, DateTime.now())) {
            _scrollCalendarToNow();
          } else {
            _scrollCalendarToHour(9);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _stripCtl.dispose();
    _calVScrollCtl.dispose();
    _calHScrollCtl.dispose();
    _chipHScrollCtl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.workerId != null) {
        final id = widget.workerId!;
        _selectedWorkerIds
          ..clear()
          ..add(id);
        await _loadWorkerRosterIfNeeded(id);
        await _loadWorkerDay(id);
      } else {
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

  Future<void> _loadWorkerRosterIfNeeded(String workerId) async {
    if (_workers.any((w) => w.id == workerId)) return;

    // hydrate from /workers/me if possible
    try {
      final r = await _dio.get('/workers/me');
      if (r.data is Map) {
        final m = Map<String, dynamic>.from(r.data as Map);
        _workers = [StaffMember.fromWorkerJson(m)];
        return;
      }
    } catch (_) {
      // ignore and fall back
    }

    _workers = [StaffMember.stub(workerId)];
  }

  Future<void> _loadWorkerDay(String workerId) async {
    final list = await _appt.getWorkerDay(workerId, _selectedDay);
    _agenda[workerId] = list;

    // opportunistic cache
    for (final a in list) {
      if ((a as dynamic).serviceName != null) {
        _serviceNameCache[a.serviceId] = (a as dynamic).serviceName as String;
      }
    }

    await _loadBreaks(workerId);
    if (mounted) setState(() {});
    await _autoCompletePast(workerId);
  }

  Future<void> _loadBreaks(String workerId) async {
    try {
      final d = _selectedDay.toIso8601String().split('T').first;
      final r = await _dio.get(
        '/workers/public/availability/break/$workerId',
        queryParameters: {'from': d, 'to': d},
      );
      final list = ((r.data as List?) ?? const [])
          .whereType<Map>()
          .map((e) => _BreakSlot.fromJson(Map<String, dynamic>.from(e)))
          .where((b) =>
              b.date.year == _selectedDay.year &&
              b.date.month == _selectedDay.month &&
              b.date.day == _selectedDay.day)
          .toList();
      _breaks[workerId] = list;
    } catch (_) {
      _breaks[workerId] = const [];
    }
  }

  Future<void> _autoCompletePast(String workerId) async {
    final list = _agenda[workerId] ?? const <Appointment>[];
    final now = DateTime.now();
    bool changed = false;
    for (final a in list) {
      if (a.status == AppointmentStatus.BOOKED) {
        final eh = int.parse(a.end.split(':')[0]);
        final em = int.parse(a.end.split(':')[1]);
        final end = DateTime(a.date.year, a.date.month, a.date.day, eh, em);
        if (now.isAfter(end)) {
          try {
            await _appt.complete(a.id);
            changed = true;
          } catch (_) {}
        }
      }
    }
    if (changed) {
      final list2 = await _appt.getWorkerDay(workerId, _selectedDay);
      _agenda[workerId] = list2;
      if (mounted) setState(() {});
    }
  }

  // Color mapping
  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.BOOKED:
        return const Color(0xFF12B76A);
      case AppointmentStatus.RESCHEDULED:
        return const Color(0xFF7F56D9);
      case AppointmentStatus.COMPLETED:
        return const Color(0xFF155EEF);
      case AppointmentStatus.NO_SHOW:
        return const Color(0xFFB54708);
      case AppointmentStatus.CANCELLED:
        return const Color(0xFFD92D20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isToday = _isSameDay(_selectedDay, DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appointments_title),
        actions: [
          if (!isToday)
            TextButton(
              onPressed: () async {
                setState(() => _selectedDay = DateTime.now());
                _scrollDateStripToSelected();
                for (final id in _selectedWorkerIds) {
                  await _loadWorkerDay(id);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollCalendarToNow();
                });
              },
              child: Text(t.today),
            ),
          IconButton(
            tooltip:
                _mode == StaffViewMode.list ? t.calendar_view : t.list_view,
            onPressed: () {
              final goCalendar = _mode == StaffViewMode.list;
              setState(() => _mode =
                  goCalendar ? StaffViewMode.calendar : StaffViewMode.list);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_mode == StaffViewMode.calendar) {
                  _isSameDay(_selectedDay, DateTime.now())
                      ? _scrollCalendarToNow()
                      : _scrollCalendarToHour(9);
                }
              });
            },
            icon: Icon(_mode == StaffViewMode.list
                ? Icons.calendar_month
                : Icons.view_list),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateStrip(),
          if (widget.providerId != null)
            (_mode == StaffViewMode.list
                ? _buildListWorkerChips()
                : _buildCalendarWorkerHeader()),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null
                    ? Center(child: Text(_error!))
                    : (_mode == StaffViewMode.list
                        ? _buildList()
                        : _buildCalendar())),
          ),
        ],
      ),
      floatingActionButton: Theme(
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: kStormDark,
            foregroundColor: Colors.white,
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: _showFabActions,
          icon: const Icon(Icons.add),
          label: Text(t.new_appointment),
        ),
      ),
    );
  }

  // ---- date strip (darker styling + “Today” highlight + bigger text + raised)
  Widget _buildDateStrip() {
    const double itemW = 78;
    final t = AppLocalizations.of(context)!;

    final today = DateTime.now();
    final wds = <String>[
      t.weekday_mon_short,
      t.weekday_tue_short,
      t.weekday_wed_short,
      t.weekday_thu_short,
      t.weekday_fri_short,
      t.weekday_sat_short,
      t.weekday_sun_short,
    ];

    return SizedBox(
      height: 66,
      child: ListView.builder(
        controller: _stripCtl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _stripTotalDays,
        itemBuilder: (_, i) {
          final d = _stripStart.add(Duration(days: i));
          final isSel = _isSameDay(d, _selectedDay);
          final isToday = _isSameDay(d, today);

          final chipBg =
              isSel ? kStormDark : (isToday ? kStormSoft : Colors.white);
          final chipSide = isSel
              ? kStormDark
              : (isToday ? kStormDark : kStormMuted.withOpacity(.45));
          final topColor = isSel
              ? Colors.white
              : (isToday ? kStormDark : kStormDark.withOpacity(.70));
          final numColor =
              isSel ? Colors.white : (isToday ? kStormDark : kStormDark);

          return SizedBox(
            width: itemW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: Colors.white,
                selectedColor: chipBg,
                selected: isSel,
                side: BorderSide(color: chipSide, width: isToday ? 1.4 : 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                label: Transform.translate(
                  offset: const Offset(0, -3), // shift content higher
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        wds[(d.weekday + 6) % 7],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel
                              ? FontWeight.w900
                              : (isToday ? FontWeight.w800 : FontWeight.w600),
                          color: topColor,
                          letterSpacing: .1,
                        ),
                      ),
                      const SizedBox(height: 0),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSel
                              ? FontWeight.w900
                              : (isToday ? FontWeight.w800 : FontWeight.w700),
                          color: numColor,
                        ),
                      ),
                    ],
                  ),
                ),
                onSelected: (_) async {
                  setState(() => _selectedDay = d);
                  for (final id in _selectedWorkerIds) {
                    await _loadWorkerDay(id);
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_mode == StaffViewMode.calendar) {
                      _isSameDay(d, DateTime.now())
                          ? _scrollCalendarToNow()
                          : _scrollCalendarToHour(9);
                    }
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _scrollDateStripToSelected() {
    const double itemW = 78;
    final idx = _daysBetween(_stripStart, _selectedDay);
    final target = (idx - 3) * itemW;
    if (_stripCtl.hasClients) {
      final max = _stripCtl.position.maxScrollExtent;
      _stripCtl.jumpTo(target.clamp(0.0, max));
    }
  }

  // ---- ordering helpers (selected first)
  List<StaffMember> _orderedWorkers() {
    final sel =
        _workers.where((w) => _selectedWorkerIds.contains(w.id)).toList();
    final rest =
        _workers.where((w) => !_selectedWorkerIds.contains(w.id)).toList();
    return [...sel, ...rest];
  }

  // ---- Worker chips (LIST) — darker selected chip
  Widget _buildListWorkerChips() {
    final ordered = _orderedWorkers();
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: ordered.map((w) {
          final sel = _selectedWorkerIds.contains(w.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              avatar: Icon(Icons.person_outline,
                  size: 18,
                  color: sel ? Colors.white : kStormDark.withOpacity(.85)),
              label: Text(
                w.displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  color: sel ? Colors.white : kStormDark,
                ),
              ),
              selected: sel,
              selectedColor: kStormDark,
              backgroundColor: Colors.white,
              side: BorderSide(
                  color: sel ? kStormDark : kStormMuted.withOpacity(.45)),
              onSelected: (v) async {
                setState(() {
                  if (v) {
                    _selectedWorkerIds.add(w.id);
                  } else {
                    _selectedWorkerIds.remove(w.id);
                  }
                });
                if (v) await _loadWorkerDay(w.id);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---- Worker chips header (CALENDAR) – all workers; unselected dimmed
  Widget _buildCalendarWorkerHeader() {
    final ordered = _orderedWorkers();
    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        controller: _chipHScrollCtl,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: _gutterWidth),
            ...ordered.map((w) {
              final sel = _selectedWorkerIds.contains(w.id);
              return SizedBox(
                width: _columnWidth,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Opacity(
                    opacity: sel ? 1.0 : 0.35,
                    child: FilterChip(
                      avatar: Icon(Icons.person_outline,
                          size: 16,
                          color:
                              sel ? Colors.white : kStormDark.withOpacity(.85)),
                      label: Text(
                        w.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                          color: sel ? Colors.white : kStormDark,
                        ),
                      ),
                      selected: sel,
                      selectedColor: kStormDark,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                          color:
                              sel ? kStormDark : kStormMuted.withOpacity(.45)),
                      onSelected: (v) async {
                        setState(() {
                          if (v) {
                            _selectedWorkerIds.add(w.id);
                          } else {
                            _selectedWorkerIds.remove(w.id);
                          }
                        });
                        if (v) await _loadWorkerDay(w.id);
                      },
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---- List mode (cards recolored; subtitle = customer name)
  Widget _buildList() {
    final ids = widget.workerId != null
        ? [widget.workerId!]
        : _selectedWorkerIds.toList();
    if (ids.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.no_workers_selected));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: ids.length,
      itemBuilder: (_, i) {
        final id = ids[i];
        final member = _workers.firstWhere((w) => w.id == id,
            orElse: () => StaffMember.stub(id));
        final appts = (_agenda[id] ?? const <Appointment>[])
            .where((a) => a.status != AppointmentStatus.CANCELLED)
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
        final brks = (_breaks[id] ?? const <_BreakSlot>[])
          ..sort((a, b) => a.start.compareTo(b.start));

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: kStormDark.withOpacity(.08)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kStormDark)),
                const SizedBox(height: 8),
                if (appts.isEmpty && brks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(AppLocalizations.of(context)!.no_appointments,
                        style: TextStyle(color: kStormDark.withOpacity(.6))),
                  ),
                ...appts.map((a) {
                  final statusColor = _statusColor(a.status);
                  final serviceName = _serviceNameCache[a.serviceId] ?? '—';
                  final customer = (a.customerName?.trim().isNotEmpty ?? false)
                      ? a.customerName!.trim()
                      : (a.customerId != null ? 'ID ${a.customerId}' : '—');

                  final canCancel = a.status == AppointmentStatus.BOOKED;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 0,
                    color: statusColor.withOpacity(.08),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: statusColor.withOpacity(.35)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => StaffAppointmentDetailsScreen(
                            appointmentId: a.id,
                          ),
                        ));
                      },
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: kStormDark.withOpacity(.10),
                        child: Icon(Icons.event, color: kStormDark, size: 18),
                      ),
                      title: Text('${a.start}–${a.end} • $serviceName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: kStormDark.withOpacity(.8)),
                      ),
                      trailing: canCancel
                          ? PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'cancel') {
                                  try {
                                    await _appt.cancel(a.id);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                  await _loadWorkerDay(id);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'cancel',
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .appointment_action_cancel,
                                    style: const TextStyle(
                                        color: Color(0xFFD92D20)),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                }),
                ...brks.map((b) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 0,
                      color: kStormMuted.withOpacity(.10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: kStormMuted.withOpacity(.25)),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.free_breakfast_outlined,
                            color: kStormDark),
                        title: Text(
                            '${AppLocalizations.of(context)!.breaks_title} ${b.start}–${b.end}'),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Calendar mode — ALL workers; unselected columns dimmed
  Widget _buildCalendar() {
    final selectedSet = _selectedWorkerIds;

    const totalHours = _dayEndHour - _dayStartHour;
    final totalHeight = totalHours * _hourHeight;
    final pxPerMinute = _hourHeight / 60.0;

    // Hour gutter
    Widget timeGutter() => SizedBox(
          width: _gutterWidth,
          height: totalHeight,
          child: Column(
            children: List.generate(totalHours, (i) {
              final h = _dayStartHour + i;
              return SizedBox(
                height: _hourHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: _HOUR_LABEL_NUDGE,
                      right: 8,
                      child: Text('${h.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                              fontSize: 12, color: kStormDark.withOpacity(.8))),
                    ),
                    Positioned(
                        top: _hourHeight * .25 - 8,
                        right: 8,
                        child: Text('15',
                            style: TextStyle(
                                fontSize: 10,
                                color: kStormDark.withOpacity(.5)))),
                    Positioned(
                        top: _hourHeight * .50 - 8,
                        right: 8,
                        child: Text('30',
                            style: TextStyle(
                                fontSize: 10,
                                color: kStormDark.withOpacity(.5)))),
                    Positioned(
                        top: _hourHeight * .75 - 8,
                        right: 8,
                        child: Text('45',
                            style: TextStyle(
                                fontSize: 10,
                                color: kStormDark.withOpacity(.5)))),
                  ],
                ),
              );
            }),
          ),
        );

    Widget workerColumn(StaffMember member, {required bool selected}) {
      final appts = selected
          ? (_agenda[member.id] ?? const <Appointment>[])
              .where((a) => a.status != AppointmentStatus.CANCELLED)
              .toList()
          : const <Appointment>[];

      final brks = selected
          ? (_breaks[member.id] ?? const <_BreakSlot>[])
          : const <_BreakSlot>[];

      Widget content = SizedBox(
        width: _columnWidth,
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              // breaks (background)
              ...brks.map((b) {
                final sh = int.parse(b.start.split(':')[0]);
                final sm = int.parse(b.start.split(':')[1]);
                final eh = int.parse(b.end.split(':')[0]);
                final em = int.parse(b.end.split(':')[1]);
                final startMin = (sh - _dayStartHour) * 60 + sm;
                final endMin = (eh - _dayStartHour) * 60 + em;
                final top = startMin * pxPerMinute;
                final height =
                    ((endMin - startMin) * pxPerMinute).clamp(16.0, 10000.0);
                return Positioned(
                  top: top,
                  left: 8,
                  right: 8,
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kStormMuted.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kStormMuted.withOpacity(.30)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    alignment: Alignment.topLeft,
                    child: Text(AppLocalizations.of(context)!.breaks_title,
                        style: TextStyle(
                            fontSize: 11, color: kStormDark.withOpacity(.9))),
                  ),
                );
              }),

              // appointments
              ...appts.map((a) {
                final sh = int.parse(a.start.split(':')[0]);
                final sm = int.parse(a.start.split(':')[1]);
                final eh = int.parse(a.end.split(':')[0]);
                final em = int.parse(a.end.split(':')[1]);

                final startMin = (sh - _dayStartHour) * 60 + sm;
                final endMin = (eh - _dayStartHour) * 60 + em;

                final top = startMin * pxPerMinute;
                final height =
                    ((endMin - startMin) * pxPerMinute).clamp(24.0, 10000.0);

                final statusColor = _statusColor(a.status);
                final svc = _serviceNameCache[a.serviceId] ?? '—';
                final customer = (a.customerName?.trim().isNotEmpty ?? false)
                    ? a.customerName!.trim()
                    : (a.customerId != null ? 'ID ${a.customerId}' : '—');

                final tight = height < 56;
                final veryTight = height < 40;

                return Positioned(
                  top: top,
                  left: 8,
                  right: 8,
                  height: height,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            StaffAppointmentDetailsScreen(appointmentId: a.id),
                      ));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(
                              a.status == AppointmentStatus.NO_SHOW
                                  ? .08
                                  : .15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(
                                a.status == AppointmentStatus.NO_SHOW
                                    ? .55
                                    : .4),
                            width:
                                a.status == AppointmentStatus.NO_SHOW ? 1.2 : 1,
                          ),
                        ),
                        child: DefaultTextStyle(
                          style:
                              const TextStyle(fontSize: 12, color: kStormDark),
                          child: veryTight
                              ? Text('${a.start}–${a.end}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${a.start} – ${a.end}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    if (!tight) const SizedBox(height: 2),
                                    Text(svc,
                                        maxLines: tight ? 1 : 2,
                                        overflow: TextOverflow.ellipsis),
                                    if (!tight)
                                      Text(customer,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );

      if (!selected) content = Opacity(opacity: 0.35, child: content);
      return content;
    }

    final isToday = _isSameDay(_selectedDay, DateTime.now());
    final now = DateTime.now();
    final nowTop =
        isToday ? ((now.hour * 60 + now.minute) * pxPerMinute) : null;

    return SingleChildScrollView(
      controller: _calVScrollCtl,
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            Row(
              children: [
                timeGutter(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _calHScrollCtl,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      height: totalHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _orderedWorkers()
                            .map((w) => workerColumn(w,
                                selected: selectedSet.contains(w.id)))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Grid overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GridPainter(
                      _gutterWidth, _hourHeight, _dayStartHour, _dayEndHour),
                ),
              ),
            ),
            // "Now" indicator (darker)
            if (nowTop != null)
              Positioned(
                top: nowTop,
                left: _gutterWidth - 6,
                right: 8,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: kStormDark,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: kStormDark.withOpacity(.35), blurRadius: 6)
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Container(height: 2, color: kStormDark)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- helpers
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _daysBetween(DateTime a, DateTime b) => DateTime(b.year, b.month, b.day)
      .difference(DateTime(a.year, a.month, a.day))
      .inDays;

  void _scrollCalendarToNow() {
    final now = DateTime.now();
    final target = (now.hour * 60 + now.minute) * (_hourHeight / 60.0) - 200;
    if (_calVScrollCtl.hasClients) {
      _calVScrollCtl
          .jumpTo(target.clamp(0.0, _calVScrollCtl.position.maxScrollExtent));
    }
  }

  void _scrollCalendarToHour(int hour) {
    final target = (hour * 60) * (_hourHeight / 60.0) - 100;
    if (_calVScrollCtl.hasClients) {
      _calVScrollCtl
          .jumpTo(target.clamp(0.0, _calVScrollCtl.position.maxScrollExtent));
    }
  }

  Future<void> _showFabActions() async {
    final t = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FabAction(
                icon: Icons.event_available,
                label: t.new_appointment,
                value: 'appt'),
            _FabAction(
                icon: Icons.free_breakfast, label: t.add_break, value: 'break'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'appt') {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => CreateAppointmentScreen(
            providerId: widget.providerId,
            workers: widget.providerId != null ? _workers : null,
            fixedWorkerId: widget.workerId,
          ),
        ),
      );
      if (created == true) {
        final ids = widget.workerId != null
            ? [widget.workerId!]
            : _workers.map((w) => w.id).toList();
        for (final id in ids) {
          await _loadWorkerDay(id);
        }
      }
    } else if (action == 'break') {
      await Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreateBreakScreen(
          providerId: widget.providerId,
          workers: widget.providerId != null ? _workers : null,
          fixedWorkerId: widget.workerId,
          date: _selectedDay,
        ),
      ));
      final ids = _workers.map((w) => w.id).toList();
      for (final id in ids) {
        await _loadWorkerDay(id);
      }
    }
  }
}

class _FabAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _FabAction(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kStormDark),
      title: Text(label,
          style:
              const TextStyle(fontWeight: FontWeight.w700, color: kStormDark)),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
