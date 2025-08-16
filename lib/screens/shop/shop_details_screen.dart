import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/provider_public_service.dart';

class ShopDetailsScreen extends StatefulWidget {
  final String providerId;
  const ShopDetailsScreen({super.key, required this.providerId});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final _svc = ProviderPublicService();

  late Future<_Bundle> _future;
  bool _favBusy = false;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_Bundle> _loadAll() async {
    final details = await _svc.getProvider(widget.providerId);
    final loc = await _svc.getLocation(widget.providerId);
    final hours = await _svc.getBusinessHours(widget.providerId);
    final services = await _svc.getServices(widget.providerId);
    final favs = await _svc.getFavouriteIds();
    _isFav = favs.contains(details.id);
    return _Bundle(details, loc, hours, services);
  }

  Future<void> _toggleFav(String providerId) async {
    setState(() => _favBusy = true);
    try {
      await _svc.setFavourite(providerId, !_isFav);
      setState(() => _isFav = !_isFav);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')));
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  String _fmtDur(Duration? d) {
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: FutureBuilder<_Bundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Failed to load: ${snap.error}'));
          }
          final b = snap.data!;
          final p = b.details;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header — name + fav + rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(p.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: _favBusy ? null : () => _toggleFav(p.id),
                    icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border),
                    color: _isFav ? Colors.red : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star_rate_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text(p.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(p.category,
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 8),
              if (b.location.compact.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(b.location.compact,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

              const SizedBox(height: 16),
              if ((p.description ?? '').isNotEmpty)
                Text(p.description!, style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 16),
              // Working hours
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Working hours',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (final h in b.hours)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 90,
                                  child: Text(_niceDay(h.day),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))),
                              Text(
                                  '${_trim(tf, h.start)} – ${_trim(tf, h.end)}'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text('Services',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (b.services.isEmpty)
                const Text('No services yet.',
                    style: TextStyle(color: Colors.black54)),
              for (final s in b.services)
                Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(s.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text([
                      if (s.category.isNotEmpty) s.category,
                      if (_fmtDur(s.duration).isNotEmpty) _fmtDur(s.duration),
                    ].join(' • ')),
                    trailing: Text('${s.price.toStringAsFixed(2)}'),
                    onTap: () {
                      // TODO: navigate to your Service Details screen:
                      // Navigator.pushNamed(context, '/service', arguments: s.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('TODO: open Service Details')),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _niceDay(String serverDay) {
    // serverDay is like "MONDAY" etc
    switch (serverDay.toUpperCase()) {
      case 'MONDAY':
        return 'Mon';
      case 'TUESDAY':
        return 'Tue';
      case 'WEDNESDAY':
        return 'Wed';
      case 'THURSDAY':
        return 'Thu';
      case 'FRIDAY':
        return 'Fri';
      case 'SATURDAY':
        return 'Sat';
      case 'SUNDAY':
        return 'Sun';
    }
    return serverDay;
  }

  String _trim(DateFormat tf, String hhmmss) {
    // hhmmss -> HH:mm
    final parts = hhmmss.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return hhmmss;
  }
}

class _Bundle {
  final ProviderPublic details;
  final LocationSummary location;
  final List<BusinessHourItem> hours;
  final List<ServiceSummary> services;
  _Bundle(this.details, this.location, this.hours, this.services);
}
