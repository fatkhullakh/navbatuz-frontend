import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/service_catalog_service.dart';
import '../../services/api_service.dart';
import '../booking/service_booking_screen.dart';

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
  late Future<ServiceDetails> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.details(
      serviceId: widget.serviceId,
      providerId: widget.providerId,
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  int _displayMinutes(Duration? d) {
    final mins = d?.inMinutes ?? 0;
    return mins <= 0 ? 30 : mins; // fallback for PT0S/missing duration
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final priceFmt =
        NumberFormat.currency(locale: localeTag, symbol: '', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<ServiceDetails>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed: ${snap.error}'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _future = _svc.details(
                        serviceId: widget.serviceId,
                        providerId: widget.providerId,
                      );
                    }),
                    child: Text(t.provider_retry),
                  ),
                ],
              ),
            );
          }

          final d = snap.data!;
          final priceText =
              d.price == 0 ? t.provider_free : priceFmt.format(d.price);
          final durTextRaw = _formatDuration(d.duration);
          final durText = durTextRaw.isEmpty
              ? '${_displayMinutes(d.duration)}m'
              : durTextRaw;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  // Title
                  Text(
                    d.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  // Images
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
                            d.imageUrls[i],
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
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined),
                    ),

                  const SizedBox(height: 12),

                  // Description
                  if ((d.description ?? '').isNotEmpty) ...[
                    Text(t.provider_about,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(d.description!),
                    const SizedBox(height: 12),
                  ],

                  // Category & duration chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (d.category.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.category, size: 16),
                          label: Text(d.category),
                        ),
                      if (durText.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.schedule, size: 16),
                          label: Text(durText),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

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
                                avatar:
                                    const Icon(Icons.person_outline, size: 16),
                                label: Text(
                                  w.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),

              // Sticky bottom bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(priceText,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 18)),
                            if (durText.isNotEmpty)
                              Text(durText,
                                  style:
                                      const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            // be robust: prefer service.providerId if present
                            final pid = d.providerId?.isNotEmpty == true
                                ? d.providerId!
                                : widget.providerId;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceBookingScreen(
                                  serviceId: d.id,
                                  providerId: pid,
                                ),
                              ),
                            );
                          },
                          child: Text(t.provider_book),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
