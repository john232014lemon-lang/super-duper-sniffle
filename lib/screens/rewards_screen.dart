import 'package:flutter/material.dart';

import '../data/shift_store.dart';
import '../models/reward_badge.dart';
import '../widgets/bushel_navigation_bar.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _store = ShiftStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final points = _store.points;
    final earned = rewardBadges.where((b) => b.isUnlockedAt(points)).length;
    RewardBadge? nextBadge;
    for (final badge in rewardBadges) {
      if (!badge.isUnlockedAt(points)) {
        nextBadge = badge;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _PointsHero(points: points, earned: earned, nextBadge: nextBadge),
              const SizedBox(height: 28),
              const Text(
                'Your badges',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Every completed check-in adds 100 points.',
                style: TextStyle(color: Color(0xFF718078)),
              ),
              const SizedBox(height: 14),
              for (final badge in rewardBadges)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BadgeCard(badge: badge, points: points),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 4),
    );
  }
}

class _PointsHero extends StatelessWidget {
  const _PointsHero({
    required this.points,
    required this.earned,
    required this.nextBadge,
  });

  final int points;
  final int earned;
  final RewardBadge? nextBadge;

  @override
  Widget build(BuildContext context) {
    final target =
        nextBadge?.pointsRequired ?? rewardBadges.last.pointsRequired;
    final progress = (points / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C4127), Color(0xFF22B95C)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFFFD75E)),
              SizedBox(width: 8),
              Text(
                'YOUR IMPACT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$points points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$earned of ${rewardBadges.length} badges earned',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD75E)),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            nextBadge == null
                ? 'Every badge unlocked — incredible work!'
                : '${nextBadge!.pointsRequired - points} points to ${nextBadge!.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.points});

  final RewardBadge badge;
  final int points;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlockedAt(points);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: unlocked ? badge.color : const Color(0xFFE9EEEA),
              child: Icon(
                unlocked ? badge.icon : Icons.lock_outline,
                color: unlocked ? Colors.white : const Color(0xFF8A978F),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          badge.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        unlocked ? 'EARNED' : '${badge.pointsRequired} pts',
                        style: TextStyle(
                          color: unlocked
                              ? const Color(0xFF168845)
                              : const Color(0xFF718078),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (points / badge.pointsRequired).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE7ECE8),
                    valueColor: AlwaysStoppedAnimation(badge.color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
