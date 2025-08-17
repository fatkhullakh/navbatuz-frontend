import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/provider_public_service.dart';
import '../../services/service_catalog_service.dart';
import '../../screens/booking/service_booking_screen.dart';

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
  bool _isFav = false;
  bool _favBusy = false;

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
      final favs = await _providers.getFavouriteIds();
      setState(() {
        _details = d;
        _isFav = favs.contains(d.id);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleFav() async {
    if (_details == null) return;
    setState(() => _favBusy = true);
    try {
      await _providers.setFavourite(_details!.id, !_isFav);
      setState(() => _isFav = !_isFav);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _favBusy = false);
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

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: const FlexibleSpaceBar(
              background: ColoredBox(color: Color(0xFFF2F4F7)), // placeholder
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(104),
              child: _buildHeader(t),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: t.provider_tab_services),
                  Tab(text: t.provider_tab_reviews),
                  Tab(text: t.provider_tab_details),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _ServicesTab(
              future: _futureServices,
              onBook: (s) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceBookingScreen(
                      providerId: providerId, // the current provider id
                      serviceId: service.id, // the tapped service id
                    ),
                  ),
                );
              },
            ),
            const _ReviewsTab(),
            _DetailsTab(details: _details),
          ],
        ),
      ),
      floatingActionButton: (_details == null || _error != null)
          ? null
          : FloatingActionButton.extended(
              onPressed: _favBusy ? null : _toggleFav,
              icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border),
              label:
                  Text(_isFav ? t.provider_favourited : t.provider_favourite),
            ),
    );
  }

  Widget _buildHeader(AppLocalizations t) {
    if (_error != null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Failed to load: $_error'),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: _loadHeader, child: Text(t.provider_retry)),
          ],
        ),
      );
    }
    if (_details == null) {
      return const SizedBox(
        height: 104,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final d = _details!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + rating + share
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.star_rate_rounded, size: 18),
              const SizedBox(width: 4),
              Text(d.avgRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.share_outlined)),
            ],
          ),
          const SizedBox(height: 4),
          if ((d.location?.compact ?? '').isNotEmpty)
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    d.location!.compact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);
  @override
  Widget build(context, shrink, overlap) =>
      Container(color: Colors.white, child: tabBar);
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _ServicesTab extends StatelessWidget {
  final Future<List<ServiceSummary>> future;
  final void Function(ServiceSummary) onBook;
  const _ServicesTab({required this.future, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final priceFmt =
        NumberFormat.currency(locale: localeTag, symbol: '', decimalDigits: 0);

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
          itemBuilder: (_, i) {
            final s = items[i];
            final parts = <String>[];
            if (s.category.isNotEmpty) parts.add(s.category);
            final d = s.duration;
            if (d != null) {
              final h = d.inHours;
              final m = d.inMinutes % 60;
              if (h > 0 && m > 0)
                parts.add('${h}h ${m}m');
              else if (h > 0)
                parts.add('${h}h');
              else
                parts.add('${m}m');
            }
            final priceText =
                s.price == 0 ? t.provider_free : priceFmt.format(s.price);

            return Card(
              elevation: 0,
              child: ListTile(
                title:
                    Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: parts.isNotEmpty ? Text(parts.join(' • ')) : null,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(priceText,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 88,
                      height: 28,
                      child: ElevatedButton(
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
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(AppLocalizations.of(context)!.provider_no_reviews));
}

class _DetailsTab extends StatelessWidget {
  final ProvidersDetails? details;
  const _DetailsTab({required this.details});

  // Localize server day name ("MONDAY") to full day name in current locale.
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if ((d.description ?? '').isNotEmpty) ...[
          Text(t.provider_about,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(d.description!),
          const SizedBox(height: 16),
        ],

        Text(t.provider_category,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(d.category),
        const SizedBox(height: 16),

        if ((d.location?.compact ?? '').isNotEmpty) ...[
          Text(t.provider_address,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.place_outlined, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(d.location!.compact)),
          ]),
          const SizedBox(height: 16),
        ],

        // Contacts
        if (d.email.isNotEmpty || d.phone.isNotEmpty) ...[
          Text(t.provider_contacts,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (d.email.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(t.provider_email_label),
              subtitle: Text(d.email),
            ),
          if (d.phone.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: Text(t.provider_phone_label),
              subtitle: Text(d.phone),
            ),
          const SizedBox(height: 8),
        ],

        // Workers
        if (d.workers.isNotEmpty) ...[
          Text(t.provider_team,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: d.workers.map((w) {
              return Chip(
                label: Text(w.name, overflow: TextOverflow.ellipsis),
                avatar: const Icon(Icons.person, size: 16),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Working hours
        if (d.businessHours.isNotEmpty) ...[
          Text(t.provider_hours,
              style: const TextStyle(fontWeight: FontWeight.w700)),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: (h.start == null || h.end == null)
                        ? Text(t.provider_closed)
                        : Text('${_trimHHmm(h.start)} – ${_trimHHmm(h.end)}'),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
