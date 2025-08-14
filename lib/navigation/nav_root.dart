import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

// SCREENS
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

  // one Navigator per tab → preserves back stacks
  final _navKeys = <TabItem, GlobalKey<NavigatorState>>{
    TabItem.home: GlobalKey<NavigatorState>(),
    TabItem.appointments: GlobalKey<NavigatorState>(),
    TabItem.search: GlobalKey<NavigatorState>(),
    TabItem.account: GlobalKey<NavigatorState>(),
  };

  // bump this to force AppointmentsScreen to remount (triggers initState -> reload)
  int _appointmentsKeySeed = 0;

  final _tabs = <TabItem, ({IconData icon, String title, Color color})>{
    TabItem.home: (
      icon: Icons.home_rounded,
      title: 'Home',
      color: const Color(0xFF6A89A7)
    ),
    TabItem.appointments: (
      icon: Icons.event_note_rounded,
      title: 'Appointments',
      color: const Color(0xFF6A89A7)
    ),
    TabItem.search: (
      icon: Icons.search_rounded,
      title: 'Search',
      color: const Color(0xFF6A89A7)
    ),
    TabItem.account: (
      icon: Icons.person_rounded,
      title: 'Account',
      color: const Color(0xFF6A89A7)
    ),
  };

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

  void _onTap(int index) {
    final tapped = TabItem.values[index];
    if (tapped == _current) {
      _navKeys[tapped]!.currentState!.popUntil((r) => r.isFirst);
    } else {
      setState(() => _current = tapped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = TabItem.values.map((t) {
      final m = _tabs[t]!;
      return SalomonBottomBarItem(
        icon: Icon(m.icon),
        title: Text(m.title),
        selectedColor: m.color,
      );
    }).toList();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _current.index,
          children: [
            // Home → can switch tabs via callbacks
            _buildTabNavigator(
              TabItem.home,
              CustomerHomeScreen(
                onOpenSearch: () {
                  _navKeys[TabItem.search]!
                      .currentState!
                      .popUntil((r) => r.isFirst);
                  setState(() => _current = TabItem.search);
                },
                onOpenAppointments: () {
                  _navKeys[TabItem.appointments]!
                      .currentState!
                      .popUntil((r) => r.isFirst);
                  setState(() {
                    _current = TabItem.appointments;
                    _appointmentsKeySeed++; // force remount -> fetch fresh
                  });
                },
              ),
            ),
            _buildTabNavigator(
              TabItem.appointments,
              AppointmentsScreen(key: ValueKey(_appointmentsKeySeed)),
            ),
            _buildTabNavigator(TabItem.search, const SearchScreen()),
            _buildTabNavigator(TabItem.account, const AccountScreen()),
          ],
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _current.index,
          onTap: _onTap,
          items: items,
        ),
      ),
    );
  }

  Widget _buildTabNavigator(TabItem tab, Widget root) {
    return Navigator(
      key: _navKeys[tab],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => root, settings: settings),
    );
  }
}
