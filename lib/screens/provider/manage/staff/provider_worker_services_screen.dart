import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';

class ProviderWorkerServicesScreen extends StatefulWidget {
  final String providerId;
  final String workerId;
  final String workerName;
  const ProviderWorkerServicesScreen({
    super.key,
    required this.providerId,
    required this.workerId,
    required this.workerName,
  });

  @override
  State<ProviderWorkerServicesScreen> createState() =>
      _ProviderWorkerServicesScreenState();
}

class _ProviderWorkerServicesScreenState
    extends State<ProviderWorkerServicesScreen> {
  final _dio = ApiService.client;
  bool _loading = true;
  bool _saving = false;

  List<_Svc> _all = [];
  late Set<String> _assigned; // serviceIds assigned to worker

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final rAll =
          await _dio.get('/services/provider/all/${widget.providerId}');
      final listAll = (rAll.data as List?) ?? [];

      final rMine = await _dio.get('/services/worker/all/${widget.workerId}');
      final listMine = (rMine.data as List?) ?? [];

      _all = listAll.whereType<Map>().map((m) {
        final mm = m.cast<String, dynamic>();
        return _Svc(
          id: (mm['id'] ?? '').toString(),
          name: (mm['name'] ?? '').toString(),
          isActive: mm['isActive'] == true,
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _assigned = listMine
          .whereType<Map>()
          .map((m) => (m['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String serviceId, bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (value) {
        await _dio.put('/services/$serviceId/add-worker/${widget.workerId}');
        _assigned.add(serviceId);
      } else {
        await _dio.put('/services/$serviceId/remove-worker/${widget.workerId}');
        _assigned.remove(serviceId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Added' : 'Removed')),
      );
      setState(() {});
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed ($code): $body')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${t.services_title ?? 'Services'} – ${widget.workerName}'),
        actions: [
          IconButton(
            tooltip: t.action_refresh ?? 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = _all[i];
                final checked = _assigned.contains(s.id);
                return Card(
                  elevation: 0,
                  child: CheckboxListTile(
                    value: checked,
                    onChanged: (v) => _toggle(s.id, v ?? false),
                    title: Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: s.isActive ? null : Colors.black54,
                      ),
                    ),
                    subtitle:
                        s.isActive ? null : const Text('Service inactive'),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                );
              },
            ),
    );
  }
}

class _Svc {
  final String id;
  final String name;
  final bool isActive;
  _Svc({required this.id, required this.name, required this.isActive});
}
