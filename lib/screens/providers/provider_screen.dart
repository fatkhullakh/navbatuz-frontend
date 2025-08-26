import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/services/provider_public_service.dart';
import '../../services/services/service_catalog_service.dart';
import '../../screens/booking/service_booking_screen.dart';
import '../../widgets/favorite_toggle_button.dart';
import '../../screens/services/service_details_screen.dart';
import '../workers/worker_screen.dart';

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

/* ------------------------------ Screen ---------------------------------- */
class ProviderScreen extends StatefulWidget {
  final String providerId;
  const ProviderScreen({super.key, required this.providerId});

  @override
  State<ProviderScreen> createState() => _ProviderScreenState();
}

class _ProviderScreenState extends State<ProviderScreen>
    with TickerProviderStateMixin {
  final _providers = ProviderPublicService();
  final _services = ServiceCatalogService();
  late final TabController _tabs;

  ProvidersDetails? _details;
  String? _error;
  bool? _initialFav;

  late Future<List<ServiceSummary>> _futureServices;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _futureServices = _services.byProvider(widget.providerId);
    _loadHeader();
  }

  Future<void> _loadHeader() async {
    setState(() => _error = null);
    try {
      final d = await _providers.getDetails(widget.providerId);
      final favIds = await _providers.getFavouriteIds();
      setState(() {
        _details = d;
        _initialFav = favIds.contains(d.id);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final logo = _details?.logoUrl;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: (logo != null && logo.isNotEmpty)
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          logo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFFF2F4F7)),
                        ),
                        Container(color: Colors.black.withOpacity(0.12)),
                      ],
                    ),
                  )
                : const FlexibleSpaceBar(
                    background: ColoredBox(color: Color(0xFFF2F4F7)),
                  ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(116),
              child: SizedBox.shrink(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderSection(
                      details: _details, error: _error, onRetry: _loadHeader),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: _Brand.border)),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      indicatorColor: _Brand.primary,
                      labelColor: _Brand.ink,
                      unselectedLabelColor: _Brand.subtle,
                      tabs: [
                        Tab(text: t.provider_tab_services),
                        Tab(text: t.provider_tab_reviews),
                        Tab(text: t.provider_tab_details),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _ServicesTab(
              providerId: widget.providerId,
              future: _futureServices,
              onBook: (s) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceBookingScreen(
                      serviceId: s.id,
                      providerId: widget.providerId,
                    ),
                  ),
                );
              },
            ),
            const _ReviewsTab(),
            _DetailsTab(
              details: _details,
              providerId: widget.providerId,
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Sticky header UI --------------------------- */
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickyHeaderDelegate({required this.child});
  @override
  Widget build(context, shrink, overlap) =>
      Material(color: Colors.white, child: child);
  @override
  double get maxExtent => 123 + kTextTabBarHeight; // header + TabBar
  @override
  double get minExtent => 123 + kTextTabBarHeight;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class _HeaderSection extends StatelessWidget {
  final ProvidersDetails? details;
  final String? error;
  final Future<void> Function() onRetry;
  const _HeaderSection(
      {required this.details, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (error != null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Failed to load: $error'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: Text(t.provider_retry)),
          ],
        ),
      );
    }
    if (details == null) {
      return const SizedBox(
        height: 116,
        child: Center(
            child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator())),
      );
    }

    final d = details!;
    final catLabel = _localizedCategory(context, d.category);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _Brand.border),
          bottom: BorderSide(color: _Brand.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + rating + fav + share
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _Brand.ink),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star_rate_rounded,
                  size: 18, color: _Brand.primary),
              const SizedBox(width: 4),
              Text(d.avgRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              FavoriteToggleButton(
                  providerId: d.id, initialIsFavorite: null, onChanged: () {}),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                  tooltip: t.provider_tab_details),
            ],
          ),
          const SizedBox(height: 6),
          if (catLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 16, color: _Brand.subtle),
                  const SizedBox(width: 6),
                  Text(catLabel, style: const TextStyle(color: _Brand.subtle)),
                ],
              ),
            ),
          if ((d.location?.compact ?? '').isNotEmpty)
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 16, color: _Brand.subtle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    d.location!.compact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _Brand.subtle),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/* ------------------------------ Services tab ---------------------------- */
class _ServicesTab extends StatelessWidget {
  final String providerId;
  final Future<List<ServiceSummary>> future;
  final void Function(ServiceSummary) onBook;
  const _ServicesTab({
    required this.providerId,
    required this.future,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final priceFmt =
        NumberFormat.currency(locale: localeTag, symbol: '', decimalDigits: 0);

    String durText(Duration? d) {
      if (d == null) return '';
      final h = d.inHours;
      final m = d.inMinutes % 60;
      if (h > 0 && m > 0) return '${h}h ${m}m';
      if (h > 0) return '${h}h';
      return '${m}m';
    }

    return FutureBuilder<List<ServiceSummary>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Failed to load: ${snap.error}'),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () {}, child: Text(t.provider_retry)),
            ]),
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) return Center(child: Text(t.provider_no_services));

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final s = items[i];
            final desc = (s.description ?? '').trim();
            final dur = durText(s.duration);
            final priceText =
                s.price == 0 ? t.provider_free : priceFmt.format(s.price);

            return Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _Brand.border, width: 1),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailsScreen(
                        serviceId: s.id,
                        providerId: providerId,
                      ),
                    ),
                  );
                },
                title: Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _Brand.ink, fontWeight: FontWeight.w800),
                ),
                // Show description (2 lines) + duration pill with top gap if needed
                subtitle: (desc.isNotEmpty || dur.isNotEmpty)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (desc.isNotEmpty)
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _Brand.subtle),
                            ),
                          if (dur.isNotEmpty)
                            Padding(
                              padding:
                                  EdgeInsets.only(top: desc.isNotEmpty ? 6 : 0),
                              child: _Pill(icon: Icons.schedule, label: dur),
                            ),
                        ],
                      )
                    : null,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(priceText,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: _Brand.ink)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 30,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: _Brand.accentSoft.withOpacity(.75),
                          foregroundColor: _Brand.ink,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => onBook(s),
                        child: Text(t.provider_book,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* ------------------------------ Reviews tab ----------------------------- */
class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(AppLocalizations.of(context)!.provider_no_reviews));
}

/* ------------------------------ Details tab ----------------------------- */
class _DetailsTab extends StatelessWidget {
  final ProvidersDetails? details;
  final String providerId;
  const _DetailsTab({required this.details, required this.providerId});

  String _localizedDay(BuildContext context, String serverDay) {
    final map = {
      'MONDAY': 1,
      'TUESDAY': 2,
      'WEDNESDAY': 3,
      'THURSDAY': 4,
      'FRIDAY': 5,
      'SATURDAY': 6,
      'SUNDAY': 7,
    };
    final wd = map[serverDay.toUpperCase()];
    if (wd == null) return serverDay;
    final now = DateTime.now();
    final diff = (wd - now.weekday) % 7;
    final ref = now.add(Duration(days: diff));
    final locale = Localizations.localeOf(context).toLanguageTag();
    String day = DateFormat('EEEE', locale).format(ref);
    return day[0].toUpperCase() + day.substring(1);
  }

  String _trimHHmm(String? hhmmss) {
    if (hhmmss == null || hhmmss.isEmpty) return '';
    final p = hhmmss.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : hhmmss;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final d = details;
    if (d == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final catLabel = _localizedCategory(context, d.category);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if ((d.description ?? '').isNotEmpty) ...[
          Text(t.provider_about,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _Brand.ink)),
          const SizedBox(height: 6),
          Text(d.description!, style: const TextStyle(color: _Brand.ink)),
          const SizedBox(height: 16),
        ],
        Text(t.provider_category,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: _Brand.ink)),
        const SizedBox(height: 6),
        Text(catLabel, style: const TextStyle(color: _Brand.subtle)),
        const SizedBox(height: 16),
        if ((d.location?.compact ?? '').isNotEmpty) ...[
          Text(t.provider_address,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _Brand.ink)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.place_outlined, size: 18, color: _Brand.subtle),
            const SizedBox(width: 6),
            Expanded(
                child: Text(d.location!.compact,
                    style: const TextStyle(color: _Brand.subtle))),
          ]),
          const SizedBox(height: 16),
        ],
        if (d.email.isNotEmpty || d.phone.isNotEmpty) ...[
          Text(t.provider_contacts,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _Brand.ink)),
          const SizedBox(height: 8),
          if (d.email.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined, color: _Brand.ink),
              title: Text(t.provider_email_label),
              subtitle: Text(d.email),
            ),
          if (d.phone.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined, color: _Brand.ink),
              title: Text(t.provider_phone_label),
              subtitle: Text(d.phone),
            ),
          const SizedBox(height: 8),
        ],
        if (d.workers.isNotEmpty) ...[
          Text(t.provider_team,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _Brand.ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: d.workers.map((w) {
              return InputChip(
                avatar: const Icon(Icons.person, size: 16, color: _Brand.ink),
                label: Text(w.name, overflow: TextOverflow.ellipsis),
                side: const BorderSide(color: _Brand.border),
                backgroundColor: _Brand.accentSoft.withOpacity(.35),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkerScreen(
                        workerId: w.id,
                        providerId: providerId,
                        workerNameFallback: w.name,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (d.businessHours.isNotEmpty) ...[
          Text(t.provider_hours,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _Brand.ink)),
          const SizedBox(height: 8),
          for (final h in d.businessHours)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      _localizedDay(context, h.day),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: _Brand.ink),
                    ),
                  ),
                  Expanded(
                    child: (h.start == null || h.end == null)
                        ? Text(t.provider_closed,
                            style: const TextStyle(color: _Brand.subtle))
                        : Text('${_trimHHmm(h.start)} – ${_trimHHmm(h.end)}',
                            style: const TextStyle(color: _Brand.subtle)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/* ----------------------------- Tiny UI bits ----------------------------- */
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
