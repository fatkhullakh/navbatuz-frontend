// lib/screens/search/universal_search_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/services/service_catalog_service.dart';
import '../../services/services/provider_public_service.dart';
import '../services/service_details_screen.dart';
import '../providers/provider_screen.dart';

class UniversalSearchScreen extends StatefulWidget {
  const UniversalSearchScreen({super.key});
  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen>
    with TickerProviderStateMixin {
  final _dio = ApiService.client;
  final _svc = ServiceCatalogService();
  final _provSvc = ProviderPublicService();

  late final TabController _tabs;

  final _qCtrl = TextEditingController();
  String? _selectedCategoryId; // enum like "CLINIC"

  // categories
  bool _loadingCats = false;
  List<_CategoryItem> _cats = [];

  // services state
  bool _svcLoading = false;
  String? _svcError;
  List<ServiceSummary> _svcItems = [];
  int _svcPage = 0;
  bool _svcLast = true;

  // providers state
  bool _provLoading = false;
  String? _provError;
  List<ProviderResponse> _provItems = [];
  int _provPage = 0;
  bool _provLast = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadCategories();
    _searchAll(reset: true);
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    try {
      final r = await _dio.get('/providers'); // your categories endpoint
      final list = (r.data as List?) ?? const [];
      _cats = list
          .whereType<Map>()
          .map((m) => _CategoryItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } finally {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _searchAll({bool reset = false}) async {
    await Future.wait([
      _searchServices(reset: reset),
      _searchProviders(reset: reset),
    ]);
  }

  Future<void> _searchServices({bool reset = false}) async {
    if (reset) {
      _svcLoading = true;
      _svcError = null;
      _svcItems = [];
      _svcPage = 0;
      _svcLast = true;
      setState(() {});
    } else {
      setState(() {
        _svcLoading = true;
        _svcError = null;
      });
    }
    try {
      final res = await _svc.searchServices(
        keyword: _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim(),
        category: _selectedCategoryId,
        page: reset ? 0 : _svcPage,
        size: 30,
      );
      setState(() {
        if (reset) {
          _svcItems = res.items;
        } else {
          _svcItems = [..._svcItems, ...res.items];
        }
        _svcPage = res.page + 1;
        _svcLast = res.last;
      });
    } on DioException catch (e) {
      setState(() => _svcError = 'Failed: ${e.response?.statusCode ?? ''}');
    } catch (e) {
      setState(() => _svcError = e.toString());
    } finally {
      if (mounted) setState(() => _svcLoading = false);
    }
  }

  Future<void> _searchProviders({bool reset = false}) async {
    if (reset) {
      _provLoading = true;
      _provError = null;
      _provItems = [];
      _provPage = 0;
      _provLast = true;
      setState(() {});
    } else {
      setState(() {
        _provLoading = true;
        _provError = null;
      });
    }
    try {
      final res = await _provSvc.searchProviders(
        keyword: _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim(),
        category: _selectedCategoryId,
        page: reset ? 0 : _provPage,
        size: 30,
      );
      setState(() {
        if (reset) {
          _provItems = res.items;
        } else {
          _provItems = [..._provItems, ...res.items];
        }
        _provPage = res.page + 1;
        _provLast = res.last;
      });
    } on DioException catch (e) {
      setState(() => _provError = 'Failed: ${e.response?.statusCode ?? ''}');
    } catch (e) {
      setState(() => _provError = e.toString());
    } finally {
      if (mounted) setState(() => _provLoading = false);
    }
  }

  Future<void> _openService(ServiceSummary s) async {
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

  void _openProvider(ProviderResponse p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProviderScreen(providerId: p.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final priceFmt =
        NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.search),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: t.services),
            Tab(text: t.providers),
          ],
        ),
      ),
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
                    onSubmitted: (_) => _searchAll(reset: true),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchAll(reset: true),
                  child: Text(t.search),
                ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: (_loadingCats ? 0 : _cats.length) + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isAll = i == 0;
                final selected = isAll
                    ? _selectedCategoryId == null
                    : _selectedCategoryId == _cats[i - 1].id;
                final label = isAll ? t.all : _cats[i - 1].name;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryId = isAll ? null : _cats[i - 1].id;
                    });
                    _searchAll(reset: true);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // SERVICES
                RefreshIndicator(
                  onRefresh: () => _searchServices(reset: true),
                  child: _svcLoading && _svcItems.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _svcError != null
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [Text(_svcError!)],
                            )
                          : _svcItems.isEmpty
                              ? ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    Text(t.no_results,
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _svcItems.length +
                                      (!_svcLast ? 1 : 0), // load more cell
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    if (i == _svcItems.length && !_svcLast) {
                                      return Center(
                                        child: TextButton(
                                          onPressed: () =>
                                              _searchServices(reset: false),
                                          child: Text(t.see_all),
                                        ),
                                      );
                                    }
                                    final s = _svcItems[i];
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
                                        onTap: () => _openService(s),
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

                // PROVIDERS
                RefreshIndicator(
                  onRefresh: () => _searchProviders(reset: true),
                  child: _provLoading && _provItems.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _provError != null
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [Text(_provError!)],
                            )
                          : _provItems.isEmpty
                              ? ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    Text(t.no_results,
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount:
                                      _provItems.length + (!_provLast ? 1 : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    if (i == _provItems.length && !_provLast) {
                                      return Center(
                                        child: TextButton(
                                          onPressed: () =>
                                              _searchProviders(reset: false),
                                          child: Text(t.see_all),
                                        ),
                                      );
                                    }
                                    final p = _provItems[i];
                                    final bits = <String>[];
                                    bits.add(p.category);
                                    bits.add(p.avgRating.toStringAsFixed(1));
                                    final top = bits.join(' • ');
                                    return Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        onTap: () => _openProvider(p),
                                        leading: (p.logoUrl == null ||
                                                p.logoUrl!.isEmpty)
                                            ? const CircleAvatar(
                                                child: Icon(Icons.storefront),
                                              )
                                            : CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    ApiService.fixPublicUrl(
                                                        p.logoUrl.toString())),
                                              ),
                                        title: Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(top,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            if ((p.location?.compact ?? '')
                                                .isNotEmpty)
                                              Text(
                                                p.location!.compact,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.black54),
                                              ),
                                          ],
                                        ),
                                        trailing:
                                            const Icon(Icons.chevron_right),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _tabs.dispose();
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
