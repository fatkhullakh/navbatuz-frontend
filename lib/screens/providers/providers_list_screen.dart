import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import '../providers/provider_screen.dart';

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
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
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
                            style: const TextStyle(color: Colors.black54),
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
                          final subtitleBits = <String>[];
                          if ((p.category ?? '').isNotEmpty) {
                            subtitleBits.add(p.category!);
                          }
                          if (p.rating != null) {
                            subtitleBits.add(p.rating!.toStringAsFixed(1));
                          }
                          if ((p.locationCompact ?? '').isNotEmpty) {
                            subtitleBits.add(p.locationCompact!);
                          }

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProviderScreen(providerId: p.id),
                                ),
                              );
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFE6E8EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: (p.logoUrl == null)
                                            ? Container(
                                                color: const Color(0xFFF2F4F7),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.storefront_rounded,
                                                    size: 40,
                                                  ),
                                                ),
                                              )
                                            : Image.network(
                                                p.logoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  color:
                                                      const Color(0xFFF2F4F7),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      size: 40,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.white.withOpacity(0.92),
                                          shape: const CircleBorder(),
                                          clipBehavior: Clip.antiAlias,
                                          child: IconButton(
                                            tooltip: isFav
                                                ? t.remove_from_favorites
                                                : t.favorites_added_snack,
                                            icon: Icon(isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border),
                                            color: isFav
                                                ? Colors.redAccent
                                                : Colors.black54,
                                            onPressed: () => _toggleFavorite(p),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitleBits.join(' • '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

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
