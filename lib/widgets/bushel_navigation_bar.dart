import 'package:flutter/material.dart';

import '../data/session_store.dart';
import '../screens/food_bank_map_screen.dart';
import '../screens/check_in_screen.dart';
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
          builder: (_) => SessionStore.instance.role == BushelRole.kid
              ? const KidBadgesScreen()
              : const RewardsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (SessionStore.instance.role == BushelRole.kid) {
      final kidIndex = switch (selectedIndex) {
        2 => 1,
        4 => 2,
        _ => 0,
      };
      return NavigationBar(
        selectedIndex: kidIndex,
        onDestinationSelected: (index) => _select(context, [0, 2, 4][index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Check in',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium),
            label: 'Badges',
          ),
        ],
      );
    }
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _select(context, index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Banks'),
        NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Shifts',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          label: 'Rewards',
        ),
      ],
    );
  }
}
