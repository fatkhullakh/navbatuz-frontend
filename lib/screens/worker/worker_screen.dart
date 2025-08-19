import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/worker_service.dart';
import '../../services/service_catalog_service.dart';
import '../../screens/booking/service_booking_screen.dart';

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
      if ((widget.providerId ?? '').isNotEmpty) {
        provServices = await _services.byProvider(widget.providerId!);

        // Best-effort: keep only services that list this worker
        final filtered = <ServiceSummary>[];
        for (final s in provServices) {
          try {
            final det = await _services.details(
                serviceId: s.id, providerId: widget.providerId!);
            if (det.workerIds.contains(widget.workerId)) filtered.add(s);
          } catch (_) {}
        }
        provServices = filtered.isEmpty ? provServices : filtered;
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

  @override
  Widget build(BuildContext context) {
    final priceFmt = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
          title: Text(_worker?.name ?? widget.workerNameFallback ?? 'Worker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Failed: $_error'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Card(
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: (_worker?.avatarUrl != null)
                              ? NetworkImage(_worker!.avatarUrl!)
                              : null,
                          child: (_worker?.avatarUrl == null)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(_worker?.name ?? 'Worker',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((_worker?.phone ?? '').isNotEmpty)
                              Text(_worker!.phone!),
                            if ((_worker?.email ?? '').isNotEmpty)
                              Text(_worker!.email!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_servicesList.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Services',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ..._servicesList.map((s) => Card(
                          elevation: 0,
                          child: ListTile(
                            title: Text(s.name),
                            subtitle: Text(
                              (s.duration == null)
                                  ? ''
                                  : '${s.duration!.inHours > 0 ? '${s.duration!.inHours}h ' : ''}${s.duration!.inMinutes % 60}m',
                            ),
                            trailing: Text(
                              priceFmt.format(s.price),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onTap: () {
                              if ((widget.providerId ?? '').isEmpty) return;
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ServiceBookingScreen(
                                  serviceId: s.id,
                                  providerId: widget.providerId!,
                                  initialWorkerId: widget.workerId,
                                ),
                              ));
                            },
                          ),
                        )),
                  ],
                ),
    );
  }
}
