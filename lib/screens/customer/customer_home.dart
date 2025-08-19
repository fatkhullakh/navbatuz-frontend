import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/home_service.dart' as hs;
import '../providers/provider_screen.dart';
import '../../services/api_service.dart';
import '../providers/providers_list_screen.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
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
                // Search
                SliverToBoxAdapter(
                  child: _SearchBar(
                    onTap: () {
                      try {
                        Navigator.of(context, rootNavigator: true)
                            .pushNamed('/search');
                      } catch (_) {
                        widget.onOpenSearch();
                      }
                    },
                    hint: t.home_search_hint,
                  ),
                ),

                // Categories
                SliverToBoxAdapter(
                  child: _Section(
                    title: t.categories,
                    child: _CategoryChips(
                      categories: data.categories,
                      onTap: (c) {
                        final args = {
                          'initialCategory': c.id,
                          'initialQuery': ''
                        };
                        bool pushed = false;
                        try {
                          Navigator.of(context, rootNavigator: true)
                              .pushNamed('/search', arguments: args);
                          pushed = true;
                        } catch (_) {}
                        if (!pushed) widget.onOpenSearch();
                      },
                    ),
                  ),
                ),

                // Upcoming
                SliverToBoxAdapter(
                  child: _Section(
                    title: t.upcoming_appointment,
                    child: () {
                      final a = data.upcomingAppointment;
                      if (a == null) {
                        return _NoUpcoming(
                          onTap: widget.onOpenAppointments,
                          label: t.btn_go_appointments,
                        );
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
                        onTap: widget.onOpenAppointments,
                      );
                    }(),
                  ),
                ),

                // Favorites
                SliverToBoxAdapter(
                  child: _Section(
                    title: t.favorites,
                    trailing: data.favoriteShops.isNotEmpty
                        ? TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: cs.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProvidersListScreen(
                                      filter: 'favorites'),
                                ),
                              );
                            },
                            child: Text(t.see_all),
                          )
                        : null,
                    child: data.favoriteShops.isNotEmpty
                        ? _ProviderRow(
                            shops: data.favoriteShops,
                            borderColor:
                                cs.outlineVariant, // subtle, theme-aware
                          )
                        : _MutedNote(t.no_favorites),
                  ),
                ),

                // Recommended
                SliverToBoxAdapter(
                  child: _Section(
                    title: t.recommended,
                    trailing: data.recommendedShops.isNotEmpty
                        ? TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: cs.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ProvidersListScreen(filter: 'all'),
                                ),
                              );
                            },
                            child: Text(t.see_all),
                          )
                        : null,
                    child: data.recommendedShops.isNotEmpty
                        ? _ProviderRow(
                            shops: data.recommendedShops,
                            borderColor: cs.outlineVariant,
                          )
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              height: 50,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                    cs.surfaceTint.withOpacity(
                        theme.brightness == Brightness.dark ? .10 : .05),
                    cs.surface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                if (trailing != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: trailing!,
                    ),
                  ),
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

/// Categories
class _CategoryChips extends StatelessWidget {
  final List<hs.CategoryItem> categories;
  final void Function(hs.CategoryItem) onTap;
  const _CategoryChips({required this.categories, required this.onTap});

  IconData _iconFor(String id) {
    switch (id) {
      case 'BARBERSHOP':
        return Icons.content_cut;
      case 'DENTAL':
        return Icons.medical_services_outlined;
      case 'CLINIC':
        return Icons.local_hospital_outlined;
      case 'SPA':
        return Icons.spa_outlined;
      case 'GYM':
        return Icons.fitness_center_outlined;
      case 'NAIL_SALON':
        return Icons.brush_outlined;
      case 'BEAUTY_CLINIC':
        return Icons.face_retouching_natural_outlined;
      case 'TATTOO_STUDIO':
        return Icons.draw_outlined;
      case 'MASSAGE_CENTER':
        return Icons.self_improvement_outlined;
      case 'PHYSIOTHERAPY_CLINIC':
        return Icons.healing_outlined;
      case 'MAKEUP_STUDIO':
        return Icons.palette_outlined;
      default:
        return Icons.apps_outlined;
    }
  }

  String _labelFor(AppLocalizations t, String id, String fallback) {
    switch (id.toUpperCase()) {
      case 'BARBERSHOP':
        return t.cat_barbershop;
      case 'DENTAL':
        return t.cat_dental;
      case 'CLINIC':
        return t.cat_clinic;
      case 'SPA':
        return t.cat_spa;
      case 'GYM':
        return t.cat_gym;
      case 'NAIL_SALON':
        return t.cat_nail_salon;
      case 'BEAUTY_CLINIC':
        return t.cat_beauty_clinic;
      case 'TATTOO_STUDIO':
        return t.cat_tattoo_studio;
      case 'MASSAGE_CENTER':
        return t.cat_massage_center;
      case 'PHYSIOTHERAPY_CLINIC':
        return t.cat_physiotherapy_clinic;
      case 'MAKEUP_STUDIO':
        return t.cat_makeup_studio;
      default:
        return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox();
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = categories[i];
          final icon = _iconFor(c.id);
          final label = _labelFor(t, c.id, (c.name.isNotEmpty) ? c.name : c.id);

          return InkWell(
            onTap: () => onTap(c),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 96,
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                    cs.surfaceTint.withOpacity(.06), cs.surface),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant, width: 1),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary.withOpacity(.18),
                          cs.primary.withOpacity(.08),
                        ],
                      ),
                    ),
                    child: Icon(icon, size: 22, color: cs.primary),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Providers row
class _ProviderRow extends StatelessWidget {
  final List<hs.ProviderItem> shops;
  final Color? borderColor;
  const _ProviderRow({required this.shops, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: shops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = shops[i];
          final img = ApiService.normalizeMediaUrl(s.logoUrl);

          return SizedBox(
            width: 270,
            height: 210,
            child: Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: (borderColor ?? cs.outlineVariant),
                  width: (borderColor == null) ? 1 : 1,
                ),
              ),
              color:
                  Color.alphaBlend(cs.surfaceTint.withOpacity(.05), cs.surface),
              child: InkWell(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) => ProviderScreen(providerId: s.id)),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (img == null)
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: cs.surfaceVariant.withOpacity(.5),
                        child: Icon(Icons.store_mall_directory_outlined,
                            color: cs.onSurfaceVariant),
                      )
                    else
                      Stack(
                        children: [
                          Image.network(
                            img,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 140,
                              color: cs.surfaceVariant.withOpacity(.5),
                              child: Icon(Icons.broken_image_outlined,
                                  color: cs.onSurfaceVariant),
                            ),
                          ),
                          // subtle top gradient for text readability
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: true,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(.10),
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.star_rate_rounded,
                                  size: 16, color: cs.primary),
                              const SizedBox(width: 2),
                              Text(
                                s.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  s.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withOpacity(.7)),
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
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(.7)),
                            ),
                          ],
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ],
                ),
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
  final String label;
  const _NoUpcoming({required this.onTap, required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.event_note_rounded, color: cs.primary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: cs.surfaceVariant.withOpacity(.4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
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
    final cs = Theme.of(context).colorScheme;
    final timeText =
        start != null ? DateFormat('EEE, d MMM • HH:mm').format(start!) : null;
    final subtitleParts = <String>[];
    if ((providerName ?? '').isNotEmpty) subtitleParts.add(providerName!);
    if (timeText != null) subtitleParts.add(timeText);
    final subtitle = subtitleParts.join(' • ');

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      color: Color.alphaBlend(cs.surfaceTint.withOpacity(.05), cs.surface),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // left status accent
            Positioned.fill(
              left: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              leading: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withOpacity(.20),
                      cs.primary.withOpacity(.08)
                    ],
                  ),
                ),
                child: Icon(Icons.event_available, color: cs.primary),
              ),
              title: Text((serviceName ?? 'Service'),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: subtitle.isNotEmpty
                  ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutedNote extends StatelessWidget {
  final String text;
  const _MutedNote(this.text);
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(.7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: TextStyle(color: color)),
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
          children: [
            Text(text),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: Text(AppLocalizations.of(context)!.action_reload),
            ),
          ],
        ),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget box(double h) => Container(
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(.6),
            borderRadius: BorderRadius.circular(12),
          ),
        );
    return ListView(children: [box(50), box(110), box(96), box(210), box(210)]);
  }
}
