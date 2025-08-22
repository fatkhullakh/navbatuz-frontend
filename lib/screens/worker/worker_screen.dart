import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/workers/worker_service.dart';
import '../../services/services/service_catalog_service.dart';
import '../../screens/booking/service_booking_screen.dart';

/* ---------------------------- Brand constants ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7); // #6A89A7
  static const accent = Color(0xFF88BDF2); // #88BDF2
  static const accentSoft = Color(0xFFBDDDFC); // #BDDDFC
  static const ink = Color(0xFF384959); // #384959
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

class WorkerScreen extends StatefulWidget {
  final String workerId;
  final String? providerId;
  final String? workerNameFallback;
  const WorkerScreen({
    super.key,
    required this.workerId,
    this.providerId,
    this.workerNameFallback,
  });

  @override
  State<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  final _workers = WorkerService();
  final _services = ServiceCatalogService();

  WorkerDetails? _worker;
  bool _loading = true;
  String? _error;

  List<ServiceSummary> _servicesList = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final w = await _workers.details(widget.workerId);

      List<ServiceSummary> provServices = [];
      final providerId = widget.providerId;
      if ((providerId ?? '').isNotEmpty) {
        provServices = await _services.byProvider(providerId!);

        final details = await Future.wait(provServices.map((s) async {
          try {
            return await _services.details(
                serviceId: s.id, providerId: providerId);
          } catch (_) {
            return null;
          }
        }));

        final filteredIds = details
            .where((d) => d != null && d.workerIds.contains(widget.workerId))
            .map((d) => d!.id)
            .toSet();

        if (filteredIds.isNotEmpty) {
          provServices =
              provServices.where((s) => filteredIds.contains(s.id)).toList();
        }
      }

      setState(() {
        _worker = w;
        _servicesList = provServices;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _durText(Duration? d) {
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final priceFmt = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    );
    final canBook = (widget.providerId ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          _worker?.name ?? widget.workerNameFallback ?? 'Worker',
          style:
              const TextStyle(color: _Brand.ink, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _Brand.border),
        ),
      ),
      body: RefreshIndicator(
        color: _Brand.primary,
        onRefresh: _bootstrap,
        child: _loading
            ? const _LoadingState()
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _bootstrap)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // Worker card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _Brand.border),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Avatar with subtle ring
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: _Brand.border, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: (_worker?.avatarUrl != null)
                                    ? NetworkImage(_worker!.avatarUrl!)
                                    : null,
                                child: (_worker?.avatarUrl == null)
                                    ? const Icon(Icons.person,
                                        color: _Brand.subtle)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _worker?.name ??
                                        (widget.workerNameFallback ?? 'Worker'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _Brand.ink,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if ((_worker?.phone ?? '').isNotEmpty)
                                    Text(_worker!.phone!,
                                        style: const TextStyle(
                                            color: _Brand.subtle)),
                                  if ((_worker?.email ?? '').isNotEmpty)
                                    Text(_worker!.email!,
                                        style: const TextStyle(
                                            color: _Brand.subtle)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_servicesList.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Services',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: _Brand.ink),
                          ),
                        ),

                      if (_servicesList.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _Brand.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            t.provider_no_services,
                            style: const TextStyle(color: _Brand.subtle),
                          ),
                        ),

                      // Services list
                      ..._servicesList.map((s) {
                        final duration = _durText(s.duration);
                        final priceText = priceFmt.format(s.price);
                        final desc = (s.description ?? '').trim();

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _Brand.border),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: null, // no details from here
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  // Leading badge
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _Brand.accentSoft.withOpacity(.7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _Brand.border),
                                    ),
                                    child: const Icon(
                                        Icons.design_services_outlined,
                                        size: 20,
                                        color: _Brand.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title + description + duration
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: _Brand.ink,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15.5,
                                          ),
                                        ),
                                        if (desc.isNotEmpty ||
                                            duration.isNotEmpty) ...[
                                          if (desc.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                desc,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: _Brand.subtle),
                                              ),
                                            ),
                                          if (duration.isNotEmpty)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: desc.isNotEmpty ? 6 : 4),
                                              child: _Pill(
                                                  icon: Icons.schedule,
                                                  label: duration),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Price + CTA
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _Brand.accentSoft,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border:
                                              Border.all(color: _Brand.border),
                                        ),
                                        child: Text(
                                          priceText,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: _Brand.ink,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 32,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: canBook
                                                ? _Brand.primary
                                                : _Brand.accentSoft,
                                            foregroundColor: canBook
                                                ? Colors.white
                                                : _Brand.ink,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: canBook
                                              ? () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (ctx) =>
                                                          ServiceBookingScreen(
                                                        serviceId: s.id,
                                                        providerId:
                                                            widget.providerId!,
                                                        initialWorkerId:
                                                            widget.workerId,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              : null,
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .provider_book,
                                            style:
                                                const TextStyle(fontSize: 12.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
}

/* ----------------------------- Tiny UI bits ----------------------------- */

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: _Brand.primary),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Failed: $message', style: const TextStyle(color: _Brand.ink)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _Brand.primary),
            foregroundColor: _Brand.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(t.action_retry),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: _Brand.ink),
      label: Text(label, overflow: TextOverflow.ellipsis),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: _Brand.border),
      backgroundColor: _Brand.accentSoft.withOpacity(.35),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }
}
