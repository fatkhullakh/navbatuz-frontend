import 'package:flutter/material.dart';
import 'hours/worker_availability_screen.dart';
import 'services/worker_services_screen.dart';
import '../../../services/workers/worker_profile_service.dart';

class WorkerHoursServicesScreen extends StatefulWidget {
  final String workerId;
  const WorkerHoursServicesScreen({super.key, required this.workerId});

  @override
  State<WorkerHoursServicesScreen> createState() =>
      _WorkerHoursServicesScreenState();
}

class _WorkerHoursServicesScreenState extends State<WorkerHoursServicesScreen> {
  final _profile = WorkerProfileService();

  WorkerDetailsLite? _me;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // safer to use /workers/me for current actor
      final me = await _profile.getMe();
      setState(() => _me = me);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(WorkerStatus s) {
    switch (s) {
      case WorkerStatus.AVAILABLE:
        return const Color(0xFF12B76A);
      case WorkerStatus.ON_BREAK:
        return const Color(0xFFF59E0B);
      case WorkerStatus.ON_LEAVE:
        return const Color(0xFF7C3AED);
      case WorkerStatus.UNAVAILABLE:
      default:
        return const Color(0xFF667085);
    }
  }

  String _statusText(WorkerStatus s) {
    switch (s) {
      case WorkerStatus.AVAILABLE:
        return 'Available';
      case WorkerStatus.UNAVAILABLE:
        return 'Unavailable';
      case WorkerStatus.ON_BREAK:
        return 'On break';
      case WorkerStatus.ON_LEAVE:
        return 'On leave';
    }
  }

  Future<void> _changeStatus() async {
    if (_me == null) return;

    final ctx = context;
    final choice = await showModalBottomSheet<WorkerStatus>(
      context: ctx,
      showDragHandle: true,
      builder: (bctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            _StatusPickTile(
              label: 'Available',
              color: _statusColor(WorkerStatus.AVAILABLE),
              selected: _me!.status == WorkerStatus.AVAILABLE,
              onTap: () => Navigator.pop(bctx, WorkerStatus.AVAILABLE),
            ),
            _StatusPickTile(
              label: 'Unavailable',
              color: _statusColor(WorkerStatus.UNAVAILABLE),
              selected: _me!.status == WorkerStatus.UNAVAILABLE,
              onTap: () => Navigator.pop(bctx, WorkerStatus.UNAVAILABLE),
            ),
            _StatusPickTile(
              label: 'On break',
              color: _statusColor(WorkerStatus.ON_BREAK),
              selected: _me!.status == WorkerStatus.ON_BREAK,
              onTap: () => Navigator.pop(bctx, WorkerStatus.ON_BREAK),
            ),
            _StatusPickTile(
              label: 'On leave',
              color: _statusColor(WorkerStatus.ON_LEAVE),
              selected: _me!.status == WorkerStatus.ON_LEAVE,
              onTap: () => Navigator.pop(bctx, WorkerStatus.ON_LEAVE),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    // do async work OUTSIDE setState
    try {
      final updated = await _profile.updateStatus(_me!.id, choice);
      if (!mounted) return;
      setState(() => _me = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status set to ${_statusText(updated.status)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    final workerId = widget.workerId;

    return Scaffold(
      appBar: AppBar(title: const Text('Hours & Services')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 4),

          // My Availability
          _CardAction(
            icon: Icons.schedule_rounded,
            title: 'My Availability',
            subtitle: 'Weekly plan, exceptions and breaks',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => WorkerAvailabilityScreen(workerId: workerId),
              ));
            },
          ),

          // My Services
          _CardAction(
            icon: Icons.design_services_rounded,
            title: 'My Services',
            subtitle: 'Enable/disable, edit, create',
            onTap: () {
              // you already pass providerId from the nav root into WorkerServicesScreen
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => WorkerServicesScreen(
                  workerId: workerId,
                  providerId: _me!
                      .id, // NOTE: replace with actual providerId if you already have it
                ),
              ));
            },
          ),

          // My Status (new)
          if (_me != null)
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(_me!.status).withOpacity(.12),
                  child: Icon(Icons.circle, color: _statusColor(_me!.status)),
                ),
                title: Text('My Status',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_statusText(_me!.status)),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _changeStatus,
                  label: const Text('Change'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _CardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.primary.withOpacity(.10),
          child: Icon(icon, color: c.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatusPickTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusPickTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.circle, color: color),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}
