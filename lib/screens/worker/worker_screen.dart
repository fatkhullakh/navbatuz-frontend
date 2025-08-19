// lib/screens/worker/worker_screen.dart
import 'package:flutter/material.dart';
import '../../services/worker_public_service.dart';
import '../../services/service_catalog_service.dart';
import '../../services/api_service.dart';
import '../providers/provider_screen.dart';
import '../booking/service_booking_screen.dart';

class WorkerScreen extends StatefulWidget {
  final String workerId;
  final String providerId;
  const WorkerScreen(
      {super.key, required this.workerId, required this.providerId});

  @override
  State<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  final _svc = WorkerPublicService();
  WorkerDetails? _d;
  String? _err;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final d = await _svc.getDetails(
        workerId: widget.workerId,
        providerId: widget.providerId,
      );
      setState(() => _d = d);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(
                  child: Text(_err!, style: const TextStyle(color: Colors.red)))
              : _d == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundImage: (_d!.avatarUrl != null)
                                    ? NetworkImage(_d!.avatarUrl!)
                                    : null,
                                child: (_d!.avatarUrl == null)
                                    ? const Icon(Icons.person, size: 36)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_d!.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(
                                          builder: (_) => ProviderScreen(
                                              providerId: _d!.providerId),
                                        ));
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.storefront,
                                              size: 18),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _d!.providerName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  decoration:
                                                      TextDecoration.underline),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if ((_d!.phone ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        const Icon(Icons.phone, size: 18),
                                        const SizedBox(width: 6),
                                        Text(_d!.phone!)
                                      ]),
                                    ],
                                    if ((_d!.email ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        const Icon(Icons.email_outlined,
                                            size: 18),
                                        const SizedBox(width: 6),
                                        Text(_d!.email!)
                                      ]),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Services',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          if (_d!.services.isEmpty)
                            const Text('No services yet',
                                style: TextStyle(color: Colors.black54))
                          else
                            ..._d!.services.map((s) => _ServiceRow(
                                  s: s,
                                  providerId: _d!.providerId,
                                  workerId: _d!.id,
                                )),
                        ],
                      ),
                    ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final ServiceSummary s;
  final String providerId;
  final String workerId;
  const _ServiceRow(
      {required this.s, required this.providerId, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [if (s.duration != null) '${s.duration!.inMinutes}m', s.category]
              .where((e) => e.isNotEmpty)
              .join(' • '),
        ),
        trailing: TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ServiceBookingScreen(
                serviceId: s.id,
                providerId: providerId,
                preferredWorkerId: workerId, // preselect worker
              ),
            ));
          },
          child: const Text('Book'),
        ),
      ),
    );
  }
}
