import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../l10n/app_localizations.dart';
import '../screens/account/account_screen.dart';
import '../screens/provider/appointments/staff_appointments_screen.dart';
import '../services/workers/worker_resolver_service.dart';

class WorkerNavRoot extends StatefulWidget {
  final String? workerId; // optional
  const WorkerNavRoot({super.key, this.workerId});

  @override
  State<WorkerNavRoot> createState() => _WorkerNavRootState();
}

enum _WTab { appointments, dashboard, hours, account }

class _Brand {
  // keep in sync with ProviderNavRoot
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
}

class _WorkerNavRootState extends State<WorkerNavRoot> {
  _WTab _current = _WTab.appointments;

  final _navKeys = <_WTab, GlobalKey<NavigatorState>>{
    _WTab.appointments: GlobalKey<NavigatorState>(),
    _WTab.dashboard: GlobalKey<NavigatorState>(),
    _WTab.hours: GlobalKey<NavigatorState>(),
    _WTab.account: GlobalKey<NavigatorState>(),
  };

  String? _workerId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _workerId = widget.workerId;
      if (_workerId == null || _workerId!.isEmpty) {
        _workerId = await WorkerResolverService().resolveMyWorkerId();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_current]!.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_current != _WTab.appointments) {
      setState(() => _current = _WTab.appointments);
      return false;
    }
    return true;
  }

  void _goTab(_WTab t) {
    _navKeys[t]!.currentState!.popUntil((r) => r.isFirst);
    setState(() => _current = t);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    if (_workerId == null || _workerId!.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('Cannot resolve worker id')));
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _current.index,
          children: [
            // Appointments (worker scope)
            Navigator(
              key: _navKeys[_WTab.appointments],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => StaffAppointmentsScreen(workerId: _workerId!),
                settings: settings,
              ),
            ),
            // Dashboard (placeholder)
            Navigator(
              key: _navKeys[_WTab.dashboard],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) =>
                    const _ComingSoon(title: 'Dashboard (coming soon)'),
                settings: settings,
              ),
            ),
            // Working Hours & Services (placeholder)
            Navigator(
              key: _navKeys[_WTab.hours],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const _ComingSoon(
                    title: 'Working Hours & Services (coming soon)'),
                settings: settings,
              ),
            ),
            // Account — shared for all roles
            Navigator(
              key: _navKeys[_WTab.account],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const AccountScreen(),
                settings: settings,
              ),
            ),
          ],
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _current.index,
          onTap: (i) => _goTab(_WTab.values[i]),
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.event_note_rounded),
              title: Text(t.navAppointments),
              selectedColor: _Brand.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.dashboard_customize_rounded),
              title: Text(t.navSearch ?? 'Dashboard'),
              selectedColor: _Brand.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.schedule_rounded),
              title: Text('Hours & Services'),
              selectedColor: _Brand.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.person_rounded),
              title: Text(t.navAccount),
              selectedColor: _Brand.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon({required this.title, super.key});
  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}
