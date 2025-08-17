import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/service_catalog_service.dart';
import '../../services/provider_public_service.dart';
import 'review_confirm_screen.dart';

class ServiceBookingScreen extends StatefulWidget {
  final String providerId;
  final String serviceId;
  const ServiceBookingScreen({
    super.key,
    required this.providerId,
    required this.serviceId,
  });

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final _svc = ServiceCatalogService();
  final _prov = ProviderPublicService();

  ServiceDetail? _service;
  ProvidersDetailsLite? _provider;
  bool _loading = true;
  String? _error;

  DateTime _date = DateTime.now();
  String? _selectedWorkerId; // null => Anyone
  String? _selectedTime; // "HH:mm:ss"
  String? _timeWorkerId; // worker who actually serves this selected time

  List<SlotOption> _anySlots = [];
  List<String> _singleSlots = [];

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
      final s = await _svc.getDetail(widget.serviceId);
      final p = await _prov.getDetails(widget.providerId);
      setState(() {
        _service = s;
        _provider = p;
        _selectedWorkerId = null; // default “Anyone”
      });
      await _loadSlots();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSlots() async {
    if (_service == null) return;
    setState(() {
      _selectedTime = null;
      _timeWorkerId = null;
    });
    final dateIso = DateFormat('yyyy-MM-dd').format(_date);
    final mins = _service!.durationMinutes;

    if (_selectedWorkerId == null) {
      final list = await _svc.freeSlotsForAny(
        workerIds: _service!.workerIds,
        dateIso: dateIso,
        serviceDurationMinutes: mins,
      );
      setState(() {
        _anySlots = list;
        _singleSlots = const [];
      });
    } else {
      final times = await _svc.freeSlotsRaw(
        workerId: _selectedWorkerId!,
        dateIso: dateIso,
        serviceDurationMinutes: mins,
      );
      setState(() {
        _singleSlots = times;
        _anySlots = const [];
      });
    }
  }

  String _fmtTime(String hhmmss) {
    final p = hhmmss.split(':');
    if (p.length >= 2) return '${p[0]}:${p[1]}';
    return hhmmss;
  }

  String _calcEnd(String start, int minutes) {
    final p = start.split(':');
    final base =
        DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1])); // local
    final end = base.add(Duration(minutes: minutes));
    return DateFormat('HH:mm:ss').format(end);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_service?.name ?? t.bookingTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBox(text: _error!, onRetry: _bootstrap)
              : _buildReady(t),
      bottomNavigationBar: _buildBottom(t),
    );
  }

  Widget _buildReady(AppLocalizations t) {
    final service = _service!;
    final prov = _provider!;

    // Workers that actually serve this service:
    final allowedWorkerIds = service.workerIds.toSet();
    final workers =
        prov.workers.where((w) => allowedWorkerIds.contains(w.id)).toList();

    final hasSlots = _selectedWorkerId == null
        ? _anySlots.isNotEmpty
        : _singleSlots.isNotEmpty;

    final chips = _selectedWorkerId == null
        ? _anySlots.map(
            (s) => ChoiceChip(
              label: Text(_fmtTime(s.hhmmss)),
              selected: _selectedTime == s.hhmmss,
              onSelected: (_) => setState(
                  () => {_selectedTime = s.hhmmss, _timeWorkerId = s.workerId}),
            ),
          )
        : _singleSlots.map(
            (h) => ChoiceChip(
              label: Text(_fmtTime(h)),
              selected: _selectedTime == h,
              onSelected: (_) => setState(
                  () => {_selectedTime = h, _timeWorkerId = _selectedWorkerId}),
            ),
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        // 1) Staff
        Text(t.bookingPickWorker,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t.anyone),
                  selected: _selectedWorkerId == null,
                  onSelected: (_) async {
                    setState(() => _selectedWorkerId = null);
                    await _loadSlots();
                  },
                ),
              ),
              for (final w in workers)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(w.name),
                    selected: _selectedWorkerId == w.id,
                    onSelected: (_) async {
                      setState(() => _selectedWorkerId = w.id);
                      await _loadSlots();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2) Date
        Text(t.pickDate, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        CalendarDatePicker(
          initialDate: _date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 180)),
          onDateChanged: (d) async {
            setState(() => _date = d);
            await _loadSlots();
          },
        ),
        const SizedBox(height: 8),

        // 3) Time
        Text(t.bookingPickTime,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (!hasSlots)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              t.bookingNoSlotsDay,
              style: const TextStyle(color: Colors.black54),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.toList(),
          ),

        const SizedBox(height: 16),

        // Summary preview (optional)
        if (_selectedTime != null)
          Card(
            elevation: 0,
            child: ListTile(
              title: Text(service.name),
              subtitle: Text(
                '${DateFormat('MMM d, yyyy').format(_date)} • '
                '${_fmtTime(_selectedTime!)} – ${_fmtTime(_calcEnd(_selectedTime!, service.durationMinutes))}',
              ),
              trailing: Text(
                NumberFormat.currency(
                        locale: 'en_US', symbol: '', decimalDigits: 0)
                    .format(service.price),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottom(AppLocalizations t) {
    final canBook =
        _selectedTime != null && _timeWorkerId != null && _service != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton(
          onPressed: canBook ? _goReview : null,
          child: Text(t.actionBook),
        ),
      ),
    );
  }

  void _goReview() {
    final dateIso = DateFormat('yyyy-MM-dd').format(_date);
    final service = _service!;
    final prov = _provider!;

    final workerName = () {
      if (_timeWorkerId == null) return null;
      final w = prov.workers.where((e) => e.id == _timeWorkerId).toList();
      return w.isEmpty ? null : w.first.name;
    }();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewConfirmScreen(
          providerId: prov.id,
          providerName: prov.name,
          serviceId: service.id,
          serviceName: service.name,
          price: service.price,
          durationMinutes: service.durationMinutes,
          workerId: _timeWorkerId!,
          workerName: workerName ?? AppLocalizations.of(context)!.anyone,
          dateIso: dateIso,
          startTime: _selectedTime!,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;
  final Future<void> Function() onRetry;
  const _ErrorBox({required this.text, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context)!.action_retry)),
          ],
        ),
      );
}
