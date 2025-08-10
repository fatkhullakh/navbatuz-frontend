import 'package:flutter/material.dart';
import 'package:frontend/screens/test/test_customer_home.dart';
import '../../models/provider.dart';
import '../../services/provider_service.dart';

// === REUSED Food UI shell (kept) ===

class FoodAppHomeScreen extends StatelessWidget {
  const FoodAppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const SizedBox(),
        title: Column(
          children: [
            Text(
              "Discover".toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: const Color(0xFF22A45D),
                  ),
            ),
            const Text("Nearby providers",
                style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {},
              child:
                  Text("Filter", style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
      body: const SafeArea(child: _CustomerHomeBody()),
    );
  }
}

// === BODY that wires API ===
class _CustomerHomeBody extends StatefulWidget {
  const _CustomerHomeBody();

  @override
  State<_CustomerHomeBody> createState() => _CustomerHomeBodyState();
}

class _CustomerHomeBodyState extends State<_CustomerHomeBody> {
  final _svc = ProviderService();
  final _scroll = ScrollController();
  final _providers = <ProviderItem>[];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _fetchFirst();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetchFirst() async {
    setState(() {
      _providers.clear();
      _hasMore = true;
      _page = 0;
    });
    await _fetchMore();
  }

  Future<void> _fetchMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final pageResp =
          await _svc.getProviders(page: _page, size: 10, sortBy: 'name');
      setState(() {
        _providers.addAll(pageResp.content);
        _hasMore = !pageResp.last;
        _page += 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load providers: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || !_hasMore) return;
    final nearBottom =
        _scroll.position.maxScrollExtent - _scroll.position.pixels < 200;
    if (nearBottom) _fetchMore();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchFirst,
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BigCardImageSlide(
                  images: demoBigImages), // keep your slider for now
            ),
            const SizedBox(height: 32),

            SectionTitle(title: "Featured Providers", press: () {}),
            const SizedBox(height: 16),
            _FeaturedHorizontal(providers: _providers, loading: _loading),

            const SizedBox(height: 20),
            const PromotionBanner(),
            const SizedBox(height: 20),

            SectionTitle(title: "All Providers", press: () {}),
            const SizedBox(height: 16),

            // Big list (uses same data)
            ...List.generate(_providers.length, (index) {
              final p = _providers[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: RestaurantInfoBigCard(
                  images: demoBigImages..shuffle(),
                  name: p.name,
                  rating: p.rating,
                  numOfRating: 0,
                  deliveryTime: 25,
                  foodType: _toTags(p),
                  press: () {
                    // TODO: navigate to provider details with p
                  },
                ),
              );
            }),

            if (_loading || _hasMore)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _toTags(ProviderItem p) {
    final tags = <String>[];
    if ((p.location.city ?? '').isNotEmpty) tags.add(p.location.city!);
    if ((p.location.district ?? '').isNotEmpty) tags.add(p.location.district!);
    if (tags.isEmpty) tags.add('Service');
    return tags.take(3).toList();
  }
}

// === Horizontal section (uses your MediumCard widgets) ===
class _FeaturedHorizontal extends StatelessWidget {
  final List<ProviderItem> providers;
  final bool loading;
  const _FeaturedHorizontal({required this.providers, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && providers.isEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
              2,
              (index) => const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: MediumCardScalton(),
                  )),
        ),
      );
    }

    final data = providers.take(10).toList();
    return SizedBox(
      width: double.infinity,
      height: 254,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, i) {
          final p = data[i];
          final city = p.location.city ?? '';
          final district = p.location.district ?? '';
          final loc = [city, district].where((e) => e.isNotEmpty).join(', ');
          return Padding(
            padding: EdgeInsets.only(
                left: 16, right: (i == data.length - 1) ? 16 : 0),
            child: RestaurantInfoMediumCard(
              image: demoMediumCardData.first['image'], // placeholder image
              name: p.name,
              location: loc.isEmpty ? 'No location' : loc,
              delivertTime: 25,
              rating: p.rating,
              press: () {
                // TODO: navigate to provider details with p
              },
            ),
          );
        },
      ),
    );
  }
}

// === Below are your existing Food UI widgets (unchanged) ===
// Keep your BigCardImageSlide, PromotionBanner, Skeletons, RestaurantInfo* widgets,
// and demoBigImages/demoMediumCardData constants exactly as you pasted.
// (No need to duplicate here — leave them in the same file.)
