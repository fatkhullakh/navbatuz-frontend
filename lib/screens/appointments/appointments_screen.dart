import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import 'appointment_details_screen.dart';
import '../../l10n/app_localizations.dart';

class AppointmentsScreen extends StatefulWidget {
  final VoidCallback? onChanged;
  const AppointmentsScreen({super.key, this.onChanged});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
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
        final isUpcomingStatus = s == 'BOOKED' || s == 'CONFIRMED';
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

  // Status colors (BOOKED/CONFIRMED use #88BDF2 as requested)
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'FINISHED':
        return const Color(0xFF2E7D32); // green
      case 'CANCELED':
      case 'CANCELLED':
        return const Color(0xFFB00020); // red
      case 'BOOKED':
      case 'CONFIRMED':
      default:
        return const Color(0xFF88BDF2); // light blue for upcoming
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
          foregroundColor: cs.primary,
          backgroundColor: cs.surfaceVariant.withOpacity(.55),
        ),
      ),
      chipTheme: theme.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle:
            theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerColor: cs.outlineVariant.withOpacity(.6),
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
                                  onPrimaryAction: () {/* TODO */},
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
  final VoidCallback onPrimaryAction;
  final VoidCallback onOpen;

  const _AppointmentCard({
    required this.item,
    required this.dateFmt,
    required this.timeFmt,
    required this.statusColor,
    required this.primaryActionText,
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
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.6), width: 1),
        ),
        color: Color.alphaBlend(
          cs.surfaceTint
              .withOpacity(theme.brightness == Brightness.dark ? 0.06 : 0.03),
          cs.surface,
        ),
        child: Stack(
          children: [
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.surfaceVariant.withOpacity(.45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: cs.outlineVariant.withOpacity(.6),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 16,
                                  color: cs.onSurface.withOpacity(.7)),
                              const SizedBox(width: 8),
                              Text(dateText, style: theme.textTheme.bodyMedium),
                              const SizedBox(width: 8),
                              Text("•", style: theme.textTheme.bodyMedium),
                              const SizedBox(width: 8),
                              Text(timeText, style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonal(
                            onPressed: onPrimaryAction,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  cs.secondaryContainer.withOpacity(.75),
                              foregroundColor: cs.onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
