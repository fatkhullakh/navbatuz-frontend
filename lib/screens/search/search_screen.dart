import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/provider_public_service.dart';
import '../../services/service_catalog_service.dart';
import '../providers/provider_screen.dart';
import '../services/service_details_screen.dart'; // if you have one; else open booking
import '../providers/providers_list_screen.dart'; // reuses card styles if you want

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
      // If category chosen → use server endpoint; else load all.
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
      // Text filter (client-side fallback until backend supports keyword)
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
        keyword: _query, // was "query"
        category: _category,
        page: 0,
        size: 100,
      );

      // take items from the page object
      List<ServiceSummary> svc = page.items;

      // optional client-side keyword filter (in case backend ignores `q`)
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
    // Load categories from /providers (you already use this in Home)
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
        builder: (_) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All categories'),
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(height: 0),
              for (final it in items)
                ListTile(
                  title: Text(it['name']!),
                  onTap: () => Navigator.pop(context, it['id']),
                )
            ],
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 5, left: 18),
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
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: t.providers),
            Tab(text: t.services),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed: $_error'),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _load,
                        child: Text(t.action_retry),
                      )
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _ProvidersTab(items: _providers),
                    _ServicesTab(items: _services),
                  ],
                ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;
  const _SearchField(
      {required this.controller, required this.hint, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 6),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: const Color(0xFFF5F6F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
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
      return const Center(child: Text('No providers found'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = items[i];
        return _BigProviderCard(
          name: p.name,
          subtitle: [
            if ((p.category).isNotEmpty) p.category,
            if (p.avgRating > 0) p.avgRating.toStringAsFixed(1),
            if ((p.location?.compact ?? '').isNotEmpty) p.location!.compact,
          ].join(' • '),
          imageUrl: ApiService.normalizeMediaUrl(p.logoUrl),
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
      return const Center(child: Text('No services found'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = items[i];
        final dur = s.duration;
        final durText = dur == null
            ? ''
            : (dur.inHours > 0
                ? '${dur.inHours}h ${dur.inMinutes % 60}m'
                : '${dur.inMinutes % 60}m');
        return Card(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          child: ListTile(
            title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle:
                Text([s.category, if (durText.isNotEmpty) durText].join(' • ')),
            trailing: Text(priceFmt.format(s.price),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailsScreen(
                    serviceId: s.id,
                    providerId: '', // optional if your details screen needs it
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
  final String? imageUrl;
  final VoidCallback onTap;
  const _BigProviderCard({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // banner image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: (imageUrl == null)
                  ? Container(
                      color: const Color(0xFFF2F4F7),
                      child: const Center(
                          child: Icon(Icons.storefront_rounded, size: 40)),
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF2F4F7),
                        child: const Center(
                            child: Icon(Icons.broken_image_outlined, size: 40)),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
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
