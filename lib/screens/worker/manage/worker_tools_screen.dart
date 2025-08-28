import 'package:flutter/material.dart';
import '../../provider/appointments/create_break_screen.dart';
import 'manage_working_hours_screen.dart';
import 'my_services_screen.dart';

class WorkerToolsScreen extends StatelessWidget {
  final String workerId;
  const WorkerToolsScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SizedBox(height: 8),
        _CardAction(
          icon: Icons.schedule_outlined,
          title: 'Set Working Hours',
          subtitle: 'Manage your weekly availability',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ManageWorkingHoursScreen(workerId: workerId),
            ));
          },
        ),
        _CardAction(
          icon: Icons.free_breakfast_outlined,
          title: 'Add / Manage Breaks',
          subtitle: 'Create or remove breaks for a day',
          onTap: () async {
            // Reuse your existing break screen; fixedWorkerId locks to the worker
            await Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => CreateBreakScreen(
                providerId: null, // not needed for worker self-flow
                workers: null, // not needed (fixed worker)
                fixedWorkerId: workerId,
                date: DateTime.now(),
              ),
            ));
          },
        ),
        _CardAction(
          icon: Icons.miscellaneous_services_outlined,
          title: 'My Services',
          subtitle: 'View the services you perform',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MyServicesScreen(workerId: workerId),
            ));
          },
        ),
      ],
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
