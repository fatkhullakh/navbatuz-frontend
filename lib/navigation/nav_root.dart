// lib/navigation/nav_root.dart
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

// YOUR SCREENS
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

  // tab metadata (icon/title/color)
  final _tabs = <TabItem, ({IconData icon, String title, Color color})>{
    TabItem.home: (
      icon: Icons.home_rounded,
      title: 'Home',
      color: Colors.purple
    ),
    TabItem.appointments: (
      icon: Icons.event_note_rounded,
      title: 'Appointments',
      color: Colors.pink
    ),
    TabItem.search: (
      icon: Icons.search_rounded,
      title: 'Search',
      color: Colors.orange
    ),
    TabItem.account: (
      icon: Icons.person_rounded,
      title: 'Account',
      color: Colors.teal
    ),
  };

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_current]!.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false; // handled inside tab
    }
    if (_current != TabItem.home) {
      setState(() => _current = TabItem.home);
      return false; // go back to Home instead of exiting
    }
    return true; // allow system back to exit
  }

  void _onTap(int index) {
    final tapped = TabItem.values[index];
    if (tapped == _current) {
      _navKeys[tapped]!
          .currentState!
          .popUntil((r) => r.isFirst); // pop to root of current tab
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
            _buildTabNavigator(TabItem.home, const FoodAppHomeScreen()),
            _buildTabNavigator(
                TabItem.appointments, const AppointmentsScreen()),
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
