import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/service_catalog_service.dart';
import '../../services/provider_public_service.dart';
import '../../services/worker_service.dart';
import '../../services/appointment_service.dart';
import 'review_confirm_screen.dart';

class ServiceBookingScreen extends StatefulWidget {
  final String serviceId;
  final String providerId;
  const ServiceBookingScreen({
    super.key,
    required this.serviceId,
    required this.providerId,
  });

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final _services = ServiceCatalogService();
  final _providers = ProviderPublicService();
  final _workers = WorkerService();
  final _appointments = AppointmentService();

  ServiceDetail? _service;
  ProvidersDetails? _provider;
  String?
      _selectedWorkerId; // null => "Anyone" (we'll use first allowed worker)
  DateTime _selectedDate = DateTime.now();
  Future<List<String>>? _slotsFuture; // "HH:mm:ss"
  String? _selectedStart; // "HH:mm:ss"
  String? _error;

  List<WorkerLite> get _allowedWorkers {
    if (_service == null || _provider == null) return const [];
    final ids = _service!.workerIds.toSet();
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
      final svc = await _services.getDetail(widget.serviceId);
      final prov = await _providers.getDetails(widget.providerId);
      setState(() {
        _service = svc;
        _provider = prov;
      });
      _selectedWorkerId = svc.workerIds.isNotEmpty ? svc.workerIds.first : null;
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
    setState(() {
      _selectedStart = null;
      _slotsFuture = _workers.freeSlots(
        workerId: effectiveWorkerId,
        date: _selectedDate,
        serviceDurationMinutes: _service!.duration.inMinutes,
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
    if (_service == null) return;
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
        serviceId: _service!.id,
        workerId: workerId,
        date: _selectedDate,
        startTimeHHmmss: start,
      );
      if (!mounted) return;
      // success → go to appointments tab
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/customers',
        (r) => false,
      );
      // then select appointments tab (your NavRoot already exposes openAppointment from home; if needed, emit a route or use a deep link)
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
                // Worker chips (Anyone + allowed workers)
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

                // Calendar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        DateFormat.yMMMM(
                                Localizations.localeOf(context).toLanguageTag())
                            .format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
                    if (snap.hasError) {
                      return Column(
                        children: [
                          Text('Failed to load slots: ${snap.error}'),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _loadSlots,
                            child: Text(t.booking_slots_retry),
                          ),
                        ],
                      );
                    }
                    final slots = snap.data ?? const <String>[];
                    if (slots.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(t.booking_no_slots),
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

                // Service card
                Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(svc.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${svc.duration.inMinutes}m'),
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
