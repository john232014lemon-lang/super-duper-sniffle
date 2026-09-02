import 'package:flutter/material.dart';

class RewardBadge {
  const RewardBadge({
    required this.name,
    required this.description,
    required this.pointsRequired,
    required this.icon,
    required this.color,
  });

  final String name;
  final String description;
  final int pointsRequired;
  final IconData icon;
  final Color color;

  bool isUnlockedAt(int points) => points >= pointsRequired;
}

const rewardBadges = <RewardBadge>[
  RewardBadge(
    name: 'Harvesting Hero',
    description: 'Show up and grow your impact.',
    pointsRequired: 500,
    icon: Icons.eco,
    color: Color(0xFF22B95C),
  ),
  RewardBadge(
    name: 'Family Feeder',
    description: 'Help stock tables across the community.',
    pointsRequired: 2000,
    icon: Icons.family_restroom,
    color: Color(0xFFF3A316),
  ),
  RewardBadge(
    name: 'Material Mover',
    description: 'Reach an extraordinary service milestone.',
    pointsRequired: 10000,
    icon: Icons.local_shipping,
    color: Color(0xFF278FD0),
  ),
];
