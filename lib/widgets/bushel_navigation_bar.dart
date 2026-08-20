import 'package:flutter/material.dart';

import '../screens/food_bank_map_screen.dart';
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
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const FoodBankMapScreen()),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ShiftsScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            index == 2
                ? 'QR check-in is coming soon.'
                : 'Community is coming soon.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
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
          icon: Icon(Icons.favorite_outline),
          label: 'Community',
        ),
      ],
    );
  }
}
