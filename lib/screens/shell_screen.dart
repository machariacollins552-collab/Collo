import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'coach_screen.dart';
import 'home_screen.dart';
import 'plan_tab.dart';
import 'profile_screen.dart';
import 'track_tab.dart';

/// The main app: five tabs with a bottom navigation bar.
/// Every tab stays alive, so a chat in progress or a scroll position is never lost.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return PopScope(
      // Back first returns to Home; only from Home does it leave the app.
      canPop: state.selectedTab == AppTab.home,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) state.goToTab(AppTab.home);
      },
      child: Scaffold(
        body: IndexedStack(
          index: state.selectedTab,
          children: const <Widget>[
            HomeScreen(),
            CoachScreen(),
            PlanTab(),
            TrackTab(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: state.selectedTab,
          onDestinationSelected: state.goToTab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Coach',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart),
              selectedIcon: Icon(Icons.insights),
              label: 'Track',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
