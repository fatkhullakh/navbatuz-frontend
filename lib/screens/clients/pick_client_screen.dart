import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/clients/provider_clients_service.dart';

class PickClientScreen extends StatefulWidget {
  final String providerId;
  const PickClientScreen({super.key, required this.providerId});

  @override
  State<PickClientScreen> createState() => _PickClientScreenState();
}

class _PickClientScreenState extends State<PickClientScreen> {
  final _svc = ProviderClientsService();
  final _searchCtrl = TextEditingController();
  final _debouncer = StreamController<String>.broadcast();

  List<ProviderClientHit> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _debouncer.stream.distinct().listen((q) => _run(q));
    // initial empty
    _run('');
  }

  @override
  void dispose() {
    _debouncer.close();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(String q) async {
    setState(() => _loading = true);
    try {
      _items = await _svc.search(widget.providerId, q);
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
              onChanged: (v) => _debouncer.add(v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final c = _items[i];
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(c.name?.isNotEmpty == true ? c.name! : '—'),
                        subtitle: Text(c.phoneMasked ?? ''),
                        onTap: () {
                          // return typed link id for exact booking path
                          if (c.personType == 'CUSTOMER') {
                            Navigator.pop(context, {
                              'customerId': c.linkId,
                              'guestId': null,
                              'name': c.name ?? '',
                            });
                          } else {
                            Navigator.pop(context, {
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
