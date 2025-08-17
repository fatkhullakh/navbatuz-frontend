import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../l10n/app_localizations.dart';
import '../screens/customer/customer_home.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/account/account_screen.dart';

enum TabItem { home, appointments, search, account }

class NavRoot extends StatefulWidget {
  const NavRoot({super.key});
  @override
  State<NavRoot> createState() => _NavRootState();
}

class _NavRootState extends State<NavRoot> {
  TabItem _current = TabItem.home;

  final _navKeys = <TabItem, GlobalKey<NavigatorState>>{
    TabItem.home: GlobalKey<NavigatorState>(),
    TabItem.appointments: GlobalKey<NavigatorState>(),
    TabItem.search: GlobalKey<NavigatorState>(),
    TabItem.account: GlobalKey<NavigatorState>(),
  };

  int _appointmentsKeySeed = 0;

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_current]!.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_current != TabItem.home) {
      setState(() => _current = TabItem.home);
      return false;
    }
    return true;
  }

  void _goTab(TabItem t) {
    _navKeys[t]!.currentState!.popUntil((r) => r.isFirst);
    setState(() {
      _current = t;
      if (t == TabItem.appointments) _appointmentsKeySeed++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final items = <SalomonBottomBarItem>[
      SalomonBottomBarItem(
        icon: const Icon(Icons.home_rounded),
        title: Text(t.navHome),
        selectedColor: const Color(0xFF6A89A7),
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.event_note_rounded),
        title: Text(t.navAppointments),
        selectedColor: const Color(0xFF6A89A7),
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.search_rounded),
        title: Text(t.navSearch),
        selectedColor: const Color(0xFF6A89A7),
      ),
      SalomonBottomBarItem(
        icon: const Icon(Icons.person_rounded),
        title: Text(t.navAccount),
        selectedColor: const Color(0xFF6A89A7),
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _current.index,
          children: [
            // Home
            Navigator(
              key: _navKeys[TabItem.home],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => CustomerHomeScreen(
                  onOpenSearch: () => _goTab(TabItem.search),
                  onOpenAppointments: () => _goTab(TabItem.appointments),
                ),
                settings: settings,
              ),
            ),

            // Appointments (key bumps → initState -> reload)
            Navigator(
              key: _navKeys[TabItem.appointments],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) =>
                    AppointmentsScreen(key: ValueKey(_appointmentsKeySeed)),
                settings: settings,
              ),
            ),

            // Search
            Navigator(
              key: _navKeys[TabItem.search],
              onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (_) => const SearchScreen(), settings: settings),
            ),

            // Account
            Navigator(
              key: _navKeys[TabItem.account],
              onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (_) => const AccountScreen(), settings: settings),
            ),
          ],
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _current.index,
          onTap: (i) => _goTab(TabItem.values[i]),
          items: items,
        ),
      ),
    );
  }
}
