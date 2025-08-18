// lib/screens/search/service_search_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/service_catalog_service.dart';
import '../services/service_details_screen.dart';

class ServiceSearchScreen extends StatefulWidget {
  const ServiceSearchScreen({super.key});
  @override
  State<ServiceSearchScreen> createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends State<ServiceSearchScreen> {
  final _dio = ApiService.client;
  final _svc = ServiceCatalogService();

  final _qCtrl = TextEditingController();
  String? _selectedCategoryId; // enum name like "CLINIC"
  bool _loadingCats = false;
  List<_CategoryItem> _cats = [];

  bool _loading = false;
  String? _error;
  List<ServiceSummary> _items = [];
  int _page = 0;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _runSearch(reset: true);
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    try {
      final r = await _dio.get('/providers'); // you already use this for cats
      final list = (r.data as List?) ?? const [];
      _cats = list
          .whereType<Map>()
          .map((m) => _CategoryItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      // ignore; chips will just show "All"
    } finally {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _runSearch({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items = [];
        _page = 0;
        _last = true;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final res = await _svc.searchServices(
        keyword: _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim(),
        category: _selectedCategoryId,
        page: reset ? 0 : _page,
        size: 30,
      );
      setState(() {
        if (reset) {
          _items = res.items;
        } else {
          _items = [..._items, ...res.items];
        }
        _page = res.page + 1;
        _last = res.last;
      });
    } on DioException catch (e) {
      setState(() => _error = 'Failed: ${e.response?.statusCode ?? ''}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(ServiceSummary s) async {
    // We only know serviceId from search → fetch providerId, then open details.
    final providerId = await _svc.getProviderIdForService(s.id);
    if (!mounted) return;
    if (providerId == null || providerId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Provider missing')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailsScreen(
          serviceId: s.id,
          providerId: providerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final priceFmt =
        NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text(t.action_retry)),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qCtrl,
                    decoration: InputDecoration(
                      hintText: t.home_search_hint,
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (_) => _runSearch(reset: true),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _runSearch(reset: true),
                  child: Text(t.action_retry),
                ),
              ],
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: (_loadingCats ? 0 : _cats.length) + 1, // All + cats
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isAll = i == 0;
                final selected = isAll
                    ? _selectedCategoryId == null
                    : _selectedCategoryId == _cats[i - 1].id;
                final label = isAll ? t.action_retry : _cats[i - 1].name;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryId = isAll ? null : _cats[i - 1].id;
                    });
                    _runSearch(reset: true);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _runSearch(reset: true),
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [Text(_error!)],
                        )
                      : _items.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Text(t.no_results,
                                    style:
                                        const TextStyle(color: Colors.black54)),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final s = _items[i];
                                final dur = s.duration?.inMinutes;
                                final subtitle = [
                                  s.category,
                                  if (dur != null && dur > 0) '${dur}m',
                                ].join(' • ');
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    onTap: () => _open(s),
                                    title: Text(
                                      s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(subtitle),
                                    trailing: Text(
                                      priceFmt.format(s.price),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }
}

class _CategoryItem {
  final String id; // enum id: "CLINIC"
  final String name; // display name
  _CategoryItem({required this.id, required this.name});

  factory _CategoryItem.fromJson(Map<String, dynamic> j) => _CategoryItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
      );
}
