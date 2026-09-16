import 'package:flutter/material.dart';

import '../data/session_store.dart';
import '../screens/food_bank_map_screen.dart';
import '../screens/family_center_screen.dart';
import '../screens/check_in_screen.dart';
import '../screens/coordinator_screen.dart';
import '../screens/home_screen.dart';
import '../screens/kid_badges_screen.dart';
import '../screens/rewards_screen.dart';
import '../screens/shifts_screen.dart';

class BushelNavigationBar extends StatelessWidget {
  const BushelNavigationBar({
    super.key,
    required this.selectedIndex,
    this.onHome,
  });

  final int selectedIndex;
  final VoidCallback? onHome;

  void _select(BuildContext context, int index) {
    if (index == selectedIndex) return;
    if (index == 0) {
      if (onHome != null) {
        onHome!();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => HomeScreen(name: SessionStore.instance.userName),
          ),
          (route) => false,
        );
      }
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const FoodBankMapScreen()),
      );
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const CheckInScreen()),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ShiftsScreen()),
      );
      return;
    }
    if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => switch (SessionStore.instance.role) {
            BushelRole.kid => const KidBadgesScreen(),
            BushelRole.coordinator => const CoordinatorScreen(),
            BushelRole.volunteer => const RewardsScreen(),
          },
        ),
      );
    }
    if (index == 5) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const FamilyCenterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (SessionStore.instance.role == BushelRole.kid) {
      final kidIndex = switch (selectedIndex) {
        2 => 1,
        3 => 2,
        4 => 3,
        5 => 4,
        _ => 0,
      };
      final destinations = <NavigationDestination>[
        const NavigationDestination(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Check in',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Shifts',
        ),
        const NavigationDestination(
          icon: Icon(Icons.workspace_premium),
          label: 'Badges',
        ),
        if (SessionStore.instance.familyAccount)
          const NavigationDestination(
            icon: Icon(Icons.family_restroom),
            label: 'Family',
          ),
      ];
      final canonical = SessionStore.instance.familyAccount
          ? [0, 2, 3, 4, 5]
          : [0, 2, 3, 4];
      return NavigationBar(
        selectedIndex: kidIndex,
        onDestinationSelected: (index) => _select(context, canonical[index]),
        destinations: destinations,
      );
    }
    final coordinator = SessionStore.instance.role == BushelRole.coordinator;
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.map_outlined),
        label: 'Banks',
      ),
      const NavigationDestination(
        icon: Icon(Icons.qr_code_scanner),
        label: 'Scan',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        label: 'Shifts',
      ),
      NavigationDestination(
        icon: Icon(
          coordinator ? Icons.groups_outlined : Icons.emoji_events_outlined,
        ),
        label: coordinator ? 'Groups' : 'Rewards',
      ),
      if (SessionStore.instance.familyAccount)
        const NavigationDestination(
          icon: Icon(Icons.family_restroom),
          label: 'Family',
        ),
    ];
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _select(context, index),
      destinations: destinations,
    );
  }
}
