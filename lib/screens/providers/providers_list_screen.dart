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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.filter == 'favorites') {
        final r = await _dio.get('/customers/favourites');

        // Case A: backend returns full ProviderResponse objects
        if (r.data is List &&
            (r.data as List).isNotEmpty &&
            (r.data as List).first is Map) {
          final list = (r.data as List).cast<Map>();
          _items = list
              .map((m) =>
                  _ProviderSummary.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        } else {
          // Case B: backend returns list of IDs → fetch details per ID
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
        // 'all' = use public/all page (your endpoint)
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
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final p = _items[i];

                          // Top line: category • rating
                          final bits = <String>[];
                          if ((p.category ?? '').isNotEmpty)
                            bits.add(p.category!);
                          if (p.rating != null)
                            bits.add(p.rating!.toStringAsFixed(1));
                          final top = bits.join(' • ');

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () {
                                // Open provider details screen
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProviderScreen(providerId: p.id),
                                  ),
                                );
                              },
                              title: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (top.isNotEmpty)
                                    Text(top,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  if ((p.locationCompact ?? '').isNotEmpty)
                                    Text(
                                      p.locationCompact!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.black54),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
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
  final double? rating; // from avgRating
  final String? category; // “CLINIC”, etc.
  final String? locationCompact;

  _ProviderSummary({
    required this.id,
    required this.name,
    this.description,
    this.rating,
    this.category,
    this.locationCompact,
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
    );
  }
}
