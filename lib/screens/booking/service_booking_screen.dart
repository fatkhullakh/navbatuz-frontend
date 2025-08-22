import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/services/service_catalog_service.dart';
import '../../services/services/provider_public_service.dart';
import '../../services/workers/worker_service.dart';
import '../../services/appointments/appointment_service.dart';
import 'review_confirm_screen.dart';

class ServiceBookingScreen extends StatefulWidget {
  final String serviceId;
  final String providerId;
  final String? initialWorkerId;
  const ServiceBookingScreen({
    super.key,
    required this.serviceId,
    required this.providerId,
    this.initialWorkerId,
  });

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final _services = ServiceCatalogService();
  final _providers = ProviderPublicService();
  final _workers = WorkerService();
  final _appointments = AppointmentService();

  ServiceDetails? _service;
  ProvidersDetails? _provider;
  String? _selectedWorkerId; // null => "Anyone"
  DateTime _selectedDate = DateTime.now();
  Future<List<String>>? _slotsFuture; // "HH:mm:ss"
  String? _selectedStart; // "HH:mm:ss"
  String? _error;

  List<WorkerLite> get _allowedWorkers {
    if (_service == null || _provider == null) return const [];
    final ids = _service!.workerIds;
    if (ids.isEmpty)
      return _provider!.workers; // fallback: all provider workers
    return _provider!.workers.where((w) => ids.contains(w.id)).toList();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _error = null);
    try {
      // Get the service first (works even if /details is 403; we fallback internally)
      final svc = await _services.details(
        serviceId: widget.serviceId,
        providerId: widget.providerId,
      );

      // Resolve providerId:
      String? pid =
          (widget.providerId).trim().isEmpty ? null : widget.providerId;
      pid ??= svc.providerId; // from service payload if present
      pid ??= await _services
          .getProviderIdForService(widget.serviceId); // final fallback

      if (pid == null || pid.isEmpty) {
        throw Exception('Provider id is missing for the selected service.');
      }

      final prov = await _providers.getDetails(pid);

      setState(() {
        _service = svc;
        _provider = prov;
        _selectedWorkerId = widget.initialWorkerId // prefer deep-linked worker
            ??
            (svc.workerIds.isNotEmpty ? svc.workerIds.first : null);
      });

      _loadSlots();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _loadSlots() {
    if (_service == null) return;

    final list = _allowedWorkers;
    if (list.isEmpty) {
      setState(() => _slotsFuture = Future.value(const <String>[]));
      return;
    }

    final effectiveWorkerId = _selectedWorkerId ?? list.first.id;

    // ⛑️ Clamp to a sane minimum (handles PT0S, nulls, etc.)
    final rawMin = _service!.duration?.inMinutes ?? 0;
    final durationMin = rawMin <= 0 ? 30 : rawMin;

    setState(() {
      _selectedStart = null;
      _slotsFuture = _workers.freeSlots(
        workerId: effectiveWorkerId,
        date: _selectedDate,
        serviceDurationMinutes: durationMin,
      );
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _loadSlots();
    }
  }

  Future<void> _book(AppLocalizations t) async {
    final svc = _service;
    if (svc == null) return;
    final workers = _allowedWorkers;
    if (workers.isEmpty) return;
    final workerId = _selectedWorkerId ?? workers.first.id;
    final start = _selectedStart;
    if (start == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.booking_time)));
      return;
    }
    try {
      await _appointments.create(
        serviceId: svc.id,
        workerId: workerId,
        date: _selectedDate,
        startTimeHHmmss: start,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/customers', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final priceFmt = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    );

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.bookingTitle)),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Failed to load: $_error'),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: _bootstrap, child: Text(t.provider_retry)),
          ]),
        ),
      );
    }

    final svc = _service;
    final workers = _allowedWorkers;

    return Scaffold(
      appBar: AppBar(title: Text(t.bookingTitle)),
      body: (svc == null)
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // Worker choice chips
                if (workers.isNotEmpty) ...[
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: workers.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final isAnyone = i == 0;
                        final id = isAnyone ? null : workers[i - 1].id;
                        final name =
                            isAnyone ? t.booking_anyone : workers[i - 1].name;
                        final selected = _selectedWorkerId == id;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(name, overflow: TextOverflow.ellipsis),
                          onSelected: (_) {
                            setState(() => _selectedWorkerId = id);
                            _loadSlots();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Month header + date picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMM(
                              Localizations.localeOf(context).toLanguageTag())
                          .format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: const Text(''),
                    ),
                  ],
                ),
                CalendarDatePicker(
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                  initialDate: _selectedDate,
                  onDateChanged: (d) {
                    setState(() => _selectedDate = d);
                    _loadSlots();
                  },
                ),
                const SizedBox(height: 8),

                // Slots
                FutureBuilder<List<String>>(
                  future: _slotsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // If the API errored, show the same friendly text as "no slots".
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          // Use your existing translation:
                          // "booking_no_slots": "Bu kunda bo‘sh vaqt yo‘q."
                          t.booking_no_slots,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    final slots = snap.data ?? const <String>[];
                    if (slots.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          t.booking_no_slots, // “worker is not available on that day”
                          style: const TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((hhmmss) {
                        final hhmm = hhmmss.substring(0, 5); // "HH:mm"
                        final selected = _selectedStart == hhmmss;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(hhmm),
                          onSelected: (_) =>
                              setState(() => _selectedStart = hhmmss),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Service summary card
                Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(
                      svc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${(svc.duration ?? Duration.zero).inMinutes}m',
                    ),
                    trailing: Text(
                      priceFmt.format(svc.price),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: (svc == null)
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        priceFmt.format(svc.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_service == null) return;
                          final workers = _allowedWorkers;
                          if (workers.isEmpty || _selectedStart == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.booking_time)),
                            );
                            return;
                          }
                          final worker = workers.firstWhere(
                            (w) =>
                                (_selectedWorkerId ?? workers.first.id) == w.id,
                            orElse: () => workers.first,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReviewConfirmScreen(
                                service: _service!,
                                provider: _provider!,
                                worker: worker,
                                date: _selectedDate,
                                startHHmmss: _selectedStart!,
                              ),
                            ),
                          );
                        },
                        child: Text(t.booking_book),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
