import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/service_catalog_service.dart';
import '../../services/provider_public_service.dart';
import '../providers/provider_screen.dart';
import '../booking/service_booking_screen.dart';
import '../../services/api_service.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  final String providerId;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    required this.providerId,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final _svc = ServiceCatalogService();
  final _providers = ProviderPublicService();

  ServiceDetails? _details;
  ProviderResponse? _provider;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await _svc.details(
        serviceId: widget.serviceId,
        providerId: widget.providerId,
      );
      final p = await _providers.getById(widget.providerId);
      if (!mounted) return;
      setState(() {
        _details = d;
        _provider = p;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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
        appBar: AppBar(title: Text(t.service_details_title)),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Failed to load: $_error'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: Text(t.provider_retry)),
          ]),
        ),
      );
    }

    final d = _details;
    final p = _provider;

    return Scaffold(
      appBar: AppBar(title: Text(t.service_details_title)),
      body: (d == null || p == null)
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),

                // Provider name → tap to open provider page
                Row(
                  children: [
                    Text(t.service_from,
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => ProviderScreen(providerId: p.id),
                          ),
                        );
                      },
                      child: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (d.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: d.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          ApiService.normalizeMediaUrl(d.imageUrls[i])!,
                          fit: BoxFit.cover,
                          width: 160,
                          height: 120,
                          errorBuilder: (_, __, ___) => Container(
                            width: 160,
                            height: 120,
                            color: const Color(0xFFF2F4F7),
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),

                if ((d.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    d.description!,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],

                const SizedBox(height: 16),

                // Price & duration card
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.local_offer_outlined),
                    title: Text(priceFmt.format(d.price),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      d.duration == null ? '-' : '${d.duration!.inMinutes}m',
                    ),
                    trailing: Text(d.category),
                  ),
                ),

                const SizedBox(height: 8),

                // Workers
                if (d.workers.isNotEmpty) ...[
                  Text(t.provider_team,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: d.workers
                        .map((w) => Chip(
                              avatar: const Icon(Icons.person, size: 16),
                              label:
                                  Text(w.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: (d == null || p == null)
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServiceBookingScreen(
                            serviceId: d.id,
                            providerId: p.id,
                          ),
                        ),
                      );
                    },
                    child: Text(t.booking_book),
                  ),
                ),
              ),
            ),
    );
  }
}
