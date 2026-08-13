import 'package:flutter/material.dart';

import '../data/mock_food_banks.dart';
import '../models/food_bank.dart';

class FoodBankDetailScreen extends StatelessWidget {
  const FoodBankDetailScreen({super.key, required this.foodBank});

  final FoodBank foodBank;

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shift signup is coming in Slice 3.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = mockFoodBanks
        .where((bank) => bank.name != foodBank.name)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Food bank details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _BankHero(foodBank: foodBank),
              const SizedBox(height: 24),
              const Text(
                'About this food bank',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                foodBank.description,
                style: const TextStyle(
                  color: Color(0xFF5F6D65),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: foodBank.address,
              ),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.schedule, text: foodBank.hours),
              const SizedBox(height: 28),
              const Text(
                'Upcoming shifts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ...foodBank.shifts.map(
                (shift) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ShiftCard(
                    shift: shift,
                    onTap: () => _showComingSoon(context),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Recommended food banks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ...recommendations.map(
                (bank) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecommendationCard(
                    foodBank: bank,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => FoodBankDetailScreen(foodBank: bank),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankHero extends StatelessWidget {
  const _BankHero({required this.foodBank});

  final FoodBank foodBank;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [foodBank.accent, const Color(0xFF123C2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(foodBank.icon, color: Colors.white, size: 48),
              const Spacer(),
              Chip(
                avatar: const Icon(Icons.near_me, size: 16),
                label: Text(foodBank.distance),
              ),
            ],
          ),
          const Spacer(),
          Text(
            foodBank.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Open now · Volunteers welcome',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF22B95C), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift, required this.onTap});

  final FoodBankShift shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7EA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.calendar_month, color: Color(0xFF169B4B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text('${shift.date} · ${shift.time}'),
                  Text(
                    '${shift.station} · ${shift.spotsLeft} spots left',
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: const Text('View')),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.foodBank, required this.onTap});

  final FoodBank foodBank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: foodBank.accent.withValues(alpha: 0.15),
          child: Icon(foodBank.icon, color: foodBank.accent),
        ),
        title: Text(
          foodBank.shortName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${foodBank.distance} · ${foodBank.shifts.length} upcoming shifts',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
