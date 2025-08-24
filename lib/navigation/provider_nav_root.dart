import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../l10n/app_localizations.dart';

// Root tabs
import '../screens/provider/appointments/staff_appointments_screen.dart';
import '../screens/provider/dashboard/provider_dashboard_screen.dart';
import '../screens/provider/manage/provider_manage_screen.dart';
import '../screens/account/account_screen.dart';

class ProviderNavRoot extends StatefulWidget {
  final String? providerId; // ← now optional
  const ProviderNavRoot({super.key, this.providerId});

  @override
  State<ProviderNavRoot> createState() => _ProviderNavRootState();
}

enum _Tab { appointments, dashboard, manage, account }

class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const ink = Color(0xFF384959);
}

class _ProviderNavRootState extends State<ProviderNavRoot> {
  _Tab _current = _Tab.appointments;

  final _navKeys = <_Tab, GlobalKey<NavigatorState>>{
    _Tab.appointments: GlobalKey<NavigatorState>(),
    _Tab.dashboard: GlobalKey<NavigatorState>(),
    _Tab.manage: GlobalKey<NavigatorState>(),
    _Tab.account: GlobalKey<NavigatorState>(),
  };

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_current]!.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_current != _Tab.appointments) {
      setState(() => _current = _Tab.appointments);
      return false;
    }
    return true;
  }

  void _goTab(_Tab t) {
    _navKeys[t]!.currentState!.popUntil((r) => r.isFirst);
    setState(() => _current = t);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _current.index,
          children: [
            // Appointments
            Navigator(
              key: _navKeys[_Tab.appointments],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) =>
                    StaffAppointmentsScreen(providerId: widget.providerId),
                settings: settings,
              ),
            ),
            // Dashboard
            Navigator(
              key: _navKeys[_Tab.dashboard],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const ProviderDashboardScreen(),
                settings: settings,
              ),
            ),
            // Manage (this area needs providerId; we pass whatever we have)
            Navigator(
              key: _navKeys[_Tab.manage],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => ProviderManageScreen(
                  providerId: widget.providerId, // may be null → screen guards
                ),
                settings: settings,
              ),
            ),
            // Account (shared)
            Navigator(
              key: _navKeys[_Tab.account],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const AccountScreen(),
                settings: settings,
              ),
            ),
          ],
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _current.index,
          onTap: (i) => _goTab(_Tab.values[i]),
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
              icon: const Icon(Icons.build_rounded),
              title: Text(t.provider_tab_details ?? 'Manage'),
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
