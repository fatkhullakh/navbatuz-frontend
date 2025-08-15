import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/home_service.dart';
import '../../models/appointment.dart';
import '../../models/provider.dart' as models;
import '../search/search_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAppointments;
  const CustomerHomeScreen({
    super.key,
    required this.onOpenSearch,
    required this.onOpenAppointments,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _svc = HomeService();
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.loadAll();
  }

  Future<void> _refresh() async {
    final f = _svc.loadAll(); // async work outside setState
    setState(() {
      _future = f; // setState returns void
    });
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<HomeData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _Skeleton();
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  _ErrorBox(
                    text: 'Failed to load home. Pull to refresh.',
                    onRetry: _refresh,
                  ),
                ],
              );
            }
            final data = snap.data!;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SearchBar(onTap: widget.onOpenSearch),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Categories',
                    child: _CategoryChips(
                      categories: data.categories,
                      onTap: (c) {
                        // TODO: wire filtered search by category
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen()),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Upcoming appointment',
                    child: data.upcomingAppointment != null
                        ? _UpcomingCard(
                            item: data.upcomingAppointment!,
                            onTap: widget.onOpenAppointments,
                          )
                        : _NoUpcoming(onTap: widget.onOpenAppointments),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Favorites',
                    trailing: data.favoriteShops.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              // TODO: wire to favorites list
                            },
                            child: const Text('See all'),
                          )
                        : null,
                    child: data.favoriteShops.isNotEmpty
                        ? _ProviderRow(shops: data.favoriteShops)
                        : const _MutedNote('No favorites yet.'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Recommended',
                    trailing: data.recommendedShops.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              // TODO: wire to recommended list
                            },
                            child: const Text('See all'),
                          )
                        : null,
                    child: data.recommendedShops.isNotEmpty
                        ? _ProviderRow(shops: data.recommendedShops)
                        : const _MutedNote('No recommendations right now.'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                Icon(Icons.search_rounded),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search services or businesses',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<CategoryItem> categories;
  final void Function(CategoryItem) onTap;
  const _CategoryChips({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const _MutedNote('No categories.');
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          return GestureDetector(
            onTap: () => onTap(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF2FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF77ADE2)),
              ),
              child: Text(
                c.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoUpcoming extends StatelessWidget {
  final VoidCallback onTap;
  const _NoUpcoming({required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.event_note_rounded),
        label: const Text('Go to my appointments →'),
      );
}

class _UpcomingCard extends StatelessWidget {
  final AppointmentItem item;
  final VoidCallback onTap;
  const _UpcomingCard({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final time = DateFormat('EEE, d MMM • HH:mm').format(item.start);
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.event_available),
        title: Text(item.serviceName ?? 'Service',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${item.providerName ?? 'Provider'} • $time',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final List<models.ProviderItem> shops;
  const _ProviderRow({required this.shops});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = shops[i];
          final address = s.location.compact; // may be empty
          return SizedBox(
            width: 240,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    Navigator.of(context).pushNamed('/shop', arguments: s.id),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFF2F4F7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (address.isNotEmpty)
                        Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      Row(
                        children: [
                          const Icon(Icons.star_rate_rounded, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            s.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MutedNote extends StatelessWidget {
  final String text;
  const _MutedNote(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      );
}

class _ErrorBox extends StatelessWidget {
  final String text;
  final Future<void> Function() onRetry;
  const _ErrorBox({required this.text, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          children: [
            Text(text),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: () => onRetry(), child: const Text('Retry')),
          ],
        ),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(12),
          ),
        );
    return ListView(children: [box(48), box(56), box(96), box(180), box(180)]);
  }
}
