import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/clients/provider_clients_service.dart';

class PickClientScreen extends StatefulWidget {
  final String providerId; // keep existing API — we’ll auto-fix if it’s wrong
  const PickClientScreen({super.key, required this.providerId});

  @override
  State<PickClientScreen> createState() => _PickClientScreenState();
}

class _PickClientScreenState extends State<PickClientScreen> {
  final _svc = ProviderClientsService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<ProviderClientHit> _items = const [];
  bool _loading = false;
  String? _error; // human-friendly error

  @override
  void initState() {
    super.initState();
    _run('');
    _searchCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _run(_searchCtrl.text.trim());
    });
  }

  Future<void> _run(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _svc.search(providerId: widget.providerId, q: q);
    } on StateError catch (e) {
      if (e.message == 'not_staff') {
        _items = const [];
        _error = 'You are not linked to this provider as staff.';
      } else {
        _error = e.toString();
        _items = const [];
      }
    } catch (e) {
      _error = e.toString();
      _items = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick client')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by phone or name',
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = _items[i];
                  final title = (c.name?.isNotEmpty == true) ? c.name! : '—';
                  final subtitle = c.phoneMasked ?? '';
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: subtitle.isEmpty ? null : Text(subtitle),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black12,
                      ),
                      child: Text(
                        c.personType, // "CUSTOMER" / "GUEST"
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    onTap: () {
                      if (c.personType == 'CUSTOMER') {
                        Navigator.pop<Map<String, String?>>(context, {
                          'customerId': c.linkId,
                          'guestId': null,
                          'name': c.name ?? '',
                        });
                      } else {
                        Navigator.pop<Map<String, String?>>(context, {
                          'customerId': null,
                          'guestId': c.linkId,
                          'name': c.name ?? '',
                        });
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
