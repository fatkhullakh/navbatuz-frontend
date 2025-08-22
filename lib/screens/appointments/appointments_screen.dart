import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/appointments/appointment_service.dart';
import 'appointment_details_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../screens/booking/service_booking_screen.dart';
import '../../models/appointment_detail.dart';

class AppointmentsScreen extends StatefulWidget {
  final VoidCallback? onChanged;
  const AppointmentsScreen({super.key, this.onChanged});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final Dio _dio = ApiService.client;
  final _svc = AppointmentService();
  bool _loading = false;
  List<AppointmentItem> _upcoming = [];
  List<AppointmentItem> _past = [];
  final _dateFmt = DateFormat('EEE, d MMM');
  final _timeFmt = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _svc.listMine();
      final now = DateTime.now();
      final upcoming = <AppointmentItem>[];
      final past = <AppointmentItem>[];
      for (final a in all) {
        final s = a.status.toUpperCase();
        final isUpcomingStatus =
            s == 'BOOKED' || s == 'CONFIRMED' || s == 'RESCHEDULED';
        if (isUpcomingStatus && a.start.isAfter(now)) {
          upcoming.add(a);
        } else {
          past.add(a);
        }
      }
      upcoming.sort((a, b) => a.start.compareTo(b.start));
      past.sort((a, b) => b.start.compareTo(a.start));

      setState(() {
        _upcoming = upcoming;
        _past = past;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetails(String id) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailsScreen(appointmentId: id),
      ),
    );
    if (changed == true) {
      await _load();
      widget.onChanged?.call();
    }
  }

  Future<String?> _findProviderIdByName(String? providerName) async {
    if (providerName == null || providerName.trim().isEmpty) return null;
    try {
      final r = await _dio.get('/providers/public/all',
          queryParameters: {'page': 0, 'size': 100, 'sortBy': 'name'});
      final list = (r.data is Map && (r.data as Map)['content'] is List)
          ? ((r.data as Map)['content'] as List)
          : const <dynamic>[];
      for (final e in list) {
        if (e is Map &&
            (e['name']?.toString().toLowerCase().trim() ?? '') ==
                providerName.toLowerCase().trim()) {
          return e['id']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _findWorkerIdByName({
    required String? providerId,
    required String? workerName,
  }) async {
    if (providerId == null || workerName == null) return null;
    try {
      final d = await _dio.get('/providers/public/$providerId/details');
      final workers = (d.data is Map && (d.data as Map)['workers'] is List)
          ? ((d.data as Map)['workers'] as List)
          : const <dynamic>[];
      for (final w in workers) {
        if (w is Map &&
            (w['name']?.toString().toLowerCase().trim() ?? '') ==
                workerName.toLowerCase().trim()) {
          return w['id']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _findServiceIdSmart({
    required String providerId,
    required String serviceName,
    required AppointmentDetail appointmentDetail,
  }) async {
    final resp =
        await _dio.get('/services/public/provider/$providerId/services');
    final list = (resp.data as List?) ?? const [];

    int parseIsoMinutes(String? iso) {
      if (iso == null || iso.isEmpty) return 0;
      final s = iso.toUpperCase();
      if (!s.startsWith('PT')) return 0;
      int h = 0, m = 0, sec = 0;
      final hIdx = s.indexOf('H');
      final mIdx = s.indexOf('M');
      final sIdx = s.indexOf('S');
      if (hIdx != -1) h = int.tryParse(s.substring(2, hIdx)) ?? 0;
      if (mIdx != -1) {
        final start = (hIdx == -1) ? 2 : hIdx + 1;
        m = int.tryParse(s.substring(start, mIdx)) ?? 0;
      }
      if (sIdx != -1) {
        final start = (mIdx != -1) ? mIdx + 1 : (hIdx != -1 ? hIdx + 1 : 2);
        sec = int.tryParse(s.substring(start, sIdx)) ?? 0;
      }
      return Duration(hours: h, minutes: m, seconds: sec).inMinutes;
    }

    String norm(String v) => v.toLowerCase().trim();

    final matches = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is Map && norm(e['name']?.toString() ?? '') == norm(serviceName)) {
        matches.add(Map<String, dynamic>.from(e));
      }
    }
    if (matches.isEmpty) return null;

    final int apptDurMin =
        appointmentDetail.end.difference(appointmentDetail.start).inMinutes;
    final int? apptPrice = appointmentDetail.price;

    Map<String, dynamic>? best;
    int bestScore = 1 << 30;

    for (final e in matches) {
      final durMin = parseIsoMinutes(e['duration']?.toString());
      final priceNum = e['price'];
      final priceInt =
          (priceNum is num) ? priceNum.round() : int.tryParse('$priceNum');

      final nonZeroPenalty = (durMin > 0) ? 0 : 100000;
      final durDelta = (durMin - apptDurMin).abs();
      final priceDelta = (apptPrice != null && priceInt != null)
          ? (priceInt - apptPrice).abs()
          : 0;

      final score = nonZeroPenalty + (durDelta * 100) + priceDelta;
      if (score < bestScore) {
        bestScore = score;
        best = e;
      }
    }

    return best?['id']?.toString();
  }

  // Core: perform the rebook given full detail
  Future<void> _bookAgain(AppointmentDetail a) async {
    var pid = a.providerId ?? await _findProviderIdByName(a.providerName);
    if (pid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking info is incomplete.')),
      );
      return;
    }

    final sid = a.serviceId ??
        await _findServiceIdSmart(
          providerId: pid,
          serviceName: a.serviceName ?? '',
          appointmentDetail: a,
        );

    var wid = a.workerId ??
        await _findWorkerIdByName(
          providerId: pid,
          workerName: a.workerName,
        );

    if (sid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve service for booking.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ServiceBookingScreen(
        serviceId: sid,
        providerId: pid,
        initialWorkerId: wid,
      ),
    ));
  }

  // Wrapper: fetch detail then rebook
  Future<void> _bookAgainFromItem(String appointmentId) async {
    try {
      final a = await _svc.getById(appointmentId);
      if (!mounted) return;
      await _bookAgain(a);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start rebooking: $e')),
      );
    }
  }

  Future<void> _cancel(String id) async {
    final t = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.appointment_cancel_confirm_title),
        content: Text(t.appointment_cancel_confirm_body),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common_no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.appointment_cancel_confirm_yes),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _svc.cancel(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.appointment_cancel_success)),
      );
      await _load();
      widget.onChanged?.call();
    } on LateCancellationException catch (e) {
      if (!mounted) return;
      final msg = (e.minutes != null)
          ? t.appointment_cancel_too_late_with_window(e.minutes!)
          : t.appointment_cancel_too_late;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 401) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.error_session_expired)));
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/login', (_) => false);
        return;
      }
      final code = e.response?.statusCode?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.appointment_cancel_failed_generic(code))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.appointment_cancel_failed_unknown)),
      );
    }
  }

  // Status → color mapping (BOOKED uses brand primary #6A89A7)
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'FINISHED':
        return const Color(0xFF2E7D32); // green
      case 'NO_SHOW':
        return const Color(0xFFEF6C00); // orange
      case 'CANCELED':
      case 'CANCELLED':
        return const Color(0xFFB00020); // red
      case 'BOOKED':
        return const Color(0xFF6A89A7); // PRIMARY
      case 'CONFIRMED':
      case 'RESCHEDULED':
        return const Color(0xFF88BDF2); // light blue
      default:
        return const Color(0xFF88BDF2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context)!;

    final localTheme = theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          foregroundColor: const Color(0xFF6A89A7),
          backgroundColor: const Color(0xFFBDDDFC).withOpacity(.55),
        ),
      ),
      chipTheme: theme.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle:
            theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerColor: const Color(0xFFE6ECF2),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return Theme(
      data: localTheme,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          title: Text(t.appointments_title),
        ),
        body: RefreshIndicator(
          color: const Color(0xFF6A89A7),
          onRefresh: _load,
          child: _loading && _upcoming.isEmpty && _past.isEmpty
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_upcoming.isNotEmpty)
                      _Section(
                        title: t.appointments_upcoming,
                        children: _upcoming
                            .map((a) => _AppointmentCard(
                                  item: a,
                                  dateFmt: _dateFmt,
                                  timeFmt: _timeFmt,
                                  statusColor: _statusColor(a.status),
                                  primaryActionText:
                                      t.appointment_action_cancel,
                                  destructive: true,
                                  onPrimaryAction: () => _cancel(a.id),
                                  onOpen: () => _openDetails(a.id),
                                ))
                            .toList(),
                      ),
                    if (_past.isNotEmpty) const SizedBox(height: 12),
                    if (_past.isNotEmpty)
                      _Section(
                        title: t.appointments_finished,
                        children: _past
                            .map((a) => _AppointmentCard(
                                  item: a,
                                  dateFmt: _dateFmt,
                                  timeFmt: _timeFmt,
                                  statusColor: _statusColor(a.status),
                                  primaryActionText:
                                      t.appointment_action_book_again,
                                  destructive: false,
                                  onPrimaryAction: () =>
                                      _bookAgainFromItem(a.id), // <<< here
                                  onOpen: () => _openDetails(a.id),
                                ))
                            .toList(),
                      ),
                    if (_upcoming.isEmpty && _past.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48.0),
                          child: Text(t.appointments_empty),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 10),
        ...children.expand((w) sync* {
          yield w;
          yield const SizedBox(height: 12);
        })
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentItem item;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final Color statusColor;
  final String primaryActionText;
  final bool destructive;
  final VoidCallback onPrimaryAction;
  final VoidCallback onOpen;

  const _AppointmentCard({
    required this.item,
    required this.dateFmt,
    required this.timeFmt,
    required this.statusColor,
    required this.primaryActionText,
    required this.destructive,
    required this.onPrimaryAction,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateText = dateFmt.format(item.start);
    final timeText =
        "${timeFmt.format(item.start)} – ${timeFmt.format(item.end)}";
    final title = item.serviceName ?? 'Service';
    final provider = item.providerName ?? 'Provider';
    final worker = item.workerName != null ? "with ${item.workerName}" : null;

    final chipBg = statusColor.withOpacity(.12);
    final chipBorder = statusColor.withOpacity(.28);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onOpen,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE6ECF2), width: 1.25),
        ),
        color: const Color(0xFFBDDDFC).withOpacity(.18),
        child: Stack(
          children: [
            // left status accent
            Positioned.fill(
              left: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(22, 14, 14, 14), // room for accent
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor.withOpacity(.20),
                          statusColor.withOpacity(.08),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.event_rounded,
                        size: 24, color: cs.onSurface.withOpacity(.8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: chipBorder, width: 1),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (worker != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              worker,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            provider,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // compact date–time pill with slight corners
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBDDDFC).withOpacity(.30),
                            borderRadius:
                                BorderRadius.circular(8), // slight corners
                            border: Border.all(
                                color: const Color(0xFFE6ECF2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 16,
                                  color: cs.onSurface.withOpacity(.7)),
                              const SizedBox(width: 6),
                              Text(dateText, style: theme.textTheme.bodySmall),
                              const SizedBox(width: 6),
                              Text("•", style: theme.textTheme.bodySmall),
                              const SizedBox(width: 6),
                              Text(timeText, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: destructive
                              ? FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFB00020)
                                        .withOpacity(.90),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: onPrimaryAction,
                                  child: Text(primaryActionText),
                                )
                              : FilledButton.tonal(
                                  onPressed: onPrimaryAction,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFBDDDFC)
                                        .withOpacity(.75),
                                    foregroundColor: const Color(0xFF384959),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Text(primaryActionText),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
