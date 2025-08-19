import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/provider_public_service.dart';
import '../../services/service_catalog_service.dart';
import '../providers/provider_screen.dart';
import '../services/service_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _dio = ApiService.client;
  late final TabController _tabs = TabController(length: 2, vsync: this);

  // UI state
  final _queryCtrl = TextEditingController();
  String _query = '';
  String? _category; // e.g., 'CLINIC'

  // data
  bool _loading = false;
  String? _error;
  List<ProviderResponse> _providers = [];
  List<ServiceSummary> _services = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load(); // initial
    _queryCtrl.addListener(() {
      final next = _queryCtrl.text.trim();
      if (next == _query) return;
      _query = next;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _load);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // --- PROVIDERS ---
      List<ProviderResponse> prov;
      if ((_category ?? '').isNotEmpty) {
        final r = await _dio.get('/providers/public/search', queryParameters: {
          'category': _category,
          'page': 0,
          'size': 100,
        });
        final content = (r.data is Map && (r.data as Map)['content'] is List)
            ? ((r.data as Map)['content'] as List)
            : const [];
        prov = content
            .whereType<Map>()
            .map((m) => ProviderResponse.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      } else {
        final r = await _dio.get('/providers/public/all', queryParameters: {
          'page': 0,
          'size': 100,
          'sortBy': 'name',
        });
        final content = (r.data is Map && (r.data as Map)['content'] is List)
            ? ((r.data as Map)['content'] as List)
            : const [];
        prov = content
            .whereType<Map>()
            .map((m) => ProviderResponse.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        prov = prov
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                (p.description ?? '').toLowerCase().contains(q))
            .toList();
      }

      // --- SERVICES ---
      final svcRepo = ServiceCatalogService();
      final page = await svcRepo.searchServices(
        keyword: _query,
        category: _category,
        page: 0,
        size: 100,
      );

      List<ServiceSummary> svc = page.items;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        svc = svc.where((s) => s.name.toLowerCase().contains(q)).toList();
      }

      setState(() {
        _providers = prov;
        _services = svc;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCategory() async {
    try {
      final r = await _dio.get('/providers');
      final list = (r.data is List) ? (r.data as List) : const [];
      final items = list
          .whereType<Map>()
          .map<Map<String, String>>((m) => {
                'id': (m['id'] ?? '').toString(),
                'name': (m['name'] ?? '').toString(),
              })
          .toList();

      final chosen = await showModalBottomSheet<String?>(
        context: context,
        showDragHandle: true,
        backgroundColor: _Brand.surface2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: ListView(
              shrinkWrap: true,
              children: [
                const _SheetHeader(title: 'Categories'),
                const SizedBox(height: 8),
                _ChipGrid(
                  options: const [
                    _ChipOption(id: '', label: 'All'),
                  ],
                  extra: [
                    for (final it in items)
                      _ChipOption(
                        id: it['id']!, // keep raw id for API
                        // Localize by name (safer); fallback to raw
                        label: _localizedCategory(context, it['name']),
                      ),
                  ],
                  selectedId: _category ?? '',
                  onSelected: (id) =>
                      Navigator.pop(context, id.isEmpty ? null : id),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted) return;
      if (chosen != _category) {
        setState(() => _category = chosen);
        _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Theme(
      data: _brandTheme(context),
      child: Scaffold(
        backgroundColor: _Brand.bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _Brand.surface1,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 8, left: 18),
            child: _SearchField(
              controller: _queryCtrl,
              hint: t.home_search_hint,
              onClear: () {
                _queryCtrl.clear();
                _query = '';
                _load();
              },
            ),
          ),
          actions: [
            IconButton(
              tooltip: t.categories,
              onPressed: _pickCategory,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _SegmentedTabs(
                controller: _tabs,
                labels: [t.providers, t.services],
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: _BrandSpinner())
            : _error != null
                ? _ErrorState(
                    message: 'Failed: $_error',
                    onRetry: _load,
                    ctaLabel: t.action_retry,
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _ProvidersTab(items: _providers),
                      _ServicesTab(items: _services),
                    ],
                  ),
      ),
    );
  }
}

/* ---------------------------- Brand + Theme ---------------------------- */

class _Brand {
  static const primary = Color(0xFF6A89A7); // #6A89A7
  static const accent = Color(0xFF88BDF2); // #88BDF2
  static const accentSoft = Color(0xFFBDDDFC); // #BDDDFC
  static const ink = Color(0xFF384959); // #384959

  static const bg = Color(0xFFF6F8FC);
  static const surface1 = Colors.white;
  static const surface2 = Color(0xFFF2F6FC);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
}

ThemeData _brandTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    scaffoldBackgroundColor: _Brand.bg,
    colorScheme: ColorScheme.light(
      primary: _Brand.primary,
      secondary: _Brand.accent,
      surface: _Brand.surface1,
      onSurface: _Brand.ink,
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      foregroundColor: _Brand.ink,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: const IconThemeData(color: _Brand.ink),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      filled: true,
      fillColor: _Brand.accentSoft, // softened in widget via opacity
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    // Default card border (specific cards override color/width)

    dividerColor: _Brand.border,
    textTheme: base.textTheme.apply(
      bodyColor: _Brand.ink,
      displayColor: _Brand.ink,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _Brand.primary,
    ),
  );
}

/* ------------------------------ Helpers ------------------------------- */

String _normCat(String? s) =>
    (s ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

String _localizedCategory(BuildContext context, String? idOrName) {
  final t = AppLocalizations.of(context)!;
  final k = _normCat(idOrName);
  switch (k) {
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

Color _borderForCategory(String? idOrName) {
  final k = _normCat(idOrName);
  switch (k) {
    case 'barbershop':
      return _Brand.primary;
    case 'dental':
    case 'dentist':
      return _Brand.accent;
    case 'clinic':
    case 'beauty_clinic':
      return _Brand.primary.withOpacity(0.75);
    case 'spa':
    case 'massage_center':
      return _Brand.accent.withOpacity(0.75);
    case 'gym':
      return _Brand.ink.withOpacity(0.55);
    case 'nail_salon':
    case 'makeup_studio':
      return _Brand.accent;
    case 'tattoo_studio':
      return _Brand.ink;
    case 'physiotherapy_clinic':
      return _Brand.primary;
    default:
      return _Brand.border;
  }
}

/* ------------------------------ Widgets ------------------------------- */

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final fill = _Brand.accentSoft.withOpacity(0.35);
    return SizedBox(
      height: 44,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, v, __) {
          return TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            cursorColor: _Brand.primary,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              hintText: hint,
              fillColor: fill,
              suffixIcon: v.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  const _SegmentedTabs({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: _Brand.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Brand.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: _Brand.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _Brand.subtle,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [for (final l in labels) Tab(text: l)],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String ctaLabel;
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.ctaLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 32, color: _Brand.primary),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(ctaLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProvidersTab extends StatelessWidget {
  final List<ProviderResponse> items;
  const _ProvidersTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(title: 'No providers found');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = items[i];
        final catLabel = _localizedCategory(context, p.category);
        final subtitle = [
          if (catLabel.isNotEmpty) catLabel,
          if (p.avgRating > 0) p.avgRating.toStringAsFixed(1),
          if ((p.location?.compact ?? '').isNotEmpty) p.location!.compact,
        ].join(' • ');

        return _BigProviderCard(
          name: p.name,
          subtitle: subtitle,
          rating: p.avgRating,
          imageUrl: ApiService.normalizeMediaUrl(p.logoUrl),
          categoryId: p.category,
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => ProviderScreen(providerId: p.id)),
          ),
        );
      },
    );
  }
}

class _ServicesTab extends StatelessWidget {
  final List<ServiceSummary> items;
  const _ServicesTab({required this.items});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final priceFmt = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 0,
    );

    if (items.isEmpty) {
      return const _EmptyState(title: 'No services found');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = items[i];
        final catLabel = _localizedCategory(context, s.category);
        final dur = s.duration;
        final durText = dur == null
            ? ''
            : (dur.inHours > 0
                ? '${dur.inHours}h ${dur.inMinutes % 60}m'
                : '${dur.inMinutes % 60}m');

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: _borderForCategory(s.category),
              width: 1.25,
            ),
          ),
          child: ListTile(
            title: Text(
              s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [catLabel, if (durText.isNotEmpty) durText].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _Brand.subtle),
            ),
            trailing: _PricePill(text: priceFmt.format(s.price)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailsScreen(
                    serviceId: s.id,
                    providerId: '',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BigProviderCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final double rating;
  final String? imageUrl;
  final String? categoryId; // NEW for border tint
  final VoidCallback onTap;
  const _BigProviderCard({
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.imageUrl,
    required this.onTap,
    this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: _Brand.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderForCategory(categoryId),
            width: 1.25,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // banner image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl == null)
                      Container(
                        color: _Brand.surface2,
                        child: const Center(
                          child: Icon(Icons.storefront_rounded,
                              size: 40, color: _Brand.subtle),
                        ),
                      )
                    else
                      Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _Brand.surface2,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                size: 40, color: _Brand.subtle),
                          ),
                        ),
                      ),
                    if (rating > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: _ChipPill(
                          icon: Icons.star_rounded,
                          text: rating.toStringAsFixed(1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _Brand.subtle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------- Small UI primitives ------------------------- */

class _ChipPill extends StatelessWidget {
  final IconData? icon;
  final String text;
  const _ChipPill({this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _Brand.primary.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String text;
  const _PricePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Brand.accentSoft.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _Brand.border),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, color: _Brand.ink),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  const _EmptyState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off_rounded, size: 40, color: _Brand.subtle),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: _Brand.subtle)),
      ]),
    );
  }
}

class _BrandSpinner extends StatelessWidget {
  const _BrandSpinner();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(strokeWidth: 3),
    );
  }
}

/* ------------------------- Category Sheet Pieces ------------------------ */

class _ChipGrid extends StatelessWidget {
  final List<_ChipOption> options;
  final List<_ChipOption> extra;
  final String selectedId;
  final ValueChanged<String> onSelected;
  const _ChipGrid({
    required this.options,
    this.extra = const [],
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final all = [...options, ...extra];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in all)
          ChoiceChip(
            label: Text(o.label),
            selected: o.id == selectedId,
            shape: StadiumBorder(side: BorderSide(color: _Brand.border)),
            selectedColor: _Brand.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              color:
                  o.id == selectedId ? _Brand.ink : _Brand.ink.withOpacity(0.8),
              fontWeight:
                  o.id == selectedId ? FontWeight.w700 : FontWeight.w500,
            ),
            onSelected: (_) => onSelected(o.id),
          ),
      ],
    );
  }
}

class _ChipOption {
  final String id;
  final String label;
  const _ChipOption({required this.id, required this.label});
}

class _SheetHeader extends StatelessWidget {
  final String title;
  const _SheetHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _Brand.accentSoft.withOpacity(0.6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _Brand.border),
          ),
          child: const Text('Filter',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
