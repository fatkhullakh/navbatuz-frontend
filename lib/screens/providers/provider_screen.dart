import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/provider_public_service.dart';
import '../../services/service_catalog_service.dart';

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
    final header = _buildHeader();
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                  color: const Color(0xFFF2F4F7)), // placeholder image
            ),
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(104), child: header),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'SERVICES'),
                  Tab(text: 'REVIEWS'),
                  Tab(text: 'DETAILS'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _ServicesTab(future: _futureServices),
            const _ReviewsTab(), // placeholder
            _DetailsTab(details: _details),
          ],
        ),
      ),
      floatingActionButton: (_details == null || _error != null)
          ? null
          : FloatingActionButton.extended(
              onPressed: _favBusy ? null : _toggleFav,
              icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border),
              label: Text(_isFav ? 'Favourited' : 'Favourite'),
            ),
    );
  }

  Widget _buildHeader() {
    if (_error != null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Failed to load: $_error'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _loadHeader, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_details == null) {
      return Container(
        color: Colors.white,
        height: 104,
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
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
          // Title + rating + share + fav (the FAB also toggles fav)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(d.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
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
                    child: Text(d.location!.compact,
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
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
  const _ServicesTab({required this.future});

  @override
  Widget build(BuildContext context) {
    final priceFmt =
        NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);
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
              OutlinedButton(onPressed: () {}, child: const Text('Retry')),
            ]),
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) return const Center(child: Text('No services.'));
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
            return Card(
              elevation: 0,
              child: ListTile(
                title:
                    Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(parts.join(' • ')),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.price == 0 ? 'FREE' : priceFmt.format(s.price),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 76,
                      height: 28,
                      child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Book',
                              style: TextStyle(fontSize: 12))),
                    )
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
      const Center(child: Text('No reviews yet.'));
}

class _DetailsTab extends StatelessWidget {
  final ProvidersDetails? details;
  const _DetailsTab({required this.details});

  @override
  Widget build(BuildContext context) {
    final d = details;
    if (d == null) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(12.0),
        child: CircularProgressIndicator(),
      ));
    }
    final tf = DateFormat('HH:mm');
    String trim(String s) {
      final p = s.split(':');
      if (p.length >= 2) return '${p[0]}:${p[1]}';
      return s;
    }

    String niceDay(String serverDay) {
      switch (serverDay.toUpperCase()) {
        case 'MONDAY':
          return 'Mon';
        case 'TUESDAY':
          return 'Tue';
        case 'WEDNESDAY':
          return 'Wed';
        case 'THURSDAY':
          return 'Thu';
        case 'FRIDAY':
          return 'Fri';
        case 'SATURDAY':
          return 'Sat';
        case 'SUNDAY':
          return 'Sun';
      }
      return serverDay;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if ((d.description ?? '').isNotEmpty) ...[
          const Text('About', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(d.description!),
          const SizedBox(height: 16),
        ],
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(d.category),
        const SizedBox(height: 16),
        if ((d.location?.compact ?? '').isNotEmpty) ...[
          const Text('Address', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.place_outlined, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(d.location!.compact)),
          ]),
          const SizedBox(height: 16),
        ],
        if (d.businessHours.isNotEmpty) ...[
          const Text('Working hours',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final h in d.businessHours)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                      width: 90,
                      child: Text(niceDay(h.day),
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('${trim(h.start)} – ${trim(h.end)}'),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
