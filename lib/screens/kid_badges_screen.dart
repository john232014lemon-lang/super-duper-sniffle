import 'package:flutter/material.dart';

import '../data/session_store.dart';
import '../models/kid_badge.dart';
import '../widgets/bushel_navigation_bar.dart';

class KidBadgesScreen extends StatefulWidget {
  const KidBadgesScreen({super.key});

  @override
  State<KidBadgesScreen> createState() => _KidBadgesScreenState();
}

class _KidBadgesScreenState extends State<KidBadgesScreen> {
  final _session = SessionStore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My badge garden')),
      body: GridView.builder(
        padding: const EdgeInsets.all(18),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: kidBadges.length,
        itemBuilder: (context, index) {
          final badge = kidBadges[index];
          final unlocked = _session.unlockedKidBadges.contains(badge.id);
          final featured = _session.featuredKidBadge == badge.id;
          return Card(
            color: featured ? const Color(0xFFE1F8E8) : null,
            child: InkWell(
              onTap: unlocked
                  ? () => setState(() => _session.featureKidBadge(badge.id))
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      unlocked ? badge.emoji : '🔒',
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 4),
    );
  }
}
