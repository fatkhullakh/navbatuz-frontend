import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/home_service.dart' as hs;

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
  final _svc = hs.HomeService();
  late Future<hs.HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.loadAll();
  }

  Future<void> _refresh() async {
    setState(() => _future = _svc.loadAll());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<hs.HomeData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _Skeleton();
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  _ErrorBox(text: t.error_home_failed, onRetry: _refresh),
                ],
              );
            }
            final data = snap.data!;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SearchBar(
                      onTap: widget.onOpenSearch, hint: t.home_search_hint),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    title: t.categories,
                    child: _CategoryChips(
                      categories: data.categories,
                      onTap: (c) => Navigator.of(context).pushNamed(
                        '/providers',
                        arguments: {'categoryId': c.id},
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    title: t.upcoming_appointment,
                    child: () {
                      final a = data.upcomingAppointment;
                      if (a == null) {
                        return _NoUpcoming(
                            onTap: widget.onOpenAppointments,
                            label: t.btn_go_appointments);
                      }
                      DateTime? start;
                      final dd =
                          (a.date?.toLowerCase() == 'null') ? null : a.date;
                      final tt = (a.startTime?.toLowerCase() == 'null')
                          ? null
                          : a.startTime;
                      if (dd != null && tt != null) {
                        start = DateTime.tryParse('${dd}T$tt');
                      }
                      return _UpcomingCard(
                        start: start,
                        serviceName: a.serviceName,
                        providerName: a.providerName,
                        onTap: widget.onOpenAppointments, // switch tab
                      );
                    }(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    title: t.favorites,
                    trailing: data.favoriteShops.isNotEmpty
                        ? TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(
                              '/providers',
                              arguments: {'filter': 'favorites'},
                            ),
                            child: Text(t.see_all),
                          )
                        : null,
                    child: data.favoriteShops.isNotEmpty
                        ? _ProviderRow(shops: data.favoriteShops)
                        : _MutedNote(t.no_favorites),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    title: t.recommended,
                    trailing: data.recommendedShops.isNotEmpty
                        ? TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(
                              '/providers',
                              arguments: {'filter': 'recommended'},
                            ),
                            child: Text(t.see_all),
                          )
                        : null,
                    child: data.recommendedShops.isNotEmpty
                        ? _ProviderRow(shops: data.recommendedShops)
                        : _MutedNote(t.no_recommended),
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
  final String hint;
  const _SearchBar({required this.onTap, required this.hint});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
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
  final List<hs.CategoryItem> categories;
  final void Function(hs.CategoryItem) onTap;
  const _CategoryChips({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (categories.isEmpty) return _MutedNote(t.no_categories);
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
              child: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}

class _NoUpcoming extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _NoUpcoming({required this.onTap, required this.label});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.event_note_rounded),
        label: Text(label),
      );
}

class _UpcomingCard extends StatelessWidget {
  final DateTime? start;
  final String? serviceName;
  final String? providerName;
  final VoidCallback onTap;

  const _UpcomingCard({
    super.key,
    required this.start,
    required this.serviceName,
    required this.providerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeText =
        start != null ? DateFormat('EEE, d MMM • HH:mm').format(start!) : null;
    final subtitleParts = <String>[];
    if ((providerName ?? '').isNotEmpty) subtitleParts.add(providerName!);
    if (timeText != null) subtitleParts.add(timeText);
    final subtitle = subtitleParts.join(' • ');

    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap, // switches to Appointments tab
        leading: const Icon(Icons.event_available),
        title: Text((serviceName ?? 'Service'),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final List<hs.ProviderItem> shops;
  const _ProviderRow({required this.shops});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = shops[i];
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
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rate_rounded, size: 16),
                          const SizedBox(width: 2),
                          Text(s.rating.toStringAsFixed(1),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
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
                      if (s.location != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          s.location!.compact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
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
      child: Text(text, style: const TextStyle(color: Colors.black54)));
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
                onPressed: () => onRetry(),
                child: Text(AppLocalizations.of(context)!.action_reload)),
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
              borderRadius: BorderRadius.circular(12)),
        );
    return ListView(children: [box(48), box(56), box(96), box(170), box(170)]);
  }
}
