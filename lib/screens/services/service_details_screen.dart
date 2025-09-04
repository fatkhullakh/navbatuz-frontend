import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/services/service_catalog_service.dart';
import '../../services/api_service.dart';
import '../booking/service_booking_screen.dart';

/* ---------------------------- Brand constants ---------------------------- */
class _Brand {
  static const primary = Color(0xFF6A89A7); // #6A89A7
  static const accent = Color(0xFF88BDF2); // #88BDF2
  static const accentSoft = Color(0xFFBDDDFC); // #BDDDFC
  static const ink = Color(0xFF384959); // #384959
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
}

/* ------------------------------ Helpers --------------------------------- */
String _normCat(String? s) =>
    (s ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

String _localizedCategory(BuildContext context, String? idOrName) {
  final t = AppLocalizations.of(context)!;
  switch (_normCat(idOrName)) {
    case 'barbershop':
      return t.cat_barbershop;
    case 'dental':
    case 'dentist':
      return t.cat_dental;
    case 'clinic':
      return t.cat_clinic;
    case 'spa':
      return t.cat_spa;
    case 'gym':
      return t.cat_gym;
    case 'nail_salon':
      return t.cat_nail_salon;
    case 'beauty_clinic':
      return t.cat_beauty_clinic;
    case 'tattoo_studio':
      return t.cat_tattoo_studio;
    case 'massage_center':
      return t.cat_massage_center;
    case 'physiotherapy_clinic':
      return t.cat_physiotherapy_clinic;
    case 'makeup_studio':
      return t.cat_makeup_studio;
    default:
      return idOrName ?? '';
  }
}

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
      appBar: AppBar(
        title: Text(t.provider_book), // simple, keeps context clear
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Divider(height: 1, thickness: 1, color: _Brand.border),
        ),
      ),
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
          final catLabel = _localizedCategory(context, d.category);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  // Title
                  Text(
                    d.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _Brand.ink,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Images
                  if (d.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: d.imageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final url =
                              ApiService.normalizeMediaUrl(d.imageUrls[i]) ??
                                  d.imageUrls[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: 180,
                              height: 140,
                              errorBuilder: (_, __, ___) => Container(
                                width: 180,
                                height: 140,
                                color: _Brand.accentSoft.withOpacity(.5),
                                child: const Icon(Icons.broken_image_outlined,
                                    color: _Brand.subtle),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: _Brand.accentSoft.withOpacity(.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _Brand.border, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined,
                          color: _Brand.subtle),
                    ),

                  const SizedBox(height: 12),

                  // Description
                  if ((d.description ?? '').isNotEmpty) ...[
                    Text(t.provider_about,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _Brand.ink,
                        )),
                    const SizedBox(height: 6),
                    Text(d.description!,
                        style: const TextStyle(color: _Brand.ink)),
                    const SizedBox(height: 12),
                  ],

                  // Category & duration chips (brand-styled)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (d.category.isNotEmpty)
                        _Chip(
                          icon: Icons.category,
                          label: catLabel,
                        ),
                      if (durText.isNotEmpty)
                        _Chip(
                          icon: Icons.schedule,
                          label: durText,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Workers
                  if (d.workers.isNotEmpty) ...[
                    Text(t.provider_team,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _Brand.ink,
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: d.workers
                          .map((w) => InputChip(
                                avatar: const Icon(Icons.person_outline,
                                    size: 16, color: _Brand.ink),
                                label: Text(w.name,
                                    overflow: TextOverflow.ellipsis),
                                side: const BorderSide(color: _Brand.border),
                                backgroundColor:
                                    _Brand.accentSoft.withOpacity(.35),
                                onPressed: null, // keep non-clickable here
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
                    border: const Border(top: BorderSide(color: _Brand.border)),
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
                      // price + duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // price pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _Brand.accentSoft.withOpacity(.6),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: _Brand.border),
                              ),
                              child: Text(
                                priceText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _Brand.ink,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (durText.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(durText,
                                  style: const TextStyle(color: _Brand.subtle)),
                            ],
                          ],
                        ),
                      ),

                      // book button
                      SizedBox(
                        width: 148,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Brand.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
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

/* ----------------------------- Tiny UI bits ----------------------------- */
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: _Brand.ink),
      label: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: _Brand.border),
      backgroundColor: _Brand.accentSoft.withOpacity(.35),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
