import 'package:flutter/material.dart';

import '../data/session_store.dart';
import '../models/kid_badge.dart';
import '../widgets/bushel_navigation_bar.dart';
import '../data/catalog_store.dart';
import '../services/catalog_repository.dart';
import '../widgets/attendance_status.dart';

class KidBadgesScreen extends StatefulWidget {
  const KidBadgesScreen({super.key});

  @override
  State<KidBadgesScreen> createState() => _KidBadgesScreenState();
}

class _KidBadgesScreenState extends State<KidBadgesScreen> {
  final _session = SessionStore.instance;
  bool _saving = false;
  String? _error;
  Future<void> _choose(CatalogStore store, String badgeId) async {
    if (_saving) return;
    final completed = store.rewards.completed(_session.accountId);
    final entry =
        completed.where((e) => e.badgeId == badgeId).firstOrNull ??
        completed.where((e) => e.badgeId == null).firstOrNull;
    if (entry == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await store.repository.chooseBadge(
        store.uid,
        _session.accountId,
        entry.shiftId,
        badgeId,
      );
    } catch (error) {
      if (mounted) setState(() => _error = catalogError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    if (catalog != null && (catalog.rewardsLoading || catalog.rewardsFailed)) {
      return Scaffold(
        appBar: AppBar(title: const Text('My badge garden')),
        body: Center(child: AttendanceStatus(store: catalog, rewards: true)),
        bottomNavigationBar: const BushelNavigationBar(selectedIndex: 4),
      );
    }
    final claimable =
        catalog?.rewards
            .completed(_session.accountId)
            .where((entry) => entry.badgeId == null)
            .length ??
        0;
    return Scaffold(
      appBar: AppBar(title: const Text('My badge garden')),
      body: Column(
        children: [
          if (_saving) const LinearProgressIndicator(),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          if (catalog != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                claimable > 0
                    ? 'Choose $claimable new badge${claimable == 1 ? '' : 's'}! Each confirmed shift earns one choice.'
                    : 'Confirmed shifts earn badge choices. Tap an earned badge to feature it.',
              ),
            ),
          Expanded(
            child: GridView.builder(
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
                    onTap:
                        !_saving &&
                            (unlocked ||
                                (catalog != null &&
                                    claimable > 0 &&
                                    _session.isKidAccount))
                        ? () => catalog != null
                              ? _choose(catalog, badge.id)
                              : setState(
                                  () => _session.featureKidBadge(badge.id),
                                )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            unlocked || claimable > 0 ? badge.emoji : '🔒',
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
          ),
        ],
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 4),
    );
  }
}
