import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../providers/provider_screen.dart';

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

Color _borderForCategory(String? idOrName) {
  switch (_normCat(idOrName)) {
    case 'barbershop':
      return _Brand.primary;
    case 'dental':
    case 'dentist':
      return _Brand.accent;
    case 'clinic':
    case 'beauty_clinic':
      return _Brand.primary.withOpacity(.75);
    case 'spa':
    case 'massage_center':
      return _Brand.accent.withOpacity(.75);
    case 'gym':
      return _Brand.ink.withOpacity(.55);
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

/* ---------------------------- Screen widget ----------------------------- */
class ProvidersListScreen extends StatefulWidget {
  /// 'favorites' => list user’s favorite providers
  /// 'all'       => list all providers (placeholder for recommendations)
  final String? filter;
  final String? categoryId; // (future)
  const ProvidersListScreen({super.key, this.filter, this.categoryId});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen> {
  final _dio = ApiService.client;
  bool _loading = false;
  String? _error;
  List<_ProviderSummary> _items = [];
  Set<String> _favIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Set<String>> _fetchFavoriteIds() async {
    try {
      final r = await _dio.get('/customers/favourites');
      final data = r.data;
      if (data is List) {
        if (data.isNotEmpty && data.first is Map) {
          return data
              .cast<Map>()
              .map((m) => (m['id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet();
        } else {
          return data.map((e) => e.toString()).toSet();
        }
      }
    } catch (_) {}
    return <String>{};
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // always know current favorites
      _favIds = await _fetchFavoriteIds();

      if (widget.filter == 'favorites') {
        final r = await _dio.get('/customers/favourites');

        if (r.data is List &&
            (r.data as List).isNotEmpty &&
            (r.data as List).first is Map) {
          final list = (r.data as List).cast<Map>();
          _items = list
              .map((m) =>
                  _ProviderSummary.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        } else {
          final ids = (r.data as List).map((e) => e.toString()).toList();
          final futures = ids.map((id) async {
            final d = await _dio.get('/providers/public/$id/details');
            return _ProviderSummary.fromJson(
                Map<String, dynamic>.from(d.data as Map));
          });
          _items = await Future.wait(futures);
        }

        _items.sort((a, b) => a.name.compareTo(b.name));
      } else {
        // 'all'
        final r = await _dio.get(
          '/providers/public/all',
          queryParameters: {'page': 0, 'size': 100, 'sortBy': 'name'},
        );
        final content = (r.data is Map && (r.data as Map)['content'] is List)
            ? ((r.data as Map)['content'] as List)
            : const <dynamic>[];

        _items = content
            .whereType<Map>()
            .map((m) => _ProviderSummary.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }

      setState(() {});
    } on DioException catch (e) {
      setState(() => _error = 'Failed: ${e.response?.statusCode ?? ''}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(_ProviderSummary p) async {
    final isFav = _favIds.contains(p.id);
    try {
      if (isFav) {
        await _dio.delete('/customers/favourites/${p.id}');
      } else {
        await _dio.post('/customers/favourites/${p.id}');
      }
      setState(() {
        if (isFav) {
          _favIds.remove(p.id);
          if (widget.filter == 'favorites') {
            _items.removeWhere((e) => e.id == p.id); // instantly disappear
          }
        } else {
          _favIds.add(p.id);
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed (${e.response?.statusCode ?? 'net'})')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = (widget.filter == 'favorites') ? t.favorites : t.providers;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        color: _Brand.primary,
        onRefresh: _load,
        child: _loading
            ? const _Skeleton()
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red))
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            (widget.filter == 'favorites')
                                ? t.no_favorites
                                : t.no_results,
                            style: const TextStyle(color: _Brand.subtle),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final p = _items[i];
                          final isFav = _favIds.contains(p.id);
                          return _ProviderCard(
                            item: p,
                            isFavorite: isFav,
                            onFavoriteToggle: () => _toggleFavorite(p),
                            onOpen: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProviderScreen(providerId: p.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

/* ------------------------------ Card UI -------------------------------- */
class _ProviderCard extends StatelessWidget {
  final _ProviderSummary item;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onOpen;

  const _ProviderCard({
    required this.item,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final catLabel = _localizedCategory(context, item.category);
    final subtitleBits = <String>[
      if (catLabel.isNotEmpty) catLabel,
      if (item.rating != null) item.rating!.toStringAsFixed(1),
      if ((item.locationCompact ?? '').isNotEmpty) item.locationCompact!,
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpen,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderForCategory(item.category),
            width: 1.25,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // banner
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: (item.logoUrl == null)
                        ? Container(
                            color: _Brand.accentSoft.withOpacity(.5),
                            child: const Center(
                              child: Icon(Icons.storefront_rounded,
                                  size: 40, color: _Brand.subtle),
                            ),
                          )
                        : Image.network(
                            item.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _Brand.accentSoft.withOpacity(.5),
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    size: 40, color: _Brand.subtle),
                              ),
                            ),
                          ),
                  ),

                  // gradient for readability
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
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // rating pill
                  if ((item.rating ?? 0) > 0)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _ChipPill(
                        icon: Icons.star_rounded,
                        text: item.rating!.toStringAsFixed(1),
                      ),
                    ),

                  // favorite
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.white.withOpacity(0.95),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        tooltip: isFavorite
                            ? AppLocalizations.of(context)!
                                .remove_from_favorites
                            : AppLocalizations.of(context)!
                                .favorites_added_snack,
                        icon: Icon(isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border),
                        color: isFavorite
                            ? Colors.redAccent
                            : _Brand.ink.withOpacity(.75),
                        onPressed: onFavoriteToggle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // text
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _Brand.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleBits.join(' • '),
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

/* ------------------------------ Skeleton -------------------------------- */
class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    Widget box({double h = 170, double r = 16}) => Container(
          height: h,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          decoration: BoxDecoration(
            color: _Brand.accentSoft.withOpacity(.45),
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return ListView(children: [
      box(h: 190),
      box(h: 190),
      box(h: 190),
    ]);
  }
}

/* ----------------------------- Data model ------------------------------- */
class _ProviderSummary {
  final String id;
  final String name;
  final String? description;
  final double? rating; // avgRating
  final String? category;
  final String? locationCompact;
  final String? logoUrl;

  _ProviderSummary({
    required this.id,
    required this.name,
    this.description,
    this.rating,
    this.category,
    this.locationCompact,
    this.logoUrl,
  });

  factory _ProviderSummary.fromJson(Map<String, dynamic> j) {
    String? compactLocation() {
      final loc = j['location'];
      if (loc is! Map) return null;
      final m = Map<String, dynamic>.from(loc);
      final parts = <String>[];
      void add(String? s) {
        if (s != null && s.trim().isNotEmpty) parts.add(s.trim());
      }

      add(m['addressLine1']?.toString());
      add(m['city']?.toString());
      add(m['countryIso2']?.toString());
      return parts.isEmpty ? null : parts.join(', ');
    }

    return _ProviderSummary(
      id: j['id'].toString(),
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      rating:
          (j['avgRating'] is num) ? (j['avgRating'] as num).toDouble() : null,
      category: j['category']?.toString(),
      locationCompact: compactLocation(),
      logoUrl: ApiService.normalizeMediaUrl(j['logoUrl']?.toString()),
    );
  }
}

/* ----------------------------- Tiny UI bits ----------------------------- */
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
        border: Border.all(color: Colors.white.withOpacity(.4)),
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
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
